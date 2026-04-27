# app/clients/here/client.rb
module Here
  class Client
    BASE_URLS = {
      geocode: "https://geocode.search.hereapi.com/v1",
      routing: "https://router.hereapi.com/v8",
      transit: "https://transit.router.hereapi.com/v8"
    }.freeze

    class << self
      def get(service, path, query: {})
        return stub_response(service, path, query) if stub_mode?

        response = HTTParty.get(
          "#{BASE_URLS.fetch(service)}#{path}",
          headers: { "Accept" => "application/json" },
          query: query.merge(apiKey: api_key)
        )
        maybe_record(service, path, query, response.parsed_response)
        handle_response(service, response)
      end

      def post(service, path, body: {})
        return stub_response(service, path, body) if stub_mode?
        
        response = HTTParty.post(
          "#{BASE_URLS.fetch(service)}#{path}",
          body: body.to_json,
          headers: { 
            "Content-Type" => "application/json",
            "Accept" => "application/json" },
          query: { apiKey: api_key }
        )
        maybe_record(service, path, body, response.parsed_response)
        handle_response(service, response)
      end

      private

      def stub_mode?
        Rails.configuration.here_api_mode == :stub
      end

      def stub_response(service, path, params)
        data = Stubs.fetch(service, path, query: params)
        service == :geocode ? data : Normalizer.call(data)
      end

      def maybe_record(service, path, query, raw_response)
        return unless Rails.configuration.here_api_mode == :record

        key = Stubs.build_key(service, path, query)
        file_path = Stubs::BASE_PATH.join("#{key}.json")

        Rails.logger.info("[RECORD STUB] #{key}.json")

        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, JSON.pretty_generate(raw_response))
      end

      def api_key
        Rails.application.credentials.dig(:here, :api_key)
      end

      def handle_response(service, response)        
        unless response.success?
          message = response.parsed_response&.dig("error", "message") || response.body
          raise StandardError, message
        end

        service == :geocode ? response.parsed_response : Normalizer.call(response.parsed_response)
      end
    end
  end
end 