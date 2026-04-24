module Here
  class Stubs
    BASE_PATH = Rails.root.join("spec/fixtures/here")

    def self.fetch(service, path, query: {})
        key = build_key(service, path, query)
        file = BASE_PATH.join("#{key}.json")

        Rails.logger.info("[LOAD STUB] #{key}.json")
        raise "Missing stub file: #{file}" unless File.exist?(file)

        JSON.parse(File.read(file))
    end

    require "digest"

    def self.build_key(service, path, query)
        normalized = normalize_params(query)
        digest = Digest::SHA256.hexdigest(normalized.to_json)

        "#{service}__#{path.gsub('/', '_')}__#{digest}"
    end
    
    private 

    def self.normalize_params(params)
        params
            .deep_stringify_keys
            .sort
            .to_h
    end
  end
end