module Here
  class Routing
    def self.call(origin:, destination:, mode:, leave_at: nil, arrive_by: nil)
      origin_geocode = Client.get(
        :geocode,
        "/geocode",
        query: { q: origin }
      )
      
      dest_geocode = Client.get(
        :geocode,
        "/geocode",
        query: { q: destination }
      )

      unless origin_geocode["items"]&.any? && dest_geocode["items"]&.any?
        raise ArgumentError, "Unable to geocode origin or destination"
      end

      base_query = {
        origin: Geocode.extract_coords(origin_geocode),
        destination: Geocode.extract_coords(dest_geocode),
        departureTime: leave_at,
        arrivalTime: arrive_by,
        alternatives: 2
      }

      data = {}

      if mode == "car" || mode == "taxi"
        data = Client.get(
          :routing,
          "/routes",
          query: base_query.merge(
            transportMode: mode,
            routingMode: "fast",
            return: "travelSummary,typicalDuration,polyline,routeLabels,routeHandle,tolls"
          ).compact
        )
      elsif mode == "transit"
        data = Client.get(
          :transit,
          "/routes",
          query: base_query.merge(
            return: "travelSummary,polyline,fares"
          ).compact
        )
      else
        raise ArgumentError, "Unsupported mode of transportation: #{mode}"
      end

      updateNames(data, origin_geocode, dest_geocode)
    end

    private

    def self.updateNames(data, origin, dest)
      origin_name = origin["items"].first["title"] # TODO handle multiple geocoding results
      dest_name = dest["items"].first["title"] # TODO handle multiple geocoding results

      data[:routes].each do |r|
        s = r[:segments]
        s.first[:start][:location][:name] = origin_name
        s.last[:end][:location][:name] = dest_name
      end

      data
    end
  end
end