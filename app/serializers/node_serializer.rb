class NodeSerializer < ActiveModel::Serializer
  attributes :id, :name, :latitude, :longitude
end
