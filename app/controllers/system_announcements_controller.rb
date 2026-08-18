class SystemAnnouncementsController < ApplicationController
  # Admin-management actions require a logged-in system admin.
  before_action :require_system_admin!, only: %i[index create update destroy]
  before_action :set_announcement, only: %i[update destroy]

  # GET /system_announcements  (system admin: full list, incl. inactive/expired)
  def index
    announcements = ActsAsTenant.without_tenant { SystemAnnouncement.recent }
    render json: announcements
  end

  # GET /system_announcements_active  (tenant-facing: only live ones, no auth required)
  def active
    announcements = ActsAsTenant.without_tenant { SystemAnnouncement.live.recent }
    render json: announcements
  end

  # POST /system_announcements
  # def create
  #   announcement = ActsAsTenant.without_tenant do
  #     SystemAnnouncement.new(announcement_params.merge(created_by: current_system_admin&.email))
  #   end

  #   if announcement.save
      
  #     render json: announcement, status: :created
  #   else
  #     render json: { errors: announcement.errors }, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /system_announcements/:id
  # def update
  #   if @announcement.update(announcement_params)
  #     render json: @announcement, status: :ok
  #   else
  #     render json: { errors: @announcement.errors }, status: :unprocessable_entity
  #   end
  # end

  # DELETE /system_announcements/:id
  # 
  #





def create
  announcement = ActsAsTenant.without_tenant do
    SystemAnnouncement.new(
      announcement_params.merge(
        created_by: current_system_admin&.email
      )
    )
  end

  if announcement.save
    ActionCable.server.broadcast(
      "maintenance",
      {
        type: "created",
        announcement: announcement.as_json
      }
    )

    render json: announcement, status: :created
  else
    render json: { errors: announcement.errors }, status: :unprocessable_entity
  end
end

def update
  if @announcement.update(announcement_params)
    ActionCable.server.broadcast(
      "maintenance",
      {
        type: "updated",
        announcement: @announcement.as_json
      }
    )

    render json: @announcement, status: :ok
  else
    render json: { errors: @announcement.errors }, status: :unprocessable_entity
  end
end



  def destroy
    @announcement.destroy!
    head :no_content
  end

  private

  def set_announcement
    @announcement = ActsAsTenant.without_tenant { SystemAnnouncement.find(params[:id]) }
  end

  def announcement_params
    params.permit(:title, :body, :announcement_type, :priority, :active, :expires_at, :published_at)
  end

  def require_system_admin!
    render json: { error: 'Not authorized' }, status: :unauthorized unless current_system_admin
  end
end