//
//  MainView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct MainView: View {
    @State private var trips: [Trip] = []
    @State private var checklistItems: [CheckListItem] = []

    var body: some View {
        TabView {
            ContentView(trips: $trips)
                .tabItem { Label("Home", systemImage: "house") }

            TripInfoView(trips: $trips)
                .tabItem { Label("Trip Info", systemImage: "info.circle") }

            CountdownView()
                .tabItem { Label("Countdown", systemImage: "calendar") }

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
