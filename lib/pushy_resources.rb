Dir[File.dirname(__FILE__) + '/pushy_resources/*.rb'].each {|file| require file }

module PushyResources
   class PushyResources < Rails::Engine

     # Setting default configuration values
     config.event_queue         = :redis
     config.redis_event_channel = 'PushyEvents'
     config.redis_server        = 'localhost'
     config.redis_port          = 6379
   end
end

ActiveRecord::Base.extend PushyResources::Pushing

if EM.reactor_running?
  PushyResources::Server.run
else
  Thread.new do
    puts "Running EM reactor in new thread"
    EM.run { PushyResources::Server.run }
  end
end

EM.error_handler do |error|
  puts "Error raised during event loop: #{error.message}"
  puts error.stacktrace
end


