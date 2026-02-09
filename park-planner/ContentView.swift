//
//  ContentView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/10/26.
//

import SwiftUI

struct LargeButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(width: 250)
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 24/255, green: 195/255, blue: 249/255),
                        Color.blue.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

struct ContentView: View {
    @Binding var trips: [Trip]
    @Binding var selectedTrip: Trip?
    @State private var showTrips = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    Text("TripCheck")
                        .font(.largeTitle)

                    Image("TripCheck-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                    NavigationLink(destination: CreateTripView(trips: $trips)) {
                        LargeButton(title: "Add Trip")
                    }
                    Button {
                        withAnimation {
                            showTrips.toggle()
                        }
                    } label: {
                        LargeButton(title: showTrips ? "Hide Trips" : "View Trips")
                    }
                    .disabled(trips.isEmpty)
                    .opacity(trips.isEmpty ? 0.5 : 1)
                    .sheet(isPresented: $showTrips) {
                        NavigationStack {
                            VStack {
                                Text("Your Trips")
                                    .font(.title)
                                    .padding()

                                if trips.isEmpty {
                                    Text("No trips available.")
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    List(trips) { trip in
                                        Button {
                                            selectedTrip = trip
                                            showTrips = false
                                        } label: {
                                            Text(trip.name)
                                        }
                                    }
                                    .listStyle(.plain)
                                }
                                Spacer()
                                Button("Close") {
                                    showTrips = false
                                }
                                .padding()
                            }
                        }
                    }

                    Spacer()
                        .padding(.top)
                    Text("Created by Parker Morgan")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.bottom, 25)
                    
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
    }
}



#Preview {
    ContentView(
        trips: .constant([]),
        selectedTrip: .constant(nil)
    )
}
