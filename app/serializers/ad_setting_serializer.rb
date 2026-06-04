class AdSettingSerializer < ActiveModel::Serializer
  attributes :id, :enabled, :to_right, :to_left, :to_top, :ad_title,
  :position, :ad_duration, :skip_after, :can_skip, :ad_enabled, :media_type,
  :reward_type, :free_minutes, :selected_package, :created_at,
  :ad_link, :design_config, :design_background, :link_type, :design_canvas_w, :design_canvas_h



  def created_at
  object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
end



end
