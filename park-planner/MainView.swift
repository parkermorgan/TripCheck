//
//  MainView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
import UserNotifications



func scheduleTripNotification(for trip: Trip) {
    let content = UNMutableNotificationContent()
    content.title = "Your trip starts today! ✈️"
    content.body = "\(trip.name) to \(trip.locationName) begins today. Have a great trip!"
    content.sound = .default

    var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: trip.startDate)
    dateComponents.hour = 8
    dateComponents.minute = 0

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
    let request = UNNotificationRequest(identifier: trip.id.uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
}

func cancelTripNotification(for trip: Trip) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trip.id.uuidString])
}

struct MainView: View {
    @State private var trips: [Trip] = loadTrips()
    @State private var selectedTrip: UUID?
    @State private var checklistItems: [CheckListItem] = []

    var currentTrip: Trip? {
        trips.first(where: { $0.id == selectedTrip })
    }

    var body: some View {
        TabView {
            ContentView(trips: $trips, selectedTrip: $selectedTrip)
                .tabItem { Label("Home", systemImage: "house") }

            TripInfoView(trips: $trips, selectedTrip: $selectedTrip)
                .tabItem { Label("Trip Info", systemImage: "info.circle") }

            if let trip = currentTrip {
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
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    for trip in trips {
                        scheduleTripNotification(for: trip)
                    }
                }
            }
        }
        .onChange(of: trips) { updatedTrips in
            saveTrips(updatedTrips)

            let oldIDs = Set(trips.map { $0.id })
            let newIDs = Set(updatedTrips.map { $0.id })

            for trip in trips where !newIDs.contains(trip.id) {
                cancelTripNotification(for: trip)
            }

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    for trip in updatedTrips where !oldIDs.contains(trip.id) {
                        scheduleTripNotification(for: trip)
                        print("Scheduled notification for \(trip.name)")
                    }
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }
}

#Preview {
    MainView()
}
