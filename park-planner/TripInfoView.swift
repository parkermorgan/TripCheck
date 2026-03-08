import SwiftUI
import CoreLocation

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct TripInfoView: View {
    @Binding var trips: [Trip]
    @Binding var selectedTrip: UUID?
    @State private var tripToEdit: Trip? = nil

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
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 80,
                                topTrailingRadius: 0
                            )
                        )
                        .overlay(
                            Text("Your Trips")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                .ignoresSafeArea()

                Spacer()

                HStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 80,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )
                }
                .ignoresSafeArea()
            }

            VStack(spacing: 12) {
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
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(30)
                    .padding(.horizontal, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(trips.indices), id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(trips[index].name)
                                        .font(.headline)

                                    Text(trips[index].locationName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Label(dateFormatter.string(from: trips[index].startDate), systemImage: "calendar")
                                        Spacer()
                                        Label(dateFormatter.string(from: trips[index].endDate), systemImage: "calendar")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                    Divider()

                                    HStack {
                                        Button {
                                            tripToEdit = trips[index]
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }

                                        Spacer()

                                        Button {
                                            let tripToDelete = trips[index]
                                            if selectedTrip == tripToDelete.id {
                                                selectedTrip = nil
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                if index < trips.count {
                                                    trips.remove(at: index)
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                                .font(.subheadline)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(30)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    }
                }

                Spacer()
            }
        }
        .sheet(item: $tripToEdit) { trip in
            if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                CreateTripView(trips: $trips, selectedTrip: $selectedTrip, existingTrip: trips[index])
            }
        }
    }
}

// Sample data for preview.
#Preview {
    TripInfoView(
        trips: .constant([
            Trip(
                name: "Hawaii Trip",
                locationName: "Honolulu",
                coordinate: .init(latitude: 21.3069, longitude: -157.8583),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 5),
                checklist: []
            ),
            Trip(
                name: "Seattle Visit",
                locationName: "Seattle",
                coordinate: .init(latitude: 47.6062, longitude: -122.3321),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3),
                checklist: []
            )
        ]),
        selectedTrip: .constant(nil)
    )
}
