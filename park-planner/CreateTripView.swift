//
//  CreateTripView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/15/26.
//

import SwiftUI

struct Trip: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let startDate: Date
    let endDate: Date
}

struct CreateTripView: View {
    @Binding var trips: [Trip]
    @State private var tripName = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Trip name", text: $tripName)
                    TextField("Location", text: $location)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Button("Save Trip") {
                    let newTrip = Trip(
                        name: tripName,
                        location: location,
                        startDate: startDate,
                        endDate: endDate
                    )
                    trips.append(newTrip)
                }
                .navigationTitle("New Trip")
            }
        }
    }
}

#Preview {
    CreateTripView(trips: .constant([]))
}
