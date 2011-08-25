module PushyResources
  module CredentialsParser
    extend self

    def verifier
      @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.config.secret_token)
    end

    def parse(websocket)
      if websocket.request['query']['token'].present?
        token = websocket.request['query']['token']
        CredentialsParser.parse_token(token)
      else
        cookie = websocket.request['cookie'] || websocket.request['Cookie']
        CredentialsParser.parse_cookie(cookie)
      end
    end

    def parse_cookie(cookie)
      puts "credentials for cookie: #{cookie}"
      begin
        cookies = cookie.split(';')
        session_key = Rails.application.config.session_options[:key]
        encoded_session = cookies.detect{|c| c.include?(session_key)}.gsub("#{session_key}=",'').strip
        verifier.verify(encoded_session)
      rescue ActiveSupport::MessageVerifier::InvalidSignature => ex
        Rails.logger.error "invalid session cookie: #{cookie}"
        nil
      end
    end

    def parse_token(token)
      begin
        decoded_token = verifier.verify(token)
        ActiveSupport::JSON.decode(decoded_token)
      rescue ActiveSupport::MessageVerifier::InvalidSignature => ex
        Rails.logger.error "invalid session token: #{token}"
        nil
      end
    end

    def session_key
      Rails.application.config.session_options.key
    end

    def marshall
      Rails.application.config.session_options[:coder]
    end
  end
end