class HotspotCustomizationSerializer < ActiveModel::Serializer
  attributes :id, :customize_template_and_package_per_location, 
  :enable_autologin, :compensation_minutes, :compensation_hours,
  :enable_compensation
end




