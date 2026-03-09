//
//  TripCheckWidget.swift
//  TripCheckWidget
//
//  Created by Parker Morgan on 3/8/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared helpers

private let appGroupID = "group.com.parkermorgan.tripcheck"

private func loadTripsFromGroup() -> [TripEntry] {
    let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
    guard let data = defaults.data(forKey: "savedTrips"),
          let decoded = try? JSONDecoder().decode([TripEntry].self, from: data) else {
        return []
    }
    return decoded
}

// Minimal codable trip model for the widget (mirrors your main app's Trip)
struct TripEntry: Codable, Identifiable {
    var id: UUID
    var name: String
    var locationName: String
    var startDate: Date
    var endDate: Date
    var checklist: [ChecklistItemEntry]

    init(id: UUID = UUID(), name: String, locationName: String, startDate: Date, endDate: Date, checklist: [ChecklistItemEntry]) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.startDate = startDate
        self.endDate = endDate
        self.checklist = checklist
    }

    enum CodingKeys: String, CodingKey {
        case id, name, locationName, latitude, longitude, startDate, endDate, checklist
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,   forKey: .id)
        name         = try c.decode(String.self, forKey: .name)
        locationName = try c.decode(String.self, forKey: .locationName)
        startDate    = try c.decode(Date.self,   forKey: .startDate)
        endDate      = try c.decode(Date.self,   forKey: .endDate)
        checklist    = try c.decode([ChecklistItemEntry].self, forKey: .checklist)
        // latitude/longitude decoded but not stored — widget doesn't need them
        _ = try? c.decode(Double.self, forKey: .latitude)
        _ = try? c.decode(Double.self, forKey: .longitude)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(name,         forKey: .name)
        try c.encode(locationName, forKey: .locationName)
        try c.encode(startDate,    forKey: .startDate)
        try c.encode(endDate,      forKey: .endDate)
        try c.encode(checklist,    forKey: .checklist)
        try c.encode(0.0,          forKey: .latitude)
        try c.encode(0.0,          forKey: .longitude)
    }
}

struct ChecklistItemEntry: Codable {
    var isCompleted: Bool
}

// MARK: - Timeline

struct WidgetTimelineEntry: TimelineEntry {
    let date: Date
    let trip: TripEntry?
    let daysUntil: Int
    let checklistProgress: Double
    let completedCount: Int
    let totalCount: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetTimelineEntry {
        WidgetTimelineEntry(date: Date(), trip: nil, daysUntil: 12, checklistProgress: 0.4, completedCount: 3, totalCount: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetTimelineEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetTimelineEntry>) -> Void) {
        // Refresh every hour
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> WidgetTimelineEntry {
        let trips = loadTripsFromGroup()
        let today = Calendar.current.startOfDay(for: Date())

        let nextTrip = trips
            .filter { $0.startDate >= today }
            .sorted { $0.startDate < $1.startDate }
            .first ?? trips.sorted { $0.startDate < $1.startDate }.last

        guard let trip = nextTrip else {
            return WidgetTimelineEntry(date: Date(), trip: nil, daysUntil: 0, checklistProgress: 0, completedCount: 0, totalCount: 0)
        }

        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0)
        let completed = trip.checklist.filter { $0.isCompleted }.count
        let total = trip.checklist.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0

        return WidgetTimelineEntry(date: Date(), trip: trip, daysUntil: days, checklistProgress: progress, completedCount: completed, totalCount: total)
    }
}

// MARK: - Views

struct TripCheckWidgetEntryView: View {
    var entry: WidgetTimelineEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let trip = entry.trip {
            switch family {
            case .systemSmall:
                smallView(trip: trip)
            case .systemMedium:
                mediumView(trip: trip)
            default:
                mediumView(trip: trip)
            }
        } else {
            noTripView
        }
    }

    // MARK: Small
    func smallView(trip: TripEntry) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT TRIP")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
                    .tracking(1.5)

                Text(trip.name)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)

                Text(trip.locationName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(entry.daysUntil)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .top, endPoint: .bottom
                        ))
                    Text(entry.daysUntil == 1 ? "day" : "days")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
        }

    // MARK: Medium
    func mediumView(trip: TripEntry) -> some View {

            HStack(spacing: 16) {
                // Left: trip info
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT TRIP")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.8))
                        .tracking(1.5)

                    Text(trip.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text(trip.locationName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if entry.totalCount > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Checklist")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(entry.completedCount)/\(entry.totalCount)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(entry.checklistProgress == 1.0 ? .green : .blue)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(LinearGradient(
                                            colors: entry.checklistProgress == 1.0
                                                ? [Color.green.opacity(0.7), Color.green.opacity(0.5)]
                                                : [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * entry.checklistProgress, height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }

                // Right: countdown
                VStack(spacing: 2) {
                    Text("\(entry.daysUntil)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .top, endPoint: .bottom
                        ))
                    Text(entry.daysUntil == 1 ? "day" : "days")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
            }
            .padding(16)
        }
    

    // MARK: No trip
    var noTripView: some View {
        
            VStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No trips planned")
                    .font(.system(size: 13, weight: .semibold))
                Text("Open TripCheck to add one")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }


// MARK: - Widget

struct TripCheckWidget: Widget {
    let kind: String = "TripCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TripCheckWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("TripCheck")
        .description("See your next trip countdown and checklist progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    TripCheckWidget()
} timeline: {
    WidgetTimelineEntry(
        date: .now,
        trip: TripEntry(
            id: UUID(),
            name: "Hawaii Trip",
            locationName: "Honolulu",
            startDate: Date().addingTimeInterval(86400 * 10),
            endDate: Date().addingTimeInterval(86400 * 15),
            checklist: []
        ),
        daysUntil: 10,
        checklistProgress: 0.4,
        completedCount: 3,
        totalCount: 8
    )
}
