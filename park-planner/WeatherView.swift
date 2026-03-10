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
    @State private var selectedTripID: UUID?
    @State private var selectedTab: String = "Current"
    @State private var temperatureText: String = "--"
    @State private var conditionText: String = ""
    @State private var weatherIconName: String = "questionmark.circle"
    @State private var dailyForecast: [(date: String, max: String, min: String, weatherCode: Int)] = []
    @State private var tripForecast: [(date: String, max: String, min: String, weatherCode: Int)] = []
    @State private var tripForecastUnavailable: Bool = false

    @Environment(\.colorScheme) var colorScheme

    let tabs = ["Current", "Trip Forecast"]

    var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white.opacity(0.85)
    }

    var evenRowBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color.white
    }

    var selectedTrip: Trip? {
        trips.first(where: { $0.id == selectedTripID })
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
                            Text("Weather")
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

                if trips.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "sun.max")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No trips planned yet")
                            .font(.headline)
                        Text("Add a trip to see its weather")
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trips) { trip in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trip.name)
                                        .font(.headline)
                                    Text(trip.locationName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(width: 180)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                        Capsule().fill(.ultraThinMaterial)
                                        if selectedTripID == trip.id {
                                            Capsule().fill(Color.white.opacity(0.1))
                                            Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                                        }
                                    }
                                )
                                .onTapGesture { selectedTripID = trip.id }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .onChange(of: selectedTripID) { _ in
                        guard let trip = selectedTrip else { return }
                        temperatureText = "--"
                        conditionText = ""
                        dailyForecast = []
                        tripForecast = []
                        tripForecastUnavailable = false
                        Task { await loadWeather(for: trip) }
                    }

                    Picker("View", selection: $selectedTab) {
                        ForEach(tabs, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 30)

                    if let trip = selectedTrip {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                if selectedTab == "Current" {
                                    VStack(spacing: 4) {
                                        Text(trip.locationName)
                                            .font(.title3).fontWeight(.semibold)
                                        Image(systemName: weatherIconName)
                                            .font(.system(size: 36))
                                            .foregroundColor(.primary)
                                        Text(temperatureText)
                                            .font(.system(size: 40, weight: .bold))
                                        Text(conditionText)
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(cardBackground)
                                    .cornerRadius(30)
                                    .padding(.horizontal, 30)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("7-Day Forecast")
                                            .font(.headline)
                                            .padding(.horizontal, 8)
                                        ForEach(Array(dailyForecast.enumerated()), id: \.element.date) { index, day in
                                            forecastRow(index: index, day: day)
                                        }
                                    }
                                    .padding(.horizontal, 30)

                                } else {
                                    if tripForecastUnavailable {
                                        VStack(spacing: 10) {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                            Text("Forecast not available yet")
                                                .font(.headline)
                                            Text("Check back closer to your trip date.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 32)
                                        .background(cardBackground)
                                        .cornerRadius(30)
                                        .padding(.horizontal, 30)
                                    } else if tripForecast.isEmpty {
                                        ProgressView().padding()
                                    } else {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Forecast for \(trip.name)")
                                                .font(.headline)
                                                .padding(.horizontal, 8)
                                            ForEach(Array(tripForecast.enumerated()), id: \.element.date) { index, day in
                                                forecastRow(index: index, day: day)
                                            }
                                        }
                                        .padding(.horizontal, 30)
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    } else {
                        Text("Tap a trip to view weather")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            selectedTripID = trips.first?.id
            if let trip = trips.first {
                Task { await loadWeather(for: trip) }
            }
        }
        .onChange(of: trips) { updatedTrips in
            if let updated = updatedTrips.first(where: { $0.id == selectedTripID }) {
                Task { await loadWeather(for: updated) }
            }
        }
    }

    @ViewBuilder
    func forecastRow(index: Int, day: (date: String, max: String, min: String, weatherCode: Int)) -> some View {
        HStack {
            Text(day.date)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Image(systemName: weatherCodeToIcon(day.weatherCode))
                .frame(width: 24)
            Text("H: \(day.max)")
                .font(.subheadline)
                .foregroundColor(.primary)
            Text("L: \(day.min)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if index % 2 != 0 {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    Capsule().fill(.ultraThinMaterial)
                } else {
                    Capsule().fill(evenRowBackground)
                }
            }
        )
        .cornerRadius(30)
    }

    private func loadWeather(for trip: Trip) async {
        let today = Calendar.current.startOfDay(for: Date())
        let tripStart = Calendar.current.startOfDay(for: trip.startDate)
        let tripEnd = Calendar.current.startOfDay(for: trip.endDate)
        let daysUntilTrip = Calendar.current.dateComponents([.day], from: today, to: tripStart).day ?? 0
        let tripDuration = max(1, (Calendar.current.dateComponents([.day], from: tripStart, to: tripEnd).day ?? 0) + 1)
        let totalDaysNeeded = daysUntilTrip + tripDuration
        let maxForecastDays = 16

        // Always request at least 7 days for current forecast
        // Only extend if the trip falls within the 16-day window
        let daysToRequest = daysUntilTrip >= maxForecastDays ? 7 : max(7, min(totalDaysNeeded, maxForecastDays))

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(trip.coordinate.latitude)&longitude=\(trip.coordinate.longitude)&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode&forecast_days=\(daysToRequest)&temperature_unit=fahrenheit&timezone=auto"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.temperatureText = "--"; self.conditionText = "Invalid URL" }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let current = json["current_weather"] as? [String: Any],
                   let temp = current["temperature"] as? Double,
                   let weatherCode = current["weathercode"] as? Int {
                    DispatchQueue.main.async {
                        self.temperatureText = "\(Int(temp))°"
                        self.conditionText = self.weatherCodeToDescription(weatherCode)
                        self.weatherIconName = self.weatherCodeToIcon(weatherCode)
                    }
                }

                if let daily = json["daily"] as? [String: Any],
                   let dates = daily["time"] as? [String],
                   let maxTemps = daily["temperature_2m_max"] as? [Double],
                   let minTemps = daily["temperature_2m_min"] as? [Double],
                   let weatherCodes = daily["weathercode"] as? [Int] {

                    var sevenDayData: [(String, String, String, Int)] = []
                    for i in 0..<min(7, dates.count) {
                        sevenDayData.append((formatDate(dates[i]), "\(Int(maxTemps[i]))°", "\(Int(minTemps[i]))°", weatherCodes[i]))
                    }

                    var tripData: [(String, String, String, Int)] = []
                    if daysUntilTrip >= maxForecastDays {
                        DispatchQueue.main.async { self.tripForecastUnavailable = true }
                    } else {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        for i in 0..<dates.count {
                            if let date = formatter.date(from: dates[i]) {
                                let day = Calendar.current.startOfDay(for: date)
                                if day >= tripStart && day <= tripEnd {
                                    tripData.append((formatDate(dates[i]), "\(Int(maxTemps[i]))°", "\(Int(minTemps[i]))°", weatherCodes[i]))
                                }
                            }
                        }
                        if tripData.isEmpty {
                            DispatchQueue.main.async { self.tripForecastUnavailable = true }
                        }
                    }

                    DispatchQueue.main.async {
                        self.dailyForecast = sevenDayData
                        if !tripData.isEmpty { self.tripForecast = tripData }
                    }
                }
            } else {
                DispatchQueue.main.async { self.temperatureText = "--"; self.conditionText = "No weather data" }
            }
        } catch {
            DispatchQueue.main.async { self.temperatureText = "--"; self.conditionText = "Unable to load weather" }
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
            formatter.dateFormat = "EEE, MMM d"
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
