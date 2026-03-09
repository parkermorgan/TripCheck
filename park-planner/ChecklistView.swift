//
//  ChecklistView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
internal import _LocationEssentials


struct ChecklistRow: View {
    @Binding var item: CheckListItem
    let onToggle: () -> Void
    let onEdit: (String) -> Void
    @State private var isEditing = false
    @State private var editText = ""

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
            } else {
                Text(item.title)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    editText = item.title
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(30)
    }
}

struct TripChecklistTab: View {
    @Binding var trips: [Trip]
    @State private var selectedTripID: UUID?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative banners
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
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .allowsHitTesting(false)

            // Main content
            if let id = selectedTripID,
               let index = trips.firstIndex(where: { $0.id == id }),
               index < trips.count {
                ChecklistView(trips: $trips, tripIndex: index, selectedTripID: $selectedTripID)
                    .id(id)
            } else {
                VStack(spacing: 10) {
                    Spacer().frame(height: 100)

                    // Pill selector in empty state too
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
                                    .background(Capsule().fill(Color.white.opacity(0.85)))
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
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(30)
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
        }
        .onAppear {
            if let lastTrip = trips.last {
                selectedTripID = lastTrip.id
            }
        }
        .onChange(of: trips) { updatedTrips in
            if updatedTrips.isEmpty {
                selectedTripID = nil
            } else if let id = selectedTripID, !updatedTrips.contains(where: { $0.id == id }) {
                selectedTripID = updatedTrips.first?.id
            }
        }
    }
}


struct ChecklistView: View {
    @Binding var trips: [Trip]
    let tripIndex: Int
    @Binding var selectedTripID: UUID?

    @State private var newItemText = ""
    @State private var selectedCategory = "Travel Prep"

    let categories = ["Travel Prep", "Packing", "At the Park"]

    var visibleIndices: [Int] {
        trips[tripIndex].checklist.indices.filter { trips[tripIndex].checklist[$0].category == selectedCategory }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer().frame(height: 100)

                // Trip pill selector
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
                                    // Gradient base
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                    // Frosted glass on top
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                    // Extra tint + border when selected
                                    if selectedTripID == trip.id {
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
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

                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    HStack {
                        TextField("New item", text: $newItemText)
                            .textFieldStyle(.plain)
                        Button("Add") { addItem() }
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)

                    Button {
                        trips[tripIndex].checklist.sort { $0.title.lowercased() < $1.title.lowercased() }
                        saveTrips(trips)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 30)

                List {
                    ForEach(visibleIndices, id: \.self) { idx in
                        ChecklistRow(
                            item: $trips[tripIndex].checklist[idx],
                            onToggle: {
                                trips[tripIndex].checklist[idx].isCompleted.toggle()
                                saveTrips(trips)
                            },
                            onEdit: { newTitle in
                                trips[tripIndex].checklist[idx].title = newTitle
                                saveTrips(trips)
                            }
                        )
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 16)

                if !visibleIndices.isEmpty {
                    Button(role: .destructive) {
                        trips[tripIndex].checklist.removeAll { $0.category == selectedCategory }
                        saveTrips(trips)
                    } label: {
                        Text("Clear All")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func addItem() {
        guard !newItemText.isEmpty else { return }
        trips[tripIndex].checklist.append(CheckListItem(title: newItemText, isCompleted: false, category: selectedCategory))
        saveTrips(trips)
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        let toDelete = offsets.map { visibleIndices[$0] }
        trips[tripIndex].checklist.remove(atOffsets: IndexSet(toDelete))
        saveTrips(trips)
    }
}

#Preview {
    @State var trips = [Trip(
        name: "Sample Trip",
        locationName: "Yosemite",
        coordinate: .init(latitude: 37.8651, longitude: -119.5383),
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 5),
        checklist: [
            CheckListItem(title: "Book flights", isCompleted: false, category: "Travel Prep"),
            CheckListItem(title: "Pack clothes", isCompleted: false, category: "Packing"),
            CheckListItem(title: "Buy park pass", isCompleted: false, category: "At the Park")
        ]
    )]
    return ChecklistView(trips: $trips, tripIndex: 0, selectedTripID: .constant(trips[0].id))
}
