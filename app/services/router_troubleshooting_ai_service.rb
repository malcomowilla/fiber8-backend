class RouterTroubleshootingAiService
  # Free tier: no billing required. https://aistudio.google.com/apikey
  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent"

  def self.ask(router:, diagnostics:, question:, history: [])
    new.ask(router: router, diagnostics: diagnostics, question: question, history: history)
  end

  def ask(router:, diagnostics:, question:, history: [])
    api_key = ENV['GEMINI_API_KEY']
    return { success: false, error: 'GEMINI_API_KEY not configured' } unless api_key.present?

    contents = build_contents(history, question)

    payload = {
      system_instruction: { parts: [{ text: system_prompt(router, diagnostics) }] },
      contents: contents,
      generationConfig: { maxOutputTokens: 1024 }
    }

    response = RestClient.post(
      "#{GEMINI_URL}?key=#{api_key}",
      payload.to_json,
      { content_type: :json }
    )

    parsed = JSON.parse(response.body)
    text = parsed.dig('candidates', 0, 'content', 'parts', 0, 'text')

    { success: true, reply: text.presence || "I couldn't generate a response — try rephrasing." }
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "RouterTroubleshootingAiService error: #{e.response&.body}"
    { success: false, error: 'AI assistant is temporarily unavailable' }
  rescue => e
    Rails.logger.error "RouterTroubleshootingAiService error: #{e.message}"
    { success: false, error: 'AI assistant is temporarily unavailable' }
  end

  private

  # Gemini uses "user"/"model" roles (not "assistant") and a different
  # content shape than Anthropic's Messages API.
  def build_contents(history, question)
    contents = Array(history).map do |m|
      role = (m['role'] || m[:role]).to_s
      gemini_role = role == 'assistant' ? 'model' : 'user'
      { role: gemini_role, parts: [{ text: (m['content'] || m[:content]).to_s }] }
    end.select { |c| c[:parts].first[:text].present? }

    contents << { role: 'user', parts: [{ text: question }] }
    contents
  end

  def system_prompt(router, diagnostics)
    <<~PROMPT
      You are a senior network engineer embedded in an ISP admin dashboard.
      You're helping the admin troubleshoot a specific MikroTik router named
      "#{router.name}" (#{router.ip_address}) without them needing to call support.

      Here is the live diagnostic snapshot for this router, gathered moments ago:
      #{diagnostics.to_json}

      Rules:
      - Answer like a colleague who already looked at the data, not a generic chatbot.
      - Be specific and reference actual numbers from the snapshot (CPU %, memory,
        interface errors, tunnel status, active hotspot users, etc.) when relevant.
      - If CPU or memory is high, give concrete next steps (e.g. identify heavy
        queues/scripts, disable unused services like unused firewall logging,
        move heavy DNS/logging off-router, consider hardware upgrade if this is
        a sustained pattern rather than a spike).
      - If the WireGuard tunnel is down, say so plainly and suggest checking:
        peer handshake age, whether the router's WAN changed, and whether the
        relay/VPS side (RemoteWireguardExecutor host) is reachable.
      - If something needed to answer isn't in the snapshot, say what additional
        check you'd run (and name the concrete MikroTik command/REST endpoint).
      - Keep responses tight — a few sentences or a short list, not an essay.
      - Never invent numbers that aren't in the snapshot.
    PROMPT
  end
end