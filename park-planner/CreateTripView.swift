import SwiftUI
import MapKit
import CoreLocation

struct CreateTripView: View {
    @State private var selectedLocation: MKMapItem?
    @State private var showLocationPicker = false
    @Binding var trips: [Trip]
    @Binding var selectedTrip: UUID?
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var checklistItems: [CheckListItem] = []
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var existingTrip: Trip? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NavigationStack {
                Form {
                    Section("Trip Info") {
                        TextField("Trip name", text: $tripName)
                        Button {
                            showLocationPicker = true
                        } label: {
                            HStack {
                                Text("Location")
                                Spacer()
                                Text(selectedLocation?.name ?? existingTrip?.locationName ?? "Select")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .sheet(isPresented: $showLocationPicker) {
                            LocationPickerView(selectedLocation: $selectedLocation)
                        }
                    }

                    Section("Dates") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .onChange(of: startDate) { newValue in
                                if endDate < newValue {
                                    endDate = newValue
                                }
                            }
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }

                    Button(existingTrip == nil ? "Save Trip" : "Update Trip") {
                        let locationName = selectedLocation?.name ?? existingTrip?.locationName ?? ""
                        let coordinate = selectedLocation?.placemark.coordinate ?? existingTrip?.coordinate

                        guard !tripName.isEmpty, !locationName.isEmpty, let coordinate = coordinate else {
                            alertMessage = "Please fill in all fields."
                            isSuccess = false
                            showAlert = true
                            return
                        }

                        if let existing = existingTrip,
                           let index = trips.firstIndex(where: { $0.id == existing.id }) {
                            var updatedTrip = Trip(
                                name: tripName,
                                locationName: locationName,
                                coordinate: coordinate,
                                startDate: startDate,
                                endDate: endDate,
                                checklist: checklistItems
                            )
                            updatedTrip.id = existing.id
                            trips[index] = updatedTrip

                            if selectedTrip == existing.id {
                                selectedTrip = nil
                                selectedTrip = existing.id
                            }
                        } else {
                            let newTrip = Trip(
                                name: tripName,
                                locationName: locationName,
                                coordinate: coordinate,
                                startDate: startDate,
                                endDate: endDate,
                                checklist: defaultChecklistItems
                            )
                            trips.append(newTrip)
                        }

                        alertMessage = existingTrip == nil ? "\(tripName) added successfully!" : "\(tripName) updated successfully!"
                        isSuccess = true
                        showAlert = true
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .navigationTitle(existingTrip == nil ? "New Trip" : "Edit Trip")
                .alert(isSuccess ? "Success" : "Notice", isPresented: $showAlert) {
                    Button("OK") {
                        if isSuccess { dismiss() }
                    }
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    if let trip = existingTrip {
                        tripName = trip.name
                        startDate = trip.startDate
                        endDate = trip.endDate
                        checklistItems = trip.checklist
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTripView(trips: .constant([]), selectedTrip: .constant(nil))
}

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: MKMapItem?

    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search for a location", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchQuery) { newValue in
                        searchLocations()
                    }

                List(searchResults, id: \.self) { item in
                    Button {
                        selectedLocation = item
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                            Text(item.placemark.title ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Pick a Location")
        }
    }

    func searchLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let mapItems = response?.mapItems {
                searchResults = mapItems
            }
        }
    }
}
