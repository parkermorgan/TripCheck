import SwiftUI
import CoreLocation
import MapKit

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct TripCard: View {
    @Binding var trip: Trip
    @Binding var selectedTrip: UUID?
    var onEdit: () -> Void
    var onDelete: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground).opacity(0.9)
    }

    var isSelected: Bool { selectedTrip == trip.id }

    var days: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
        return max(0, days)
    }

    var progress: Double {
        guard !trip.checklist.isEmpty else { return 0 }
        let completed = trip.checklist.filter { $0.isCompleted }.count
        return Double(completed) / Double(trip.checklist.count)
    }

    var completedCount: Int { trip.checklist.filter { $0.isCompleted }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if isSelected {
                        Text("SELECTED")
                            .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(LinearGradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                    }
                    Text(trip.name).font(.title3).fontWeight(.bold)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.blue).font(.caption)
                        Text(trip.locationName).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(days)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .top, endPoint: .bottom))
                    Text(days == 1 ? "day" : "days").font(.caption2).foregroundColor(.secondary)
                }
                .padding(10).background(Color.blue.opacity(0.07)).cornerRadius(16)
            }

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "calendar").foregroundColor(.blue).font(.caption)
                Text("\(dateFormatter.string(from: trip.startDate)) – \(dateFormatter.string(from: trip.endDate))")
                    .font(.caption).foregroundColor(.secondary)
            }

            if !trip.checklist.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Checklist").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(completedCount)/\(trip.checklist.count) done")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(progress == 1.0 ? .green : .blue)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.1)).frame(height: 7)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: progress == 1.0 ? [Color.green.opacity(0.7), Color.green.opacity(0.5)] : [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * progress, height: 7)
                                .animation(.spring(response: 0.6), value: progress)
                        }
                    }
                    .frame(height: 7)
                }
            } else {
                Text("No checklist items yet").font(.caption).foregroundColor(.secondary)
            }

            // MARK: - Local Discovery Section (Visible only when selected)
            if isSelected {
                Divider()
                PlaceDiscoveryView(coordinate: trip.coordinate)
            }

            Divider()

            HStack(spacing: 0) {
                Button {
                    selectedTrip = isSelected ? nil : trip.id
                } label: {
                    Label(isSelected ? "Deselect" : "Select", systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline).foregroundColor(isSelected ? .green : .blue)
                }
                Spacer()
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil").font(.subheadline).foregroundColor(.blue)
                }
                Spacer()
                Button { onDelete() } label: {
                    Label("Delete", systemImage: "trash").font(.subheadline).foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(LinearGradient(
                    colors: isSelected ? [Color.blue.opacity(0.5), Color.purple.opacity(0.5)] : [Color.clear, Color.clear],
                    startPoint: .leading, endPoint: .trailing
                ), lineWidth: 2)
        )
    }
}

// MARK: - Place Discovery View
struct PlaceDiscoveryView: View {
    let coordinate: CLLocationCoordinate2D
    
    @State private var hotels: [MKMapItem] = []
    @State private var restaurants: [MKMapItem] = []
    
    @State private var showHotels = false
    @State private var showRestaurants = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var buttonBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color.white
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Discover Nearby")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Hotels Card
                Button {
                    withAnimation { showHotels.toggle() }
                    if showHotels && hotels.isEmpty { fetchPlaces(query: "Hotels", isHotel: true) }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Hotels", systemImage: "building.fade.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text(showHotels ? "Hide list" : "Show top 5")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(buttonBackground)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 5)
                }
                .buttonStyle(.plain)
                
                // Restaurants Card
                Button {
                    withAnimation { showRestaurants.toggle() }
                    if showRestaurants && restaurants.isEmpty { fetchPlaces(query: "Restaurants", isHotel: false) }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Dining", systemImage: "fork.knife")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.purple)
                        Text(showRestaurants ? "Hide list" : "Show top 5")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(buttonBackground)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 5)
                }
                .buttonStyle(.plain)
            }
            
            // Hotels List
            if showHotels {
                PlaceList(places: hotels, iconName: "bed.double.fill", iconColor: .blue)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Restaurants List
            if showRestaurants {
                PlaceList(places: restaurants, iconName: "fork.knife", iconColor: .purple)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func fetchPlaces(query: String, isHotel: Bool) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Center the search on your trip's coordinates
        request.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let items = response?.mapItems else { return }
            
            DispatchQueue.main.async {
                let limitedList = Array(items.prefix(5))
                if isHotel {
                    self.hotels = limitedList
                } else {
                    self.restaurants = limitedList
                }
            }
        }
    }
}

// MARK: - Reusable List for MapItems
struct PlaceList: View {
    let places: [MKMapItem]
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if places.isEmpty {
                Text("Searching...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            } else {
                ForEach(places, id: \.self) { item in
                    Button {
                        // This opens the location directly in Apple Maps
                        item.openInMaps(launchOptions: [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: item.placemark.coordinate)
                        ])
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: iconName)
                                .font(.caption)
                                .foregroundColor(iconColor)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Unknown Place")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                if let subTitle = item.placemark.title {
                                    Text(subTitle)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.primary.opacity(0.01)) // Makes the whole row tappable
                    }
                    .buttonStyle(.plain)
                    
                    if item != places.last {
                        Divider()
                            .padding(.leading, 44) // Aligns divider cleanly past the icon
                    }
                }
            }
        }
        .background(Color.black.opacity(0.03))
        .cornerRadius(12)
    }
}

struct TripInfoView: View {
    @Binding var trips: [Trip]
    @Binding var selectedTrip: UUID?
    @State private var tripToEdit: Trip? = nil

    @Environment(\.colorScheme) var colorScheme

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground).opacity(0.85)
    }

    var body: some View {
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
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(.rect(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 80, topTrailingRadius: 0))
                        .overlay(
                            Text("Your Trips")
                                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                .ignoresSafeArea()
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
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer().frame(height: 100)

                    if trips.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No trips planned yet")
                                .font(.headline)
                            Text("Start planning your adventure!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(cardBackground)
                        .cornerRadius(30)
                        .padding(.horizontal, 30)
                    } else {
                        ForEach($trips) { $trip in
                            TripCard(
                                trip: $trip,
                                selectedTrip: $selectedTrip,
                                onEdit: { tripToEdit = trip },
                                onDelete: {
                                    withAnimation {
                                        if selectedTrip == trip.id { selectedTrip = nil }
                                        trips.removeAll { $0.id == trip.id }
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .sheet(item: $tripToEdit) { trip in
            if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                CreateTripView(trips: $trips, selectedTrip: $selectedTrip, existingTrip: trips[index])
            }
        }
    }
}
