//
//  park_plannerApp.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
import WidgetKit

private let appGroupID = "group.com.parkermorgan.tripcheck"

func sharedDefaults() -> UserDefaults {
    return UserDefaults(suiteName: appGroupID) ?? .standard
}

func saveTrips(_ trips: [Trip]) {
    if let encoded = try? JSONEncoder().encode(trips) {
        sharedDefaults().set(encoded, forKey: "savedTrips")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

func loadTrips() -> [Trip] {
    if let data = sharedDefaults().data(forKey: "savedTrips"),
       let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
        return decoded
    }
    return []
}

@main
struct park_plannerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
