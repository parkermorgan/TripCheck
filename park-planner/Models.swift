//
//  Models.swift
//  park-planner
//
//  Created by Parker Morgan on 3/2/26.
//

import Foundation
import CoreLocation

struct CheckListItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

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
