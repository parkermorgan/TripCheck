//
//  Models.swift
//  park-planner
//
//  Created by Parker Morgan on 3/2/26.
//

import Foundation
import CoreLocation


// Models that are created for needed items, views pull from models for data.
struct CheckListItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var category: String
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

    // At the Park
    CheckListItem(title: "Download offline maps", isCompleted: false, category: "At the Park"),
    CheckListItem(title: "Buy park pass", isCompleted: false, category: "At the Park"),
]

struct Trip: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var locationName: String
    var coordinate: CLLocationCoordinate2D
    var startDate: Date
    var endDate: Date
    var checklist: [CheckListItem]

    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.locationName == rhs.locationName &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate
    }
}
