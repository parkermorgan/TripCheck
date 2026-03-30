//
//  Models.swift
//  park-planner
//
//  Created by Parker Morgan on 3/2/26.
//

import Foundation
import CoreLocation


// Models that are created for needed items, views pull from models for data.
struct CheckListItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var category: String
    var notificationsEnabled: Bool = false
    var date: Date?
}

let defaultChecklistItems: [CheckListItem] = [
    // Travel Prep
    CheckListItem(title: "Book flights", isCompleted: false, category: "Travel Prep"),
    CheckListItem(title: "Book hotel", isCompleted: false, category: "Travel Prep"),
    CheckListItem(title: "Check passport expiry", isCompleted: false, category: "Travel Prep"),

    // Packing
    CheckListItem(title: "Pack clothes", isCompleted: false, category: "Packing"),
    CheckListItem(title: "Pack toiletries", isCompleted: false, category: "Packing"),
    CheckListItem(title: "Pack chargers", isCompleted: false, category: "Packing"),
]

struct Trip: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var locationName: String
    var coordinate: CLLocationCoordinate2D
    var startDate: Date
    var endDate: Date
    var checklist: [CheckListItem]
    
    var tripDates: [Date] {
            var dates: [Date] = []
            let calendar = Calendar.current
            
            guard let start = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: startDate),
                  let end = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endDate) else {
                return []
            }
            
            var currentDate = start
            while currentDate <= end {
                dates.append(currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            return dates
        }

    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.locationName == rhs.locationName &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.checklist == rhs.checklist
    }

    enum CodingKeys: String, CodingKey {
        case id, name, locationName, latitude, longitude, startDate, endDate, checklist
    }

    init(id: UUID = UUID(), name: String, locationName: String, coordinate: CLLocationCoordinate2D, startDate: Date, endDate: Date, checklist: [CheckListItem]) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.coordinate = coordinate
        self.startDate = startDate
        self.endDate = endDate
        self.checklist = checklist
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        locationName = try container.decode(String.self, forKey: .locationName)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        checklist = try container.decode([CheckListItem].self, forKey: .checklist)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(checklist, forKey: .checklist)
    }
}
