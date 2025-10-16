class Drawing < ApplicationRecord

 acts_as_tenant(:account)

 store :position, accessors: [:lat, :lng], coder: JSON
  store :path, accessors: [], coder: JSON
  store :paths, accessors: [], coder: JSON
  store :center, accessors: [:lat, :lng], coder: JSON
  store :bounds, accessors: [:north, :south, :east, :west], coder: JSON

  validates :drawing_type, presence: true
end
