//
//  ContentView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/10/26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    
    // State variables
    @Binding var trips: [Trip]
    @Binding var selectedTrip: UUID?
    @State private var showTrips = false
    @State private var showTripAlert = false
    @State private var tappedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
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
                                Text("TripCheck")
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

                VStack(spacing: 24) {
                    Spacer().frame(height: 100)

                    Image("TripCheck-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                    // Welcome text
                    VStack(spacing: 6) {
                        Text("Welcome to TripCheck")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Plan your next adventure")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Buttons for adding and vewing trips
                    VStack(spacing: 12) {
                        NavigationLink(destination: CreateTripView(trips: $trips, selectedTrip: $selectedTrip)) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Trip")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                        }

                        Button {
                            withAnimation { showTrips.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.circle.fill")
                                Text(showTrips ? "Hide Trips" : "View Trips")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                trips.isEmpty
                                ? AnyShapeStyle(Color.gray.opacity(0.4))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            )
                            .cornerRadius(30)
                        }
                        .disabled(trips.isEmpty)
                    }
                    .padding(.horizontal, 30)

                    // Shows trip button, only shows if trips have been created.
                    if showTrips && !trips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Trips")
                                .font(.headline)
                                .padding(.horizontal, 8)

                            ForEach(trips) { trip in
                                Button {
                                    tappedTrip = trip
                                    showTripAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(trip.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text(trip.locationName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.85))
                                    .cornerRadius(30)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }

                    Spacer()

                    Text("Created by Parker Morgan")
                        .foregroundColor(.secondary)
                        .italic()
                        .font(.caption)
                        .padding(.bottom, 25)
                }
                
                // Confirms trip selection to user.
                .alert("Trip Selected", isPresented: $showTripAlert) {
                    Button("OK") {
                        selectedTrip = tappedTrip?.id
                        showTrips = false
                    }
                } message: {
                    Text("This trip has been selected.")
                }
            }
        }
    }
}

// Sample data for preview.
#Preview {
    ContentView(
        trips: .constant([
            Trip(
                name: "Hawaii Trip",
                locationName: "Honolulu",
                coordinate: .init(latitude: 21.3069, longitude: -157.8583),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 5),
                checklist: []
            )
        ]),
        selectedTrip: .constant(nil)
    )
}
