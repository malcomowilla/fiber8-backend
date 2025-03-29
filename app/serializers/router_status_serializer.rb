
class RouterStatusSerializer < ActiveModel::Serializer
  attributes :ip, :reachable, :response, :checked_at, :tenant_id, :id



 
  def checked_at
    object.checked_at.strftime("%B %d, %Y at %I:%M %p")
  end
end