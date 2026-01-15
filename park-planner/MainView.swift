//
//  MainView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            TripInfoView()
                .tabItem {
                    Label("Trip Info", systemImage: "info.circle")
                }
            CountdownView()
                .tabItem {
                    Label("Countdown", systemImage: "calendar")
                }
            WeatherView()
                .tabItem {
                    Label("Weather", systemImage: "sun.max")
                }
            ChecklistView()
                .tabItem {
                    Label("Checklist", systemImage: "checkmark.circle")
                }
            
        }
    }
}

#Preview {
    MainView()
        
}
