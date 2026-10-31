class AccessApplicationsController < ApplicationController
  skip_before_action :enforce_ip_allowlist, raise: false
  before_action :require_system_admin, only: %i[index approve reject]

  rate_limit to: 5,  within: 10.minutes, only: :send_email_code,
             with: -> { render json: { error: 'Too many requests, try again later' }, status: :too_many_requests }
  rate_limit to: 15, within: 10.minutes, only: :verify_email,
             with: -> { render json: { error: 'Too many attempts, try again later' }, status: :too_many_requests }
  rate_limit to: 5,  within: 1.hour, only: :create,
             with: -> { render json: { error: 'Too many applications from this network' }, status: :too_many_requests }

  CODE_TTL = 10.minutes

  # POST /api/access_applications/send_email_code
  def send_email_code
    email = params[:email].to_s.strip.downcase
    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: { error: 'Enter a valid email address' }, status: :unprocessable_entity
    end
    if AccessApplication.where(email: email, status: %w[pending approved]).exists? ||
       User.unscoped.exists?(email: email)
      return render json: { error: 'An application or account with this email already exists' },
                    status: :unprocessable_entity
    end

    code = format('%06d', SecureRandom.random_number(1_000_000))
    Rails.cache.write(code_key(email), { digest: digest(email, code), attempts: 0 }, expires_in: CODE_TTL)
    AccessApplicationMailer.verification_code(email, code).deliver_now
    render json: { message: 'Code sent' }
  rescue StandardError => e
    Rails.logger.error "send_email_code failed: #{e.message}"
    render json: { error: 'Could not send the code, please try again' }, status: :internal_server_error
  end

  # POST /api/access_applications/verify_email
  def verify_email
    email = params[:email].to_s.strip.downcase
    entry = Rails.cache.read(code_key(email))
    return render json: { error: 'Code expired, request a new one' }, status: :unprocessable_entity unless entry

    if entry[:attempts] >= 5
      Rails.cache.delete(code_key(email))
      return render json: { error: 'Too many wrong attempts, request a new code' }, status: :unprocessable_entity
    end

    if ActiveSupport::SecurityUtils.secure_compare(entry[:digest], digest(email, params[:code].to_s.strip))
      Rails.cache.delete(code_key(email))
      token = verifier.generate(email, purpose: :access_application, expires_in: 30.minutes)
      render json: { verified: true, email_token: token }
    else
      Rails.cache.write(code_key(email), entry.merge(attempts: entry[:attempts] + 1), expires_in: CODE_TTL)
      render json: { error: 'Incorrect code' }, status: :unprocessable_entity
    end
  end

  # GET /api/access_applications/check_subdomain?company_name=Foo Net
  def check_subdomain
    sub = AccessApplication.slugify(params[:company_name])
    render json: {
      subdomain: sub,
      domain: root_domain,
      available: sub.length >= 3 && !AccessApplication.subdomain_taken?(sub)
    }
  end

  # POST /api/access_applications
  def create
    email = verifier.verified(params[:email_token].to_s, purpose: :access_application)
    if email.blank? || email != params[:email].to_s.strip.downcase
      return render json: { error: 'Please verify your email first' }, status: :unprocessable_entity
    end

    app = AccessApplication.new(
      name: params[:name].to_s.strip,
      company_name: params[:company_name],
      email: email,
      email_verified_at: Time.current,
      country: params[:country],
      phone_number: params[:phone_number].to_s.strip,
      support_whatsapp: params[:support_whatsapp].to_s.strip.presence,
      referral_code: params[:referral_code],
      signup_ip: request.remote_ip,
      terms_accepted_at: (Time.current if ActiveModel::Type::Boolean.new.cast(params[:accepted_terms]))
    )

    if app.save
      AccessApplicationNotifyJob.perform_later(app.id)
      render json: { id: app.id, subdomain: app.subdomain }, status: :created
    else
      render json: { error: app.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # GET /api/access_applications   (system admin)
  def index
    apps = AccessApplication.order(created_at: :desc).limit(500)
    render json: {
      stats: {
        pending: AccessApplication.where(status: 'pending').count,
        approved: AccessApplication.where(status: 'approved').count,
        rejected: AccessApplication.where(status: 'rejected').count
      },
      applications: apps.map { |a| a.as_json.merge('hostname' => "#{a.subdomain}.#{root_domain}") }
    }
  end

  # POST /api/access_applications/:id/approve   (system admin)
  def approve
    app = AccessApplication.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless app
    return render json: { error: 'Already reviewed' }, status: :unprocessable_entity unless app.pending?
    if AccessApplication.subdomain_taken?(app.subdomain, except_id: app.id)
      return render json: { error: 'Subdomain is no longer available' }, status: :unprocessable_entity
    end

    # 1. Cloudflare first: if it fails nothing else has been created yet
    CloudflareTunnel.publish_hostname!(app.subdomain)

    # 2. Account + super admin
    password = generate_password
    admin = nil
    ActiveRecord::Base.transaction do
      account = Account.find_or_create_by!(subdomain: app.subdomain)
      account.update!(company_name: app.company_name) if account.respond_to?(:company_name=)

      if app.referral_code.present?
        begin
          ReferralAttacher.call(account, app.referral_code)
        rescue StandardError => e
          Rails.logger.warn "Referral attach failed for application #{app.id}: #{e.message}"
        end
      end

      ActsAsTenant.with_tenant(account) do
        admin = User.create!(
          username: app.name,
          email: app.email,
          phone_number: app.phone_number,
          password: password,
          password_confirmation: password,
          role: 'super_administrator',
          first_login: true,
          date_registered: Time.now.strftime('%Y-%m-%d %I:%M:%S %p')
        )
      end

      app.update!(status: 'approved', reviewed_at: Time.current, account_id: account.id)
    end

    # 3. Credentials by email
    login_url = "https://#{app.subdomain}.#{root_domain}/signin"
    AdminOnboardingMailer.admin_onboarding(admin, password, login_url).deliver_now

    render json: { message: "#{app.company_name} approved", hostname: "#{app.subdomain}.#{root_domain}" }
  rescue CloudflareTunnel::Error => e
    Rails.logger.error "Approve application #{params[:id]} Cloudflare error: #{e.message}"
    render json: { error: e.message }, status: :bad_gateway
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/access_applications/:id/reject   { reason }
  def reject
    app = AccessApplication.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless app
    return render json: { error: 'Already reviewed' }, status: :unprocessable_entity unless app.pending?

    app.update!(status: 'rejected', rejection_reason: params[:reason].to_s.strip.presence, reviewed_at: Time.current)
    AccessApplicationMailer.rejected(app).deliver_now
    render json: { message: 'Application rejected' }
  end

  private

  def require_system_admin
    return if current_system_admin
    render json: { error: 'Not authorized' }, status: :unauthorized unless performed?
  end

  def verifier     = Rails.application.message_verifier(:access_application)
  def code_key(e)  = "access_email_code:#{e}"
  def digest(e, c) = Digest::SHA256.hexdigest("#{e}:#{c}")
  def root_domain  = ENV.fetch('PLATFORM_ROOT_DOMAIN', 'owitech.co.ke')

  def generate_password
    pool = [*'a'..'z', *'A'..'Z', *'0'..'9']
    chars = [('a'..'z').to_a.sample, ('A'..'Z').to_a.sample, ('0'..'9').to_a.sample, %w[! @ # $ % *].sample]
    chars += Array.new(12) { pool.sample }
    chars.shuffle.join
  end
end