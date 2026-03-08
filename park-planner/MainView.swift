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
    @State private var showHelper = false

    var currentTrip: Trip? {
        trips.first(where: { $0.id == selectedTrip })
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
                            HStack {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                                    .clipShape(
                                        .rect(
                                            topLeadingRadius: 0,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 80,
                                            topTrailingRadius: 0
                                        )
                                    )
                                    .overlay(
                                        Text("Countdown")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.leading, 20),
                                        alignment: .leading
                                    )
                                Spacer()
                            }
                            .ignoresSafeArea()
                            Spacer()
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                                    .clipShape(
                                        .rect(
                                            topLeadingRadius: 80,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 0
                                        )
                                    )
                            }
                            .ignoresSafeArea()
                        }

                        VStack(spacing: 12) {
                            Spacer().frame(height: 100)
                            VStack(spacing: 10) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)

                                Text("No trips planned yet")
                                    .font(.headline)

                                Text("Add a trip to start the countdown")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(.systemBackground).opacity(0.85))
                            .cornerRadius(30)
                            .padding(.horizontal, 30)

                            Spacer()
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
            .sheet(isPresented: $showHelper) {
                HelperView(trips: $trips)
            }

            // Sparkle button overlaid on all tabs
            Button {
                showHelper = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.leading, 24)
            .padding(.bottom, 80)
        }
    }
}

#Preview {
    MainView()
}
