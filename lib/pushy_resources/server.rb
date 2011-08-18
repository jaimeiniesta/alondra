require 'em-websocket'
require 'em-synchrony'
require 'em-synchrony/em-http'

module PushyResources
  module Server
    extend self

    def run
      EM.synchrony do

        Rails.logger.error "Server starting on 0.0.0.0:12345"

        puts "starting server on port: #{PushyResources.config.port}"

        EM::WebSocket.start(:host => '0.0.0.0', :port => PushyResources.config.port) do |websocket|

          websocket.onopen do
            token = websocket.request['query']['token']

            credentials = CredentialsParser.parse(token)
            Rails.logger.info "client connected. credentials: #{credentials}"

            Connection.new(websocket, credentials)
          end

          websocket.onclose do
            Connections[websocket].destroy!
          end

          websocket.onerror do |ex|
            Rails.logger.error "Error: #{ex.message}"
            Rails.logger.error ex.backtrace.join("\n")
            Connections[websocket].destroy!
          end

          websocket.onmessage do |msg|
            Rails.logger.info "received: #{msg}"
            MessageDispatcher.dispatch(msg, Connections[websocket])
          end
        end
      end
    end
  end
end