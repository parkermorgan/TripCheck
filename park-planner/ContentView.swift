import SwiftUI
import CoreLocation

struct ContentView: View {

    @Binding var trips: [Trip]
    @Binding var selectedTrip: UUID?
    @State private var showTrips = false
    @State private var showTripAlert = false
    @State private var tappedTrip: Trip?
    @State private var showResetSheet = false
    @State private var showResetConfirm = false
    @State private var resetTarget: ResetTarget = .both

    // Animation states
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: CGFloat = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: CGFloat = 0
    @State private var buttonsOffset: CGFloat = 40
    @State private var buttonsOpacity: CGFloat = 0
    @State private var heroOffset: CGFloat = 50
    @State private var heroOpacity: CGFloat = 0

    enum ResetTarget {
        case chat, trips, both
        var message: String {
            switch self {
            case .chat:  return "This will permanently delete your chat history."
            case .trips: return "This will permanently delete all your trips."
            case .both:  return "This will permanently delete all your trips and chat history."
            }
        }
    }

    func performReset() {
        switch resetTarget {
        case .chat:
            UserDefaults.standard.removeObject(forKey: "chatHistory")
        case .trips:
            trips = []
            selectedTrip = nil
            saveTrips([])
        case .both:
            trips = []
            selectedTrip = nil
            saveTrips([])
            UserDefaults.standard.removeObject(forKey: "chatHistory")
        }
    }

    var nextTrip: Trip? {
        if let selected = selectedTrip,
           let trip = trips.first(where: { $0.id == selected }) {
            return trip
        }
        return trips
            .filter { $0.startDate >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.startDate < $1.startDate }
            .first ?? trips.sorted { $0.startDate < $1.startDate }.last
    }

    var daysUntilNextTrip: Int {
        guard let trip = nextTrip else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
        return max(0, days)
    }

    var checklistProgress: Double {
        guard let trip = nextTrip, !trip.checklist.isEmpty else { return 0 }
        let completed = trip.checklist.filter { $0.isCompleted }.count
        return Double(completed) / Double(trip.checklist.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Bottom banner — non-interactive
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

                // Scroll content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 130)
                        if trips.isEmpty {
                            emptyStateView
                        } else {
                            tripsStateView
                        }
                        Text("Created by Parker Morgan")
                            .foregroundColor(.secondary)
                            .italic()
                            .font(.caption)
                            .padding(.bottom, 25)
                            .padding(.top, 8)
                    }
                }

                // Top banner + button — rendered last so it's on top
                VStack {
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: UIScreen.main.bounds.width * 0.75, height: 130)
                                .clipShape(.rect(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 80, topTrailingRadius: 0))
                                .overlay(
                                    Text("TripCheck")
                                        .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                                    alignment: .leading
                                )
                                .ignoresSafeArea(edges: .top)
                            Spacer()
                        }
                        Button {
                            showResetSheet = true
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(16)
                        }
                    }
                   
                    Spacer()
                }
            }
            .alert("Trip Selected", isPresented: $showTripAlert) {
                Button("OK") { selectedTrip = tappedTrip?.id; showTrips = false }
            } message: { Text("This trip has been selected.") }
            .alert("Are you sure?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { performReset() }
                Button("Cancel", role: .cancel) {}
            } message: { Text(resetTarget.message) }
            .confirmationDialog("Reset App Data", isPresented: $showResetSheet, titleVisibility: .visible) {
                Button("Clear Chat History", role: .destructive) { resetTarget = .chat; showResetConfirm = true }
                Button("Clear All Trips", role: .destructive) { resetTarget = .trips; showResetConfirm = true }
                Button("Clear Everything", role: .destructive) { resetTarget = .both; showResetConfirm = true }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 180, height: 180)

                Image("TripCheck-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }

            VStack(spacing: 8) {
                Text("Welcome to TripCheck ✈️")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Plan trips, track countdowns,\ncheck the weather, and pack smarter.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .offset(y: titleOffset)
            .opacity(titleOpacity)

            NavigationLink(destination: CreateTripView(trips: $trips, selectedTrip: $selectedTrip)) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Trip").font(.headline)
                }
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
            .offset(y: buttonsOffset)
            .opacity(buttonsOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    titleOffset = 0
                    titleOpacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                    buttonsOffset = 0
                    buttonsOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Trips State

    var tripsStateView: some View {
        VStack(spacing: 20) {

            if let trip = nextTrip {
                VStack(alignment: .leading, spacing: 16) {

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NEXT TRIP")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue.opacity(0.8))
                                .tracking(2)

                            Text(trip.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(trip.locationName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(spacing: 0) {
                            Text("\(daysUntilNextTrip)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .top, endPoint: .bottom
                                ))
                            Text(daysUntilNextTrip == 1 ? "day" : "days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !trip.checklist.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Checklist progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                let completed = trip.checklist.filter { $0.isCompleted }.count
                                Text("\(completed)/\(trip.checklist.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(checklistProgress == 1.0 ? .green : .blue)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(
                                            colors: checklistProgress == 1.0
                                                ? [Color.green.opacity(0.7), Color.green.opacity(0.5)]
                                                : [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * checklistProgress, height: 8)
                                        .animation(.spring(response: 0.8), value: checklistProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateStyle = .medium
                            return f
                        }()
                        Text("\(formatter.string(from: trip.startDate)) – \(formatter.string(from: trip.endDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground).opacity(0.85))
                .cornerRadius(30)
                .padding(.horizontal, 30)
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 4)
                .offset(y: heroOffset)
                .opacity(heroOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                        heroOffset = 0
                        heroOpacity = 1.0
                    }
                }
            }

            VStack(spacing: 12) {
                NavigationLink(destination: CreateTripView(trips: $trips, selectedTrip: $selectedTrip)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Trip").font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(30)
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showTrips.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showTrips ? "chevron.up.circle.fill" : "list.bullet.circle.fill")
                        Text(showTrips ? "Hide Trips" : "View All Trips").font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(
                        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(30)
                }
            }
            .padding(.horizontal, 30)
            .offset(y: buttonsOffset)
            .opacity(buttonsOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    buttonsOffset = 0
                    buttonsOpacity = 1.0
                }
            }

            if showTrips {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Trips")
                        .font(.headline)
                        .padding(.horizontal, 8)

                    ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                        Button {
                            tappedTrip = trip
                            showTripAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trip.name)
                                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                                    Text(trip.locationName)
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground).opacity(0.85))
                            .cornerRadius(30)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 30)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    ContentView(
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
            )
        ]),
        selectedTrip: .constant(nil)
    )
}
