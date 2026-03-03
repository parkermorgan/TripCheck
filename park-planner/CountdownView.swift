import SwiftUI
import CoreLocation
import Combine

// Keep your existing daysUntil helper or replace with the new one below

struct CountdownView: View {
    let trip: Trip
    
    // Fires every second to keep the countdown live
    @State private var now: Date = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Total seconds remaining until trip start
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Countdown to your trip")
                    .font(.headline)

                if tripHasStarted && !isToday {
                    Text("Trip already started")
                        .foregroundColor(.secondary)
                } else if isToday && tripHasStarted {
                    Text("Trip starts today! ✈️")
                        .font(.largeTitle)
                } else {
                    // Live countdown tiles
                    HStack(spacing: 20) {
                        CountdownUnit(value: days,    label: "Days")
                        CountdownUnit(value: hours,   label: "Hours")
                        CountdownUnit(value: minutes, label: "Min")
                        CountdownUnit(value: seconds, label: "Sec")
                    }
                    .font(.system(.largeTitle, design: .monospaced))
                    .bold()

                    Text("until \(trip.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        // Update `now` every second from the timer
        .onReceive(timer) { tick in
            now = tick
        }
    }
}

// Small reusable tile for each time unit
private struct CountdownUnit: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
