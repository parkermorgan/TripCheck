//
//  ChecklistView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
import UserNotifications
internal import _LocationEssentials

struct ChecklistRow: View {
    @Binding var item: CheckListItem
    let onToggle: () -> Void
    let onEdit: (String) -> Void
    let onNotificationToggle: () -> Void
    @State private var isEditing = false
    @State private var editText = ""
    
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var rowBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }

    var body: some View {
        HStack {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isCompleted ? .blue : .secondary)
            }

            if isEditing {
                TextField("Edit item", text: $editText, onCommit: {
                    if !editText.isEmpty {
                        onEdit(editText)
                    }
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
            } else {
                Text(item.title)
                    .foregroundColor(.primary)
                
                Spacer()

                Button {
                    item.notificationsEnabled.toggle()
                    onNotificationToggle()
                } label: {
                    Image(systemName: item.notificationsEnabled ? "bell.fill" : "bell.slash")
                        .foregroundColor(item.notificationsEnabled ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    editText = item.title
                    isEditing = true
                    // Trigger keyboard focus after a small delay to ensure the UI builds the TextField first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(rowBackground)
        .cornerRadius(30)
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 30))
    }
}

struct TripChecklistTab: View {
    @Binding var trips: [Trip]
    @State private var selectedTripID: UUID?
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
                            Text("My Checklist")
                                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

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
            
            if let id = selectedTripID,
               let index = trips.firstIndex(where: { $0.id == id }) {
                ChecklistView(trips: $trips, tripIndex: index, selectedTripID: $selectedTripID)
                    .id(id)
            } else {
                VStack(spacing: 10) {
                    Spacer().frame(height: 100)

                    if !trips.isEmpty {
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
                                        }
                                    )
                                    .onTapGesture { selectedTripID = trip.id }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 4)
                        }
                    }

                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(trips.isEmpty ? "No trips planned yet" : "Select a trip above")
                            .font(.headline)
                        Text(trips.isEmpty ? "Add a trip to manage your checklist" : "Tap a trip to view its checklist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(cardBackground)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
        }
        .onAppear {
            if selectedTripID == nil || !trips.contains(where: { $0.id == selectedTripID }) {
                selectedTripID = trips.last?.id
            }
        }
        .onChange(of: trips) { _, updatedTrips in
            if updatedTrips.isEmpty {
                selectedTripID = nil
            } else if let id = selectedTripID, !updatedTrips.contains(where: { $0.id == id }) {
                selectedTripID = updatedTrips.last?.id
            }
        }
    }
    
    // Moved inside the struct to fix scope and extraneous bracket errors
    private func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: "savedTrips") else { return }
        if let decodedTrips = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decodedTrips
        }
    }
}

struct ChecklistView: View {
    @Binding var trips: [Trip]
    let tripIndex: Int
    @Binding var selectedTripID: UUID?

    @State private var newItemText = ""
    @State private var selectedCategory = "Travel Prep"
    @State private var selectedDate: Date? = nil
    @Environment(\.colorScheme) var colorScheme

    let categories = ["Travel Prep", "Packing", "Daily Schedule"]

