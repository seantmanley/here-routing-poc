module Here
  class Geocode
    def self.call(query:)
      Here::Client.get(
        :geocode,
        "/geocode",
        query: { q: query }
      )
    end

    def self.extract_coords(geocode)
        pos = geocode["items"].first["position"]
        "#{pos['lat']},#{pos['lng']}"
    end
  end
end