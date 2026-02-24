class HotspotTemplate < ApplicationRecord

  acts_as_tenant(:account)
  after_commit :clear_cache


  def clear_cache
   Rails.cache.delete("hotspot_templates_index_#{account.id}")
 end

end
