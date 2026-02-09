//
//  MainView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct MainView: View {
    @State private var trips: [Trip] = []
    @State private var selectedTrip: Trip?
    @State private var checklistItems: [CheckListItem] = []

    var body: some View {
        TabView {
            ContentView(trips: $trips, selectedTrip: $selectedTrip)
                .tabItem { Label("Home", systemImage: "house") }

            TripInfoView(trips: $trips, selectedTrip: $selectedTrip)
                .tabItem { Label("Trip Info", systemImage: "info.circle") }

            if let trip = selectedTrip {
                CountdownView(trip: trip)
                    .tabItem { Label("Countdown", systemImage: "calendar") }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    VStack {
                        Text("Select a trip to see the countdown")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 8)
                    }
                }
                .tabItem { Label("Countdown", systemImage: "calendar") }
            }

            WeatherView(trips: $trips)
                .tabItem { Label("Weather", systemImage: "sun.max") }

            TripChecklistTab(trips: $trips)
                .tabItem { Label("Checklist", systemImage: "checkmark.circle") }
        }
    }
}

#Preview {
    MainView()
        
}
