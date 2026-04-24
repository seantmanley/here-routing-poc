module Here
  class Geocode
    def self.call(query:)
      Here::Client.get(
        :geocode,
        "/geocode",
        query: { q: query }
      )
    end
  end
end