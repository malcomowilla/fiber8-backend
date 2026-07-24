class AdSettingsController < ApplicationController
  require 'cloudinary'

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone

  # GET /ad_settings or /ad_settings.json
  def index
    @ad_settings = AdSetting.all
    render json: @ad_settings
  end

  def allow_get_ads
    @account = ActsAsTenant.current_tenant
    @ad_settings = AdSetting.where(account_id: @account.id)
    render json: @ad_settings.map do |ad|
      {
        id: ad.id,
        ad_title: ad.ad_title,
        ad_link: ad&.ad_link,
        media_url: ad&.media_url,
        position: ad&.position,
        ad_duration: ad&.ad_duration,
        skip_after: ad&.skip_after,
        can_skip: ad&.can_skip,
        ad_enabled: ad&.ad_enabled,
        media_type: ad&.media_type,
        reward_type: ad&.reward_type,
        free_minutes: ad&.free_minutes,
        selected_package: ad&.selected_package,
        design_config: ad.design_config,
        design_background: ad.design_background,
        link_type: ad.link_type,
      }
    end
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  def update_last_activity
    current_user.update!(last_activity_active: Time.current) if current_user
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def get_ad_settings_by_id
    id = params[:id]
    @ad_settings = AdSetting.find_by_id(id)
    render json: {
      ad_title: @ad_settings.ad_title,
      ad_link: @ad_settings&.ad_link,
      media_url: @ad_settings&.media_url,
      position: @ad_settings.position,
      ad_duration: @ad_settings.ad_duration,
      skip_after: @ad_settings.skip_after,
      can_skip: @ad_settings.can_skip,
      ad_enabled: @ad_settings.ad_enabled,
      media_type: @ad_settings.media_type,
      reward_type: @ad_settings.reward_type,
      free_minutes: @ad_settings.free_minutes,
      selected_package: @ad_settings.selected_package,
      design_config: @ad_settings.design_config,
      design_background: @ad_settings.design_background,
      design_canvas_w: @ad_settings.design_canvas_w,
      design_canvas_h: @ad_settings.design_canvas_h,
      link_type: @ad_settings.link_type,
    }
  end

  # POST /ad_settings or /ad_settings.json
  def create
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    setting = AdSetting.find_or_initialize_by(ad_title: params[:ad_title])

    cloudinary_url = nil
    if params[:media_file].present?
      resource_type = params[:media_type] == "video" ? "video" : "image"
      uploaded = Cloudinary::Uploader.upload(params[:media_file].tempfile.path, resource_type: resource_type)
      cloudinary_url = uploaded["secure_url"]
    elsif params[:media_url].present?
      cloudinary_url = params[:media_url]
    end

    setting.assign_attributes(
      ad_title: params[:ad_title],
      ad_link: params[:ad_link],
      position: params[:position],
      ad_duration: params[:ad_duration],
      skip_after: params[:skip_after],
      can_skip: params[:can_skip],
      ad_enabled: params[:ad_enabled],
      media_type: params[:media_type],
      reward_type: params[:reward_type],
      free_minutes: params[:free_minutes],
      selected_package: params[:selected_package],
      media_url: cloudinary_url,
      design_config: params[:design_config],
      design_canvas_w: params[:design_canvas_w],
      design_canvas_h: params[:design_canvas_h],
      design_background: params[:design_background],
      link_type: params[:link_type],
    )

    if setting.save
      render json: { success: true, media_url: cloudinary_url }
    else
      render json: { error: setting.errors.full_messages }, status: 422
    end
  end

  # Records an ad event. Now also stores the device's mac (when present) so
  # "engaged devices" can be computed as a distinct count downstream, and
  # accepts 'engaged_view' as a first-class event type — fired by the
  # frontend once a view crosses the engagement threshold (see
  # hotspot_page_builder notes), separate from the raw 'Ad View' impression.
  def track_ad_event
    ad = AdSetting.find_by(id: params[:ad_id])
    return render json: { error: 'Ad not found' }, status: :not_found unless ad

    event_type = params[:event_type].presence || 'Ad View'

    AdEvent.create!(
      ad_setting_id: ad.id,
      account_id: ActsAsTenant.current_tenant.id,
      event_type: event_type,
      mac: params[:mac].presence,
    )
    render json: { status: 'ok' }
  rescue => e
    Rails.logger.error "track_ad_event failed: #{e.class} - #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Bulk per-ad stats for the dashboard table/cards. One query per metric,
  # avoids N+1 per-row fetches.
  #
  # Impressions  = 'Ad View' events (the ad was shown)
  # Clicks       = 'click' events (tap-through)
  # Views        = engaged views: 'engaged_view' events if present, else we
  #                fall back to (clicks + video_completed) as a proxy so
  #                this still works before the frontend starts firing
  #                'engaged_view' explicitly.
  # CTR          = clicks / impressions * 100
  # Engaged devices = distinct macs across engaged-view-qualifying events
  #                    for that ad (requires the `mac` column/migration)
  def ad_stats
    account_id = ActsAsTenant.current_tenant.id
    events = AdEvent.where(account_id: account_id)

    counts = events.group(:ad_setting_id, :event_type).count
    device_counts = events
      .where(event_type: %w[engaged_view click video_completed])
      .where.not(mac: [nil, ''])
      .distinct
      .group(:ad_setting_id)
      .count(:mac)

    stats = Hash.new { |h, k| h[k] = { impressions: 0, clicks: 0, completed_views: 0, engaged_views: 0 } }
    counts.each do |(ad_id, event_type), count|
      case event_type
      when 'Ad View'         then stats[ad_id][:impressions] += count
      when 'click'           then stats[ad_id][:clicks] += count
      when 'video_completed' then stats[ad_id][:completed_views] += count
      when 'engaged_view'    then stats[ad_id][:engaged_views] += count
      end
    end

    result = stats.map do |ad_id, s|
      impressions = s[:impressions]
      clicks = s[:clicks]
      views = s[:engaged_views] > 0 ? s[:engaged_views] : (clicks + s[:completed_views])
      ctr = impressions > 0 ? ((clicks.to_f / impressions) * 100).round(1) : 0
      {
        ad_id: ad_id,
        impressions: impressions,
        clicks: clicks,
        completed_views: s[:completed_views],
        views: views,
        ctr: ctr,
        engaged_devices: device_counts[ad_id] || 0,
      }
    end

    render json: result
  end

  # Daily engagement trend for the last 30 days, for the "Engagement · last
  # 30 days" chart. Returns clicks and completed_views per day so the
  # frontend can plot both series.
  def ad_engagement_trend
    account_id = ActsAsTenant.current_tenant.id
    since = 30.days.ago.beginning_of_day

    rows = AdEvent.where(account_id: account_id, created_at: since..)
                  .where(event_type: %w[click video_completed engaged_view])
                  .group("DATE(created_at)", :event_type)
                  .count

    by_day = Hash.new { |h, k| h[k] = { clicks: 0, completed_views: 0 } }
    rows.each do |(date, event_type), count|
      day = date.to_s
      case event_type
      when 'click'                       then by_day[day][:clicks] += count
      when 'video_completed'             then by_day[day][:completed_views] += count
      when 'engaged_view'                then by_day[day][:completed_views] += count
      end
    end

    # Fill in every day in the range (even zero days) so the chart doesn't
    # have gaps.
    result = (0..29).map do |i|
      date = (Date.today - (29 - i)).to_s
      { date: date, clicks: by_day[date][:clicks], completed_views: by_day[date][:completed_views] }
    end

    render json: result
  end

  # PATCH/PUT /ad_settings/1 or /ad_settings/1.json
  def update
    @ad_setting = AdSetting.find_by_id(params[:id])

    cloudinary_url = @ad_setting.media_url
    if params[:media_file].present?
      resource_type = params[:media_type] == "video" ? "video" : "image"
      uploaded = Cloudinary::Uploader.upload(params[:media_file].tempfile.path, resource_type: resource_type)
      cloudinary_url = uploaded["secure_url"]
    elsif params[:media_url].present?
      cloudinary_url = params[:media_url]
    end

    if @ad_setting.update(
      ad_title: params[:ad_title],
      ad_link: params[:ad_link],
      position: params[:position],
      ad_duration: params[:ad_duration],
      skip_after: params[:skip_after],
      can_skip: params[:can_skip],
      ad_enabled: params[:ad_enabled],
      media_type: params[:media_type],
      ad_format: params[:ad_format],
      reward_type: params[:reward_type],
      free_minutes: params[:free_minutes],
      selected_package: params[:selected_package],
      media_url: cloudinary_url,
      design_config: params[:design_config],
      design_canvas_w: params[:design_canvas_w],
      design_canvas_h: params[:design_canvas_h],
      design_background: params[:design_background],
      link_type: params[:link_type],
    )
      render json: @ad_setting
    else
      render json: @ad_setting.errors, status: :unprocessable_entity
    end
  end

  # DELETE /ad_settings/1 or /ad_settings/1.json
  def destroy
    @ad_setting = AdSetting.find_by_id(params[:id])
    @ad_setting.destroy!
    head :no_content
  end

  private

  def set_ad_setting
    @ad_setting = AdSetting.find_by_id(params[:id])
  end

  def ad_setting_params
    params.require(:ad_setting).permit(:enabled, :to_right, :to_left, :to_top, :account_id)
  end
end