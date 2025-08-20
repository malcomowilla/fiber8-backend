



class ONUJob 
  include Sidekiq::Job
  queue_as :onu
  
  def perform(onu_id)
    onu = ONU.find(onu_id)
    onu.update_status
    
    if onu.status == 'active'
      onu.update_status
      
      if onu.status == 'active'
        ONUJob.perform_later(onu.id)
      end
    end
   end
end