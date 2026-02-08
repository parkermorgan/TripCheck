//
//  ContentView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/10/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var trips: [Trip]
    @Binding var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Welcome to TripCheck!")
                    .font(.largeTitle)

                NavigationLink {
                    CreateTripView(trips: $trips)
                } label: {
                    Text("Add Trip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                List(trips) { trip in
                    Button {
                        selectedTrip = trip
                    } label: {
                        Text(trip.name)
                    }
                }
            }
            .padding()
        }
    }
}



#Preview {
    ContentView(
        trips: .constant([]),
        selectedTrip: .constant(nil)
    )
}
