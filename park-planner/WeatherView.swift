//
//  WeatherView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct WeatherView: View {
    @Binding var trips: [Trip]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                if trips.isEmpty {
                    Text("Select a trip to see its weather")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
                else{
                    List(trips) { trip in
                        VStack(alignment: .leading) {
                            Text(trip.name)
                                .font(.headline)
                            Text("Location: \(trip.locationName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.white.opacity(0.3))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding()
        }
    }
        
}

#Preview {
    WeatherView(trips: .constant([]))
}
