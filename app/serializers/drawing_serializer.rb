class DrawingSerializer < ActiveModel::Serializer
  attributes :id, :drawing_type, :position, :path, :paths, :center, :bounds, :title
end
