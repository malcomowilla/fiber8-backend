

class SystemMetricsChannel < ApplicationCable::Channel

def subscribed

stream_for 'system_metrics'
end



def unsubscribed
  # Any cleanup needed when channel is unsubscribed
  # stop_any_running_job
  # 
  
end

  end