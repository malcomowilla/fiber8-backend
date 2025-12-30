class TemplateLocation < ApplicationRecord
  acts_as_tenant(:account)
end
