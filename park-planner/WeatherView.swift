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
        List(trips) { trip in
            VStack(alignment: .leading) {
                Text(trip.name)
                    .font(.headline)
                Text("Location: \(trip.locationName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    WeatherView(trips: .constant([]))
}
