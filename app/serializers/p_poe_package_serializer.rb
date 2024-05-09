class PPoePackageSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :download_limit, :upload_limit, :validity, :upload_burst_limit, :download_burst_limit, :validity_period_units
end
