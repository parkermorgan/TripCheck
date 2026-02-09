import SwiftUI
import MapKit
import CoreLocation

struct CheckListItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

struct Trip: Identifiable {
    let id = UUID()
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let startDate: Date
    let endDate: Date
    var checklist: [CheckListItem]
}

struct CreateTripView: View {
    @State private var selectedLocation: MKMapItem?
    @State private var showLocationPicker = false
    @Binding var trips: [Trip]
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var checklistItems: [CheckListItem] = []
    @Environment(\.dismiss) var dismiss

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
                                Text(selectedLocation?.name ?? "Select")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .sheet(isPresented: $showLocationPicker) {
                            LocationPickerView(selectedLocation: $selectedLocation)
                        }
                    }

                    Section("Dates") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }

                    
                    .listRowBackground(Color(UIColor.systemBackground))

                    Button("Save Trip") {
                        guard let location = selectedLocation else { return }
                        let newTrip = Trip(
                            name: tripName,
                            locationName: location.name ?? "Unknown",
                            coordinate: location.location.coordinate,
                            startDate: startDate,
                            endDate: endDate,
                            checklist: checklistItems
                        )
                        trips.append(newTrip)
                        dismiss()
                    }
                }
                .scrollContentBackground(.hidden) // <-- makes Form background transparent
                .background(Color.clear)
                .navigationTitle("New Trip")
            }
        }
    }
}
#Preview {
    CreateTripView(trips: .constant([]))
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
