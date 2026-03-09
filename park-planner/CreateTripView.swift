import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

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
    @Environment(\.colorScheme) var colorScheme

    var existingTrip: Trip? = nil

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Top banner
            VStack {
                HStack {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(.rect(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 80, topTrailingRadius: 0))
                        .overlay(
                            Text(existingTrip == nil ? "New Trip" : "Edit Trip")
                                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Bottom banner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.5)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(.rect(topLeadingRadius: 80, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 16) {
                Spacer().frame(height: 100)

                ScrollView {
                    VStack(spacing: 16) {

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trip Info")
                                .font(.headline)
                                .padding(.horizontal, 8)

                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    TextField("Trip name", text: $tripName)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(cardBackground)
                                .cornerRadius(30)

                                Button {
                                    showLocationPicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        Text("Location")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(selectedLocation?.name ?? existingTrip?.locationName ?? "Select")
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(cardBackground)
                                .cornerRadius(30)
                                .sheet(isPresented: $showLocationPicker) {
                                    LocationPickerView(selectedLocation: $selectedLocation)
                                }
                            }
                        }
                        .padding(.horizontal, 30)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dates")
                                .font(.headline)
                                .padding(.horizontal, 8)

                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                        .onChange(of: startDate) { newValue in
                                            if endDate < newValue { endDate = newValue }
                                        }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(cardBackground)
                                .cornerRadius(30)

                                HStack {
                                    Image(systemName: "calendar.badge.checkmark")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(cardBackground)
                                .cornerRadius(30)
                            }
                        }
                        .padding(.horizontal, 30)

                        Button {
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

                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                    if granted {
                                        scheduleTripNotification(for: newTrip)
                                        print("Notification scheduled for \(newTrip.name)")
                                    } else {
                                        print("Permission denied")
                                    }
                                }
                            }

                            alertMessage = existingTrip == nil ? "\(tripName) added successfully!" : "\(tripName) updated successfully!"
                            isSuccess = true
                            showAlert = true
                        } label: {
                            Text(existingTrip == nil ? "Save Trip" : "Update Trip")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient(
                                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .cornerRadius(30)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
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

#Preview {
    CreateTripView(trips: .constant([]), selectedTrip: .constant(nil))
}

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedLocation: MKMapItem?

    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Top banner
            VStack {
                HStack {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(.rect(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 80, topTrailingRadius: 0))
                        .overlay(
                            Text("Pick a Location")
                                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Bottom banner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.5)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(.rect(topLeadingRadius: 80, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 12) {
                Spacer().frame(height: 100)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for a location", text: $searchQuery)
                        .onChange(of: searchQuery) { newValue in
                            searchLocations()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(cardBackground)
                .cornerRadius(30)
                .padding(.horizontal, 30)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectedLocation = item
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? "Unknown")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(item.placemark.title ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(cardBackground)
                                .cornerRadius(30)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
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
