module Here
  class Normalizer
    def self.call(data)
      {
        routes: (data["routes"] || []).map.with_index do |route, i|
          segments = (route["sections"] || []).map.with_index do |segment, j|
            build_segment(segment, route, i, j)
          end

          summary = build_summary(segments)

          {
            id: "R#{i}",
            segments: segments,
            summary: summary
          }
        end
      }
    end

    private

    def self.build_segment(segment, route, route_index, segment_index)
      labels = build_labels(segment, route)

      {
        id: "R#{route_index}-S#{segment_index}",
        mode: segment.dig("transport", "mode") || segment["type"] || "unknown",
        color: segment.dig("transport", "color") || "#333",
        polyline: segment["polyline"],
        duration: segment.dig("travelSummary", "typicalDuration") ||
                  segment.dig("travelSummary", "duration"),
        distance: segment.dig("travelSummary", "length"),
        est_cost: nil, # TODO

        start: {
          time: segment.dig("departure", "time"),
          location: {
            name: segment.dig("departure", "place", "name") || "unknown",
            lat: segment.dig("departure", "place", "location", "lat"),
            lng: segment.dig("departure", "place", "location", "lng")
          }
        },

        end: {
          time: segment.dig("arrival", "time"),
          location: {
            name: segment.dig("arrival", "place", "name") || "unknown",
            lat: segment.dig("arrival", "place", "location", "lat"),
            lng: segment.dig("arrival", "place", "location", "lng")
          }
        },

        labels: labels,

        costs: build_costs(segment)
      }.compact
    end

    def self.build_costs(segment)
      costs =
        (segment["tolls"] || []).flat_map do |t|
          (t["fares"] || []).map { |f| f.dig("price") }
        end +
        (segment["fares"] || []).map { |f| f.dig("price") }

      grouped = costs.compact.group_by { |p| p["currency"] }

      grouped.map do |currency, items|
        {
          amount: items.sum { |p| p["value"].to_f },
          currency: currency
        }
      end
    end

    def self.build_labels(segment, route) [
        route_labels(route),
        transport_labels(segment)
      ].flatten.compact.presence
    end

    def self.route_labels(route)
      (route["routeLabels"] || []).filter_map do |label|
        { name: label.dig("name", "value") }
      end
    end

    def self.transport_labels(segment)
      t = segment["transport"]
      return unless t

      label = {
        name: t["name"] || t["shortName"],
        headsign: t["headsign"],
        agency: segment.dig("agency", "name"),
        url: segment.dig("agency", "website") || t["url"]
      }

      label.values.all?(&:nil?) ? nil : label
    end

    def self.build_summary(segments)
      segments = Array(segments).sort_by { |s| s.dig(:start, :time) }

      cost_map = Hash.new(0)

      labels = segments.map do |s|
        Array(s[:labels])
          .map { |l| l[:agency] || l[:name] }
          .compact
          .join(" → ")
      end.reject(&:empty?).join(" → ")

      total_distance = 0
      total_duration = 0
      walking_distance = 0
      walking_duration = 0

      segments.each do |s|
        d = s[:distance]
        t = s[:duration]

        total_distance += d
        total_duration += t

        if s[:mode] == "pedestrian"
          walking_distance += d
          walking_duration += t
        end

        Array(s[:costs]).each do |c|
          next unless c[:currency]
          cost_map[c[:currency]] += c[:amount].to_f
        end
      end

      {
        labels: labels,
        total_distance: total_distance,
        total_duration: total_duration,
        walking_distance: walking_distance,
        walking_duration: walking_duration,
        total_cost: cost_map.map { |currency, amount| { currency: currency, amount: amount } },
        start: segments.first&.dig(:start),
        end: segments.last&.dig(:end)
      }
    end
  end
end