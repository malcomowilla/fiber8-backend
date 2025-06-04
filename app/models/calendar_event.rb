class CalendarEvent < ApplicationRecord

  acts_as_tenant(:account)
end








