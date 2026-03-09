import SwiftUI
import CoreLocation

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

            // Banners
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

            // Content
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

#Preview {
    TripInfoView(
        trips: .constant([
            Trip(
                name: "Hawaii Trip",
                locationName: "Honolulu",
                coordinate: .init(latitude: 21.3069, longitude: -157.8583),
                startDate: Date().addingTimeInterval(86400 * 10),
                endDate: Date().addingTimeInterval(86400 * 15),
                checklist: [
                    CheckListItem(title: "Book flights", isCompleted: true, category: "Travel Prep"),
                    CheckListItem(title: "Pack clothes", isCompleted: false, category: "Packing")
                ]
            ),
            Trip(
                name: "Seattle Visit",
                locationName: "Seattle",
                coordinate: .init(latitude: 47.6062, longitude: -122.3321),
                startDate: Date().addingTimeInterval(86400 * 30),
                endDate: Date().addingTimeInterval(86400 * 33),
                checklist: []
            )
        ]),
        selectedTrip: .constant(nil)
    )
}
