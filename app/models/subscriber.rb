class Subscriber < ApplicationRecord
    acts_as_tenant(:account)
    auto_increment :sequence_number

    # before_create :set_sequence_number

    # def set_sequence_number
    #     max_sequence_number = Subscriber.maximum(:sequence_number)

    #     # If there are no subscribers yet, set the sequence number to 1
    #     # Otherwise, increment the maximum sequence number by 1
    #     self.sequence_number = max_sequence_number ? max_sequence_number + 1 : 1
    #   end
end
