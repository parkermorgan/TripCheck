import SwiftUI
import CoreLocation
import Combine

struct CountdownView: View {
    let trip: Trip

    @State private var now: Date = Date()
    @Environment(\.colorScheme) var colorScheme
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var secondsRemaining: Int {
        max(0, Int(trip.startDate.timeIntervalSince(now)))
    }

    private var days: Int    { secondsRemaining / 86400 }
    private var hours: Int   { (secondsRemaining % 86400) / 3600 }
    private var minutes: Int { (secondsRemaining % 3600) / 60 }
    private var seconds: Int { secondsRemaining % 60 }

    private var tripHasStarted: Bool { now >= trip.startDate }
    private var isToday: Bool {
        Calendar.current.isDate(trip.startDate, inSameDayAs: now)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white.opacity(0.85)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Top banner — own layer
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
                            Text("Countdown")
                                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Bottom banner — own layer, matching ContentView pattern
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
            VStack(spacing: 24) {
                Spacer().frame(height: 100)

                VStack(spacing: 6) {
                    Text("Countdown to your trip")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(trip.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if tripHasStarted && !isToday {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Trip already started")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(cardBackground)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)

                } else if isToday && tripHasStarted {
                    VStack(spacing: 10) {
                        Text("✈️")
                            .font(.system(size: 48))

                        Text("Trip starts today!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(cardBackground)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)

                } else {
                    HStack(spacing: 12) {
                        CountdownUnit(value: days,    label: "Days")
                        CountdownUnit(value: hours,   label: "Hours")
                        CountdownUnit(value: minutes, label: "Min")
                        CountdownUnit(value: seconds, label: "Sec")
                    }
                    .padding(.horizontal, 30)

                    Text("until \(trip.locationName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .onReceive(timer) { tick in
            now = tick
        }
    }
}

private struct CountdownUnit: View {
    let value: Int
    let label: String

    @Environment(\.colorScheme) var colorScheme

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white.opacity(0.85)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d", value))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(cardBackground)
        .cornerRadius(30)
    }
}

#Preview {
    CountdownView(
        trip: Trip(
            name: "Sample Trip",
            locationName: "Yosemite National Park",
            coordinate: CLLocationCoordinate2D(latitude: 37.8651, longitude: -119.5383),
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 7),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 10),
            checklist: []
        )
    )
}
