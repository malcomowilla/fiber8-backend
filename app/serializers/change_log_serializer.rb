class ChangeLogSerializer < ActiveModel::Serializer
  attributes :id, :version, :system_changes, :change_title
end
