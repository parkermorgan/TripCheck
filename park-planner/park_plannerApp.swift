//
//  park_plannerApp.swift
//  park-planner
//
//  Created by Parker Morgan on 1/10/26.
//

import SwiftUI

func saveTrips(_ trips: [Trip]) {
    if let encoded = try? JSONEncoder().encode(trips) {
        UserDefaults.standard.set(encoded, forKey: "savedTrips")
    }
}

func loadTrips() -> [Trip] {
    if let data = UserDefaults.standard.data(forKey: "savedTrips"),
       let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
        return decoded
    }
    return []
}

@main
struct park_plannerApp: App {
    @State private var trips: [Trip] = loadTrips()
    @State private var selectedTrip: UUID?
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
