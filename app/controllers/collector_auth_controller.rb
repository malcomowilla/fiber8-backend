class CollectorAuthController < ApplicationController
  include CollectorAuth
  skip_before_action :set_tenant, only: %i[signup login logout]

  # POST /api/collector/signup
  # Creates the company Account (account_type "collector") and its first admin User.
  def signup
    p = params.permit(:company_name, :owner_name, :email, :phone_number, :password, :password_confirmation)
    email = p[:email].to_s.strip.downcase
    phone = normalize_phone(p[:phone_number])

    errors = []
    errors << "Company name can't be blank" if p[:company_name].blank?
    errors << "Your name can't be blank" if p[:owner_name].blank?
    errors << "Email is invalid" unless email.match?(URI::MailTo::EMAIL_REGEXP)
    errors << "Phone must be a valid Kenyan number" unless phone.match?(/\A254[17]\d{8}\z/)
    errors << "Password must be at least 8 characters" if p[:password].to_s.length < 8
    errors << "Passwords do not match" if p[:password] != p[:password_confirmation]
    ActsAsTenant.without_tenant do
      errors << "Email is already registered" if User.exists?(email: email, role: "collector_admin")
      errors << "Phone number is already registered" if User.exists?(phone_number: phone, role: "collector_admin")
    end
    return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

    account = user = nil
    ActiveRecord::Base.transaction do
      account = Account.create!(
        subdomain: "#{p[:company_name].parameterize}-#{SecureRandom.hex(3)}",
        account_type: "collector",
        company_name: p[:company_name].strip,
        status: requires_approval? ? "pending" : "active",
        signup_ip: request.remote_ip
      )
      ActsAsTenant.with_tenant(account) do
        user = User.create!(
          username: p[:owner_name].strip, email: email, phone_number: phone,
          password: p[:password], password_confirmation: p[:password_confirmation],
          role: "collector_admin", date_registered: Time.current
        )
      end
    end

    if account.status == "pending"
      return render json: { pending: true, message: "Registration received. We will notify you once approved." }, status: :created
    end

    user.update_column(:last_login_at, Time.current)
    sign_in_collector(user)
    render json: { pending: false, admin: admin_json(user, account) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # POST /api/collector/login   { identifier: email or phone, password }
  def login
    identifier = params[:identifier].to_s.strip
    user = ActsAsTenant.without_tenant do
      if identifier.include?("@")
        User.find_by(email: identifier.downcase, role: "collector_admin")
      else
        User.find_by(phone_number: normalize_phone(identifier), role: "collector_admin")
      end
    end

    unless user&.authenticate(params[:password].to_s)
      return render json: { error: "Wrong email, phone or password." }, status: :unauthorized
    end

    account = Account.find_by(id: user.account_id)
    return render json: { error: "Your registration is still awaiting approval." }, status: :forbidden if account.status == "pending"
    return render json: { error: "This account is suspended. Contact support." }, status: :forbidden if account.status == "suspended"

    user.update_column(:last_login_at, Time.current)
    sign_in_collector(user)
    render json: { admin: admin_json(user, account) }
  end

  # GET /api/collector/me  (frontend calls this on every page load to restore the session)
  def me
    render json: { admin: admin_json(current_collector, @collector_account) }
  end

  # DELETE /api/collector/logout
  def logout
    sign_out_collector
    head :no_content
  end

  private

  def admin_json(user, account)
    {
      id: user.id, account_id: account.id, company_name: account.company_name,
      owner_name: user.username, email: user.email, phone_number: user.phone_number, status: account.status
    }
  end

  # 0712 345 678 / +254712345678 / 712345678  ->  254712345678
  def normalize_phone(raw)
    digits = raw.to_s.gsub(/\D/, "")
    digits =~ /\A(?:254|0)?([17]\d{8})\z/ ? "254#{Regexp.last_match(1)}" : digits
  end

  # COLLECTOR_SIGNUP_REQUIRES_APPROVAL=true  => new signups stay "pending" until you approve them
  def requires_approval?
    ActiveModel::Type::Boolean.new.cast(ENV["COLLECTOR_SIGNUP_REQUIRES_APPROVAL"])
  end
end