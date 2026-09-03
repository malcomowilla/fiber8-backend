class RouterTroubleshootingAiService
  GATEWAY_URL = "https://gateway.ai.cloudflare.com/v1/#{ENV['CF_ACCOUNT_ID']}/#{ENV['CF_GATEWAY_ID'] || 'owitech-gateway'}/compat/chat/completions"

  DEFAULT_MODEL  = "workers-ai/@cf/openai/gpt-oss-120b"
  FALLBACK_MODEL = "google-ai-studio/gemini-3.6-flash"

  # Read-only tools only. Nothing here writes to the router — no config
  # changes, no user creation, no firewall edits. If you ever add a
  # write tool, it needs its own explicit confirmation step in the UI
  # before the AI can trigger it; never let the model call it directly.
  TOOLS = [
    {
      type: "function",
      function: {
        name: "ping_router",
        description: "Check right now whether the router is reachable over TCP. Use when the snapshot is stale or the admin asks if it's currently online.",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "get_dhcp_leases",
        description: "Fetch current DHCP leases (client IP, MAC, hostname, status) from the router.",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "get_firewall_rules",
        description: "Fetch the router's current firewall filter rules (chain, action, comment, enabled state).",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "get_wireguard_status",
        description: "Fetch live WireGuard tunnel status for this router (connected, reachable, since, transfer).",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "get_hotspot_status",
        description: "Fetch current hotspot active-user count and session list from the router.",
        parameters: { type: "object", properties: {}, required: [] }
      }
    }
  ].freeze

  MAX_TOOL_ROUNDS = 4

  # tool_executor: an object responding to #call(tool_name, args_hash) -> Hash.
  # Pass a bound method, e.g. `method(:run_diagnostic_tool)` from the controller.
  def self.ask(router:, diagnostics:, question:, history: [], tool_executor: nil)
    new.ask(router: router, diagnostics: diagnostics, question: question, history: history, tool_executor: tool_executor)
  end

  def ask(router:, diagnostics:, question:, history: [], tool_executor: nil)
    result = run_conversation(DEFAULT_MODEL, router, diagnostics, question, history, tool_executor)
    return result if result[:success]

    Rails.logger.warn "RouterTroubleshootingAiService: #{DEFAULT_MODEL} failed (#{result[:error]}), falling back to #{FALLBACK_MODEL}"
    run_conversation(FALLBACK_MODEL, router, diagnostics, question, history, tool_executor)
  end

  private

  def run_conversation(model, router, diagnostics, question, history, tool_executor)
    api_token = ENV['CF_API_TOKEN']
    return { success: false, error: 'CF_API_TOKEN not configured' } unless api_token.present?

    messages = [{ role: 'system', content: system_prompt(router, diagnostics) }] +
               build_messages(history) +
               [{ role: 'user', content: question }]

    # Workers AI's schema for @cf/ models doesn't support the OpenAI
    # tool/tool_calls message shape through the /compat endpoint (it
    # rejects the request entirely rather than ignoring the field).
    # GPT-OSS tool calling needs the separate /ai/v1/responses endpoint,
    # which isn't wired up yet — so only enable tools for non-workers-ai
    # models until that's built.
    with_tools = tool_executor.present? && !model.start_with?('workers-ai/')

    MAX_TOOL_ROUNDS.times do
      response = call_gateway(model, messages, api_token, with_tools)
      return response unless response[:success]

      msg = response[:message]

      if msg['tool_calls'].present? && with_tools
        messages << { role: 'assistant', content: msg['content'] || '', tool_calls: msg['tool_calls'] }

        msg['tool_calls'].each do |tc|
          tool_name = tc.dig('function', 'name')
          tool_args = safe_parse_json(tc.dig('function', 'arguments'))
          tool_result = safe_run_tool(tool_executor, tool_name, tool_args)

          messages << {
            role: 'tool',
            tool_call_id: tc['id'],
            content: tool_result.to_json
          }
        end
        next
      end

      text = msg['content']
      return text.present? ? { success: true, reply: text, model: model } : { success: false, error: 'empty_response' }
    end

    { success: false, error: 'tool_loop_exceeded' }
  end

  def call_gateway(model, messages, api_token, with_tools)
    payload = { model: model, messages: messages, max_tokens: 1024 }
    payload[:tools] = TOOLS if with_tools
    payload[:tool_choice] = 'auto' if with_tools

    response = RestClient::Request.execute(
      method: :post,
      url: GATEWAY_URL,
      payload: payload.to_json,
      headers: { content_type: :json, Authorization: "Bearer #{api_token}" },
      timeout: 20
    )

    parsed = JSON.parse(response.body)
    message = parsed.dig('choices', 0, 'message')
    return { success: false, error: 'no_message_in_response' } unless message

    { success: true, message: message }
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "RouterTroubleshootingAiService (#{model}) error: #{e.response&.body}"
    { success: false, error: 'model_unavailable' }
  rescue => e
    Rails.logger.error "RouterTroubleshootingAiService (#{model}) error: #{e.message}"
    { success: false, error: 'model_unavailable' }
  end

  def safe_run_tool(tool_executor, tool_name, tool_args)
    tool_executor.call(tool_name, tool_args)
  rescue => e
    Rails.logger.error "RouterTroubleshootingAiService: tool #{tool_name} failed: #{e.message}"
    { error: "tool_execution_failed: #{e.message}" }
  end

  def safe_parse_json(str)
    str.present? ? JSON.parse(str) : {}
  rescue JSON::ParserError
    {}
  end

  def build_messages(history)
    Array(history).map do |m|
      role = (m['role'] || m[:role]).to_s
      { role: role == 'assistant' ? 'assistant' : 'user', content: (m['content'] || m[:content]).to_s }
    end.select { |m| m[:content].present? }
  end

  def system_prompt(router, diagnostics)
    <<~PROMPT
      You are a senior network engineer embedded in an ISP admin dashboard.
      You're helping the admin troubleshoot a specific MikroTik router named
      "#{router.name}" (#{router.ip_address}) without them needing to call support.

      Here is the live diagnostic snapshot for this router, gathered moments ago:
      #{diagnostics.to_json}

      You also have read-only tools available (ping_router, get_dhcp_leases,
      get_firewall_rules, get_wireguard_status, get_hotspot_status). Use them
      when the admin's question needs data that isn't in the snapshot above,
      or when the snapshot might be stale (e.g. they ask "is it back up now?").
      These tools are read-only — you cannot change any router configuration,
      and you should never imply to the admin that you did.

      Rules:
      - Answer like a colleague who already looked at the data, not a generic chatbot.
      - Be specific and reference actual numbers (CPU %, memory, interface errors,
        tunnel status, active hotspot users, etc.) when relevant.
      - If CPU or memory is high, give concrete next steps (e.g. identify heavy
        queues/scripts, disable unused services like unused firewall logging,
        move heavy DNS/logging off-router, consider hardware upgrade if this is
        a sustained pattern rather than a spike).
      - If the WireGuard tunnel is down, say so plainly in plain terms (e.g. "the
        secure connection between this router and the platform is down"). Only
        suggest checks the admin can actually do themselves: has the router's
        WAN/internet connection changed or dropped recently, is the router
        powered on and online, has anything on the LAN side changed (new
        firewall rule, IP conflict, ISP outage upstream of this router). Do
        NOT mention VPS, relay servers, tunnel peer internals, or any platform
        infrastructure by name — that side is managed by the platform, not the
        admin. If none of the local checks explain it, say this looks like it
        may need the platform provider to look into it and suggest contacting
        support if it doesn't clear up on its own.
      - If something needed to answer isn't in the snapshot, use a tool to get
        it before answering, or say what additional check you'd run and name
        the concrete MikroTik command/REST endpoint if no tool covers it.
      - Keep responses tight — a few sentences or a short list, not an essay.
      - Never invent numbers that aren't in the snapshot or a tool result.
    PROMPT
  end
end