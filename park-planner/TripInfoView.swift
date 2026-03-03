import SwiftUI

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Your Trip:")
                    .font(.headline)

                if trips.isEmpty {
                    Text("You have no trips planned yet. Start planning your adventure!")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                } else {
                    ForEach(Array(trips.indices), id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trips[index].name)
                                .font(.headline)

                            Text(trips[index].locationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("Start: \(trips[index].startDate, formatter: dateFormatter)")
                                Spacer()
                                Text("End: \(trips[index].endDate, formatter: dateFormatter)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            HStack {
                                Button("Edit Trip") {
                                    tripToEdit = trips[index]
                                }
                                .foregroundColor(.blue)

                                Spacer()

                                Button("Delete Trip") {
                                    let tripToDelete = trips[index]
                                    if selectedTrip == tripToDelete.id {
                                        selectedTrip = nil
                                    }
                                    trips.remove(at: index)
                                }
                                .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
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
        trips: .constant([]),
        selectedTrip: .constant(nil)
    )
}
