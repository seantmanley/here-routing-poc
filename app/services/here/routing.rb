module Here
  class Routing
    def self.call(origin:, destination:, mode:, leave_at: nil, arrive_by: nil)
      origin_geocode = Here::Client.get(
        :geocode,
        "/geocode",
        query: { q: origin }
      )
      
      dest_geocode = Here::Client.get(
        :geocode,
        "/geocode",
        query: { q: destination }
      )

      unless origin_geocode["items"]&.any? && dest_geocode["items"]&.any?
        raise ArgumentError, "Unable to geocode origin or destination"
      end

      base_query = {
        origin: extract_coords(origin_geocode),
        destination: extract_coords(dest_geocode),
        departureTime: leave_at,
        arrivalTime: arrive_by,
        alternatives: 2
      }

      if mode === "car" || mode === "taxi"
        Here::Client.get(
          :routing,
          "/routes",
          query: base_query.merge(
            transportMode: mode,
            routingMode: "fast",
            return: "travelSummary,typicalDuration,polyline,routeLabels,routeHandle,tolls"
          ).compact
        )
      elsif mode === "transit"
        Here::Client.get(
          :transit,
          "/routes",
          query: base_query.merge(
            return: "travelSummary,polyline,fares"
          ).compact
        )
      else
        raise ArgumentError, "Unsupported mode of transportation: #{mode}"
      end
    end

    private

    def self.extract_coords(geocode)
      pos = geocode["items"].first["position"]
      "#{pos['lat']},#{pos['lng']}"
    end
  end
end