//
//  CountdownView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
import CoreLocation

func daysUntil(_ date: Date) -> Int {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    let startOfTrip = calendar.startOfDay(for: date)
    
    let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTrip)
    return components.day ?? 0
}

struct CountdownView: View {
    let trip: Trip

    var daysRemaining: Int {
        daysUntil(trip.startDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Countdown to your trip")
                .font(.headline)

            if daysRemaining > 0 {
                Text("\(daysRemaining) days to go 🎒")
                    .font(.largeTitle)
                    .bold()
            } else if daysRemaining == 0 {
                Text("Trip starts today! ✈️")
                    .font(.largeTitle)
            } else {
                Text("Trip already started")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    CountdownView(
        trip: Trip(
            name: "Sample Trip",
            locationName: "Yosemite National Park",
            coordinate: CLLocationCoordinate2D(latitude: 37.8651, longitude: -119.5383),
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 7),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 10),
            checklist: []
        )
    )
}