    var inputBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }

    var visibleItems: [CheckListItem] {
        guard tripIndex < trips.count else { return [] }
        return trips[tripIndex].checklist.filter { item in
            if selectedCategory == "Daily Schedule" {
                guard let selectedDate = selectedDate, let itemDate = item.date else { return false }
                return Calendar.current.isDate(itemDate, inSameDayAs: selectedDate)
            } else {
                return item.category == selectedCategory
            }
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    var body: some View {
        ZStack {
            if tripIndex < trips.count {
                VStack(spacing: 16) {
                    Spacer().frame(height: 100)

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
                                .onTapGesture {
                                    selectedTripID = trip.id
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 4)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .onChange(of: selectedCategory) { _, newValue in
                        if newValue == "Daily Schedule" && selectedDate == nil {
                            selectedDate = trips[tripIndex].tripDates.first
                        }
                    }
                    
                    if selectedCategory == "Daily Schedule" {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let dates = trips[tripIndex].tripDates
                                ForEach(0..<dates.count, id: \.self) { index in
                                    let date = dates[index]
                                    let isSelected = selectedDate.map { Calendar.current.isDate(date, inSameDayAs: $0) } ?? false
                                    
                                    VStack(spacing: 4) {
                                        Text("Day \(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(isSelected ? .white : .secondary)
                                        
                                        Text(dayFormatter.string(from: date))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(isSelected ? .white : .primary)
                                        
                                        Text(monthFormatter.string(from: date).uppercased())
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                    }
                                    .frame(width: 65, height: 75)
                                    .background(
                                        ZStack {
                                            if isSelected {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(LinearGradient(
                                                        colors: [Color.blue, Color.purple.opacity(0.8)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))
                                            } else {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(inputBackground)
                                                RoundedRectangle(cornerRadius: 16)
                                                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }

                    HStack(spacing: 12) {
                        HStack {
                            TextField("New item", text: $newItemText)
                                .textFieldStyle(.plain)
                            Button("Add") { addItem() }
                                .font(.headline)
                        }
                        .padding()
                        .background(inputBackground)
                        .cornerRadius(30)

                        Button {
                            trips[tripIndex].checklist.sort { $0.title.lowercased() < $1.title.lowercased() }
                            saveTrips(trips)
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.primary)
                                .padding()
                                .background(inputBackground)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 30)

                    List {
                        ForEach(visibleItems) { item in
                            if let idx = trips[tripIndex].checklist.firstIndex(where: { $0.id == item.id }) {
                                ChecklistRow(
                                    item: $trips[tripIndex].checklist[idx],
                                    onToggle: {
                                        trips[tripIndex].checklist[idx].isCompleted.toggle()
                                        saveTrips(trips)
                                    },
                                    onEdit: { newTitle in
                                        trips[tripIndex].checklist[idx].title = newTitle
                                        saveTrips(trips)
                                    },
                                    onNotificationToggle: {
                                        let updatedItem = trips[tripIndex].checklist[idx]
                                        if updatedItem.notificationsEnabled {
                                            scheduleNotification(for: updatedItem)
                                        } else {
                                            cancelNotification(for: updatedItem)
                                        }
                                        saveTrips(trips)
                                    }
                                )
                                .listRowBackground(Color.clear)
                            }
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 16)

                    if !visibleItems.isEmpty {
                        Button(role: .destructive) {
                            trips[tripIndex].checklist.removeAll { item in
                                if selectedCategory == "Daily Schedule" {
                                    guard let selectedDate = selectedDate, let itemDate = item.date else { return false }
                                    return Calendar.current.isDate(itemDate, inSameDayAs: selectedDate)
                                } else {
                                    return item.category == selectedCategory
                                }
                            }
                            saveTrips(trips)
                        } label: {
                            Text("Clear All")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 24)
                                .background(inputBackground)
                                .cornerRadius(20)
                        }
                        .padding(.bottom, 8)
                    }
                }
            } else {
                Color.clear
            }
        }
        .onAppear {
            if selectedCategory == "Daily Schedule" && selectedDate == nil {
                selectedDate = trips[tripIndex].tripDates.first
            }
        }
    }

    private func addItem() {
        guard tripIndex < trips.count, !newItemText.isEmpty else { return }
        let newItem = CheckListItem(
            title: newItemText,
            isCompleted: false,
            category: selectedCategory,
            notificationsEnabled: false,
            date: selectedCategory == "Daily Schedule" ? selectedDate : nil
        )
        trips[tripIndex].checklist.append(newItem)
        saveTrips(trips)
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        guard tripIndex < trips.count else { return }
        
        for offset in offsets {
            let itemToDelete = visibleItems[offset]
            cancelNotification(for: itemToDelete)
            
            if let actualIndex = trips[tripIndex].checklist.firstIndex(where: { $0.id == itemToDelete.id }) {
                trips[tripIndex].checklist.remove(at: actualIndex)
            }
        }
        
        saveTrips(trips)
    }

    private func scheduleNotification(for item: CheckListItem) {
        guard item.notificationsEnabled else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Checklist Reminder"
            content.sound = .default

            var trigger: UNNotificationTrigger
            
            if let itemDate = item.date, let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: itemDate) {
                
                content.body = "Tomorrow is scheduled: \(item.title)"
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
                
                var scheduledComponents = components
                scheduledComponents.hour = 9
                scheduledComponents.minute = 0
                
                trigger = UNCalendarNotificationTrigger(dateMatching: scheduledComponents, repeats: false)
            } else {
                content.body = "Don't forget: \(item.title)"
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            }

            let request = UNNotificationRequest(
                identifier: item.id.uuidString,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Notification successfully scheduled!")
                }
            }
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        guard tripIndex < trips.count else { return }
        
        let movingItemsIDs = source.map { visibleItems[$0].id }
        
        let masterIndices = movingItemsIDs.compactMap { id in
            trips[tripIndex].checklist.firstIndex(where: { $0.id == id })
        }
        
        let masterDestination: Int
        if destination < visibleItems.count {
            let destID = visibleItems[destination].id
            masterDestination = trips[tripIndex].checklist.firstIndex(where: { $0.id == destID }) ?? destination
        } else {
            if let lastVisibleID = visibleItems.last?.id,
               let lastMasterIdx = trips[tripIndex].checklist.firstIndex(where: { $0.id == lastVisibleID }) {
                masterDestination = lastMasterIdx + 1
            } else {
                masterDestination = trips[tripIndex].checklist.count
            }
        }
        
        trips[tripIndex].checklist.move(fromOffsets: IndexSet(masterIndices), toOffset: masterDestination)
        
        saveTrips(trips)
    }

    private func cancelNotification(for item: CheckListItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [item.id.uuidString]
        )
    }
    
    private func saveTrips(_ updatedTrips: [Trip]) {
        guard tripIndex < updatedTrips.count else { return }
        
        if let encoded = try? JSONEncoder().encode(updatedTrips) {
            UserDefaults.standard.set(encoded, forKey: "savedTrips")
        }
    }
}
