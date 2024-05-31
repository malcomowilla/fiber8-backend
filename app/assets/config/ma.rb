
sequence_number = 1
prefix = 'FK'
minimum_number = 6

number_prefix =  "#{prefix}#{sequence_number.to_s.rjust(minimum_number, '0')}"


puts number_prefix


# def create
#     @subscriber = Subscriber.create!(subscriber_params)
    
#     # Increment the sequence number by 1 for each new subscriber
#     @subscriber.increment!(:sequence_number)
  
#     # Combine prefix and the incremented sequence number to generate the reference number
#     @subscriber.ref_no = "#{@subscriber.prefix}#{subscriber.sequence_number.to_s.rjust(4, '0')}"
    
#     # Save the changes to the subscriber
#     @subscriber.save!
  
#     render json: @subscriber, status: :created
#   end
  










  