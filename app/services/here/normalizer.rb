module Here
  class Normalizer
    def self.call(data)
      {
        routes: (data["routes"] || []).map.with_index do |route, i|
          segments = route["sections"] || []

          {
            id: "R#{i}",
            segments: segments.map.with_index do |segment, j|
              build_segment(segment, i, j)
            end
          }
        end
      }
    end

    private

    def self.build_segment(segment, route_index, segment_index)
      {
        id: "R#{route_index}-S#{segment_index}",
        type: segment.dig("transport", "mode") || "unknown",

        travelSummary: {
          duration: segment.dig("travelSummary", "duration") ||
                    segment.dig("summary", "duration"),

          length: segment.dig("travelSummary", "length") ||
                  segment.dig("summary", "length")
        },

        departure: build_place(segment["departure"]),
        arrival: build_place(segment["arrival"]),

        polyline: segment["polyline"],

        transport: {
          mode: segment.dig("transport", "mode")
        }
      }
    end

    def self.build_place(node)
      place = node["place"] || {}

      {
        time: node["time"],
        place: {
          name: place["name"],
          type: place["type"] || "place",
          location: {
            lat: place.dig("location", "lat"),
            lng: place.dig("location", "lng")
          }
        }
      }
    end
  end
end