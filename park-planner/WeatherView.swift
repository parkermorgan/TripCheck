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
    @State private var weatherIconName: String = "questionmark.circle"
    @State private var dailyForecast: [(date: String, max: String, min: String, weatherCode: Int)] = []

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
                                temperatureText = "--"
                                conditionText = ""
                                dailyForecast = []
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

                            Image(systemName: weatherIconName)
                                .font(.system(size: 40))
                                .foregroundColor(.primary)

                            Text(temperatureText)
                                .font(.system(size: 48, weight: .bold))

                            Text(conditionText)
                                .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("7-Day Forecast")
                                    .font(.headline)

                                ForEach(dailyForecast, id: \.date) { day in
                                    HStack {
                                        Text(day.date)
                                            .font(.caption)

                                        Spacer()

                                        Image(systemName: weatherCodeToIcon(day.weatherCode))
                                            .font(.caption)

                                        Text("H: \(day.max)  L: \(day.min)")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.top, 8)
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
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(trip.coordinate.latitude)&longitude=\(trip.coordinate.longitude)&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode&forecast_days=7&temperature_unit=fahrenheit&timezone=auto"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.temperatureText = "--"
                self.conditionText = "Invalid URL"
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
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
                    self.weatherIconName = weatherCodeToIcon(weatherCode)
                }
                
                if let daily = json["daily"] as? [String: Any],
                   let dates = daily["time"] as? [String],
                   let maxTemps = daily["temperature_2m_max"] as? [Double],
                   let minTemps = daily["temperature_2m_min"] as? [Double],
                   let weatherCodes = daily["weathercode"] as? [Int] {

                    var forecastData: [(String, String, String, Int)] = []

                    for i in 0..<min(7, dates.count) {
                        let max = "\(Int(maxTemps[i]))°"
                        let min = "\(Int(minTemps[i]))°"
                        let code = weatherCodes[i]
                        let formattedDate = formatDate(dates[i])
                        forecastData.append((formattedDate, max, min, code))
                    }

                    DispatchQueue.main.async {
                        self.dailyForecast = forecastData
                    }
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

    private func weatherCodeToIcon(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1, 2, 3: return "cloud.sun"
        case 45, 48: return "cloud.fog"
        case 51, 53, 55: return "cloud.drizzle"
        case 61, 63, 65: return "cloud.rain"
        case 66, 67: return "cloud.sleet"
        case 71, 73, 75: return "cloud.snow"
        case 80, 81, 82: return "cloud.heavyrain"
        case 95: return "cloud.bolt.rain"
        default: return "questionmark.circle"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }

        return dateString
    }
}

#Preview {
    WeatherView(
        trips: .constant([
            Trip(
                name: "Hawaii Trip",
                locationName: "Honolulu",
                coordinate: CLLocationCoordinate2D(latitude: 21.3069, longitude: -157.8583),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 5),
                checklist: []
            ),
            Trip(
                name: "Seattle Visit",
                locationName: "Seattle",
                coordinate: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3),
                checklist: []
            )
        ])
    )
}
