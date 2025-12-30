class HotspotTemplateSerializer < ActiveModel::Serializer
  attributes :id, :name, :account_id, :preview_image,
  :default_template, :sleekspot, :attractive, :clean, :default, :flat, :minimal, :simple, :pepea,
  :premium, :location
end



