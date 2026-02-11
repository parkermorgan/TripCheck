//
//  WeatherView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
import CoreLocation

struct WeatherView: View {
    @Binding var trips: [Trip]
    @State private var selectedTrip: Trip?
    @State private var temperatureText: String = "--"
    @State private var conditionText: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                if trips.isEmpty {
                    Text("Select a trip to see its weather")
                        .foregroundColor(.secondary)
                        .italic()
                } else {

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trips) { trip in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(trip.name)
                                        .font(.headline)

                                    Text(trip.locationName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(width: 180)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTrip?.id == trip.id
                                              ? Color.blue.opacity(0.35)
                                              : Color.white.opacity(0.25))
                                )
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                            }
                        }
                        
                        }
                            .padding(.horizontal)
                            .onChange(of: selectedTrip) { newTrip in
                                guard let trip = newTrip else { return }
                                // Reset displayed weather
                                temperatureText = "--"
                                conditionText = ""
                                // Fetch new weather
                                Task {
                                    await loadWeather(for: trip)
                                }
                    }

                    Divider()

                    if let trip = selectedTrip {
                        VStack(spacing: 12) {
                            Text(trip.locationName)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(temperatureText)
                                .font(.system(size: 48, weight: .bold))

                            Text(conditionText)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 12)
                    } else {
                        Text("Tap a trip to view weather")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            selectedTrip = trips.first
        }
    }

    private func loadWeather(for trip: Trip) async {
        // Build URL with explicit temperature unit and timezone
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(trip.coordinate.latitude)&longitude=\(trip.coordinate.longitude)&current_weather=true&temperature_unit=fahrenheit&timezone=auto"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.temperatureText = "--"
                self.conditionText = "Invalid URL"
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Log raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Open-Meteo raw JSON for \(trip.name):", jsonString)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current_weather"] as? [String: Any],
               let temp = current["temperature"] as? Double,
               let weatherCode = current["weathercode"] as? Int {

                let condition = weatherCodeToDescription(weatherCode)

                DispatchQueue.main.async {
                    self.temperatureText = "\(Int(temp))°"
                    self.conditionText = condition
                }
            } else {
                DispatchQueue.main.async {
                    self.temperatureText = "--"
                    self.conditionText = "No weather data"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.temperatureText = "--"
                self.conditionText = "Unable to load weather"
            }
            print("Open-Meteo error for \(trip.name):", error)
        }
    }

    // Helper to convert Open-Meteo weather code to description
    private func weatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Mainly clear / partly cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 80, 81, 82: return "Rain showers"
        case 95: return "Thunderstorm"
        default: return "Unknown"
        }
    }
}
