  class SpeedTestsController < ApplicationController
    set_current_tenant_through_filter
    before_action :set_tenant
    skip_before_action :verify_authenticity_token, raise: false

    DEFAULT_DOWNLOAD_MB = 15
    MAX_DOWNLOAD_MB     = 30
    MIN_DOWNLOAD_MB     = 2

    # GET /api/speed_test/ping
    # Used client-side for round-trip latency + jitter measurement.
    def ping
      render json: { pong: true, server_time: Time.current.to_f }
    end

    # GET /api/speed_test/download?size_mb=15
    # Streams genuinely random (incompressible) bytes so gzip middleware
    # can't quietly shrink the payload and skew the measured throughput.
    def download
      size_mb = params[:size_mb].to_i
      size_mb = DEFAULT_DOWNLOAD_MB if size_mb <= 0
      size_mb = size_mb.clamp(MIN_DOWNLOAD_MB, MAX_DOWNLOAD_MB)

      data = SecureRandom.random_bytes(size_mb.megabytes)

      response.headers['Cache-Control']   = 'no-store'
      response.headers['Content-Length']  = data.bytesize.to_s
      send_data data, type: 'application/octet-stream', disposition: 'inline'
    end

    # POST /api/speed_test/upload
    # Client posts a random blob; we just read and discard it.
    # Timing happens client-side around the request.
    def upload
      bytes_received = request.body.read&.bytesize || 0
      render json: { received_bytes: bytes_received }
    end

    # POST /api/speed_test/results
    # Persists a completed test and returns a plan-relative status.
    def create
      subscriber = current_customer
      return render json: { error: 'Not authenticated' }, status: :unauthorized unless subscriber

      plan_speed_mbps = extract_plan_speed_mbps(subscriber)
      download_mbps    = params[:download_mbps].to_f
      upload_mbps      = params[:upload_mbps].to_f
      percent_of_plan  = plan_speed_mbps.present? && plan_speed_mbps > 0 ? (download_mbps / plan_speed_mbps) : nil
      status           = SpeedTestResult.classify(percent_of_plan)

      result = SpeedTestResult.create!(
        subscriber_id:   subscriber.id,
        account_id:      ActsAsTenant.current_tenant.id,
        nas_router_id:   subscriber.respond_to?(:nas_router_id) ? subscriber.nas_router_id : nil,
        download_mbps:   download_mbps,
        upload_mbps:     upload_mbps,
        ping_ms:         params[:ping_ms],
        jitter_ms:       params[:jitter_ms],
        plan_speed_mbps: plan_speed_mbps,
        percent_of_plan: percent_of_plan,
        status:          status,
        tested_at:       Time.current
      )

      render json: {
        id:               result.id,
        download_mbps:    result.download_mbps,
        upload_mbps:      result.upload_mbps,
        ping_ms:          result.ping_ms,
        jitter_ms:        result.jitter_ms,
        plan_speed_mbps:  result.plan_speed_mbps,
        percent_of_plan:  result.percent_of_plan,
        status:           result.status,
        tested_at:        result.tested_at
      }, status: :created
    end

    # GET /api/speed_test/history?limit=10
    def history
      subscriber = current_customer
      return render json: { error: 'Not authenticated' }, status: :unauthorized unless subscriber

      limit = (params[:limit] || 10).to_i.clamp(1, 50)
      results = SpeedTestResult.where(subscriber_id: subscriber.id)
                                .order(tested_at: :desc)
                                .limit(limit)
                                .reverse

      render json: results.map { |r|
        { id: r.id, download_mbps: r.download_mbps, upload_mbps: r.upload_mbps,
          percent_of_plan: r.percent_of_plan, status: r.status, tested_at: r.tested_at }
      }
    end

    # POST /api/speed_test/results/:id/report
    # Turns a bad speed test straight into a pre-filled, diagnosable ticket.
    def report_issue
      subscriber = current_customer
      return render json: { error: 'Not authenticated' }, status: :unauthorized unless subscriber

      result = SpeedTestResult.find_by(id: params[:id], subscriber_id: subscriber.id)
      return render json: { error: 'Speed test not found' }, status: :not_found unless result

      description = build_ticket_description(result)
      priority    = result.status == 'critical' ? 'High' : 'Medium'

      # NOTE: adjust field names to match your actual ClientSupportTicket schema
      # (agent_review/subject, ticket_number generation, etc. per your existing model).
      ticket = ClientSupportTicket.create!(
        subscriber_id: subscriber.id,
        account_id:    ActsAsTenant.current_tenant.id,
        subject:       'Slow speeds detected (auto-generated)',
        description:   description,
        priority:      priority,
        status:        'Open'
      )

      ActivtyLog.create(
        action: 'create',
        ip: request.remote_ip,
        description: "Auto-created support ticket from speed test ##{result.id}",
        user_agent: request.user_agent,
        user: subscriber.respond_to?(:name) ? subscriber.name : "subscriber:#{subscriber.id}",
        date: Time.current
      )

      render json: { ticket_id: ticket.id, ticket_number: ticket.try(:ticket_number) }, status: :created
    end

    private

    def set_tenant
      host = request.headers['X-Subdomain']
      @account = Account.find_by(subdomain: host)
      ActsAsTenant.current_tenant = @account
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Invalid tenant' }, status: :not_found
    end

    def extract_plan_speed_mbps(subscriber)
      # Adjust to however plan speed is actually stored/joined
      # (e.g. subscriber.package&.speed, subscriber.subscriptions.active.first&.package&.speed)
      speed_str = subscriber.respond_to?(:package_speed) ? subscriber.package_speed : nil
      speed_str&.to_s&.gsub(/[^\d.]/, '')&.to_f
    end

    def build_ticket_description(result)
      <<~DESC
        Speed test recorded #{result.download_mbps.round(1)} Mbps down / #{result.upload_mbps.round(1)} Mbps up
        (plan: #{result.plan_speed_mbps || 'unknown'} Mbps#{result.percent_of_plan ? ", #{(result.percent_of_plan * 100).round}% of plan" : ''})
        at #{result.tested_at.strftime('%Y-%m-%d %H:%M %Z')}.
        Ping: #{result.ping_ms}ms, Jitter: #{result.jitter_ms}ms.
      DESC
    end
  end
