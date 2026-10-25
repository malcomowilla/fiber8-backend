# class CallCenterSettingsController < ApplicationController


#   set_current_tenant_through_filter

#   before_action :set_tenant
#   def show
#     render json: serialize(setting)
#   end


#   def set_tenant
#     host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
#     ActsAsTenant.current_tenant = @account
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Invalid tenant' }, status: :not_found
#   end

#   def update
#     s = setting
#     attrs = params.permit(
#       :always_open, :open_from, :open_until, :timezone, :open_message, :closed_message,
#       :hold_message, :hold_music_url, :record_calls, :announce_recording
#     ).to_h
#     attrs[:open_days] = Array(params[:open_days]).map(&:to_s).join(",") if params.key?(:open_days)

#     if s.update(attrs)
#       render json: serialize(s)
#     else
#       render json: { error: s.errors.full_messages.to_sentence }, status: :unprocessable_entity
#     end
#   end

#   private

#   def setting
#     CallCenterSetting.first_or_create!(
#       open_message: "Welcome. Thank you for calling.",
#       closed_message: "We are closed right now. Please leave a message after the beep and we will call you back."
#     )
#   end

#   def serialize(s)
#     s.as_json(except: %i[account_id created_at updated_at open_days]).merge(
#       open_days: s.days,
#       open_now: s.open_now?
#     )
#   end
# end
class CallCenterSettingsController < ApplicationController
  def show
    render json: serialize(setting)
  end

  def update
    s = setting
    attrs = params.permit(
      :always_open, :open_from, :open_until, :timezone, :open_message, :closed_message,
      :hold_message, :hold_music_url, :record_calls, :announce_recording,
      :did_numbers, :unreachable_message
    ).to_h
    attrs[:open_days] = Array(params[:open_days]).map(&:to_s).join(",") if params.key?(:open_days)

    if s.update(attrs)
      render json: serialize(s)
    else
      render json: { error: s.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def setting
    CallCenterSetting.first_or_create!(
      open_message: "Welcome. Thank you for calling.",
      closed_message: "We are closed right now. Please leave a message after the beep and we will call you back."
    )
  end

  def serialize(s)
    s.as_json(except: %i[account_id created_at updated_at open_days]).merge(
      open_days: s.days,
      open_now: s.open_now?
    )
  end
end