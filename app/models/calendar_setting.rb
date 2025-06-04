class CalendarSetting < ApplicationRecord
  acts_as_tenant(:account)
end
