//
//  ChecklistView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI
internal import _LocationEssentials


// Displays a single row in the checklist list. Shows checkbox button, title text. and edit button.
struct ChecklistRow: View {
    let item: CheckListItem
    let index: Int
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
        .background(index % 2 == 0 ? Color.white : Color.blue.opacity(0.20))
        .cornerRadius(30)
    }
}

// Outer view that handles the trip selection.
// Shows ChecklistView for which trip is selection, renders dropdown button to allow for switching of trips.
struct TripChecklistTab: View {
    @Binding var trips: [Trip]
    @State private var selectedTripID: UUID?
    @State private var showTripList = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                ZStack {
                    if let id = selectedTripID,
                       let index = trips.firstIndex(where: { $0.id == id }),
                       index < trips.count {
                        ChecklistView(trips: $trips, tripIndex: index)
                            .id(id)
                    } else {
                        Text("Select a trip to see its checklist")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                if !trips.isEmpty {
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                showTripList.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedTripID.flatMap { id in trips.first(where: { $0.id == id })?.name } ?? "Select Trip")
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }

                        if showTripList {
                            VStack(spacing: 0) {
                                ForEach(trips) { trip in
                                    Button(action: {
                                        selectedTripID = trip.id
                                        showTripList = false
                                    }) {
                                        Text(trip.name)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white)
                                    }
                                }
                            }
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .shadow(radius: 3)
                        }
                    }
                    .padding(.bottom)
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
}

// States variables for checklist and displays tabs
struct ChecklistView: View {
    @Binding var trips: [Trip]
    let tripIndex: Int
 
    // Copy of the checklist that gets edited, gets saved back to binding.
    @State private var localItems: [CheckListItem] = []
    @State private var newItemText = ""
    @State private var selectedCategory = "Travel Prep"

    let categories = ["Travel Prep", "Packing", "At the Park"]

    var visibleIndices: [Int] {
        localItems.indices.filter { localItems[$0].category == selectedCategory }
    }

    func saveBack() {
        guard tripIndex < trips.count else { return }
        trips[tripIndex].checklist = localItems
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative banner shape, draws two gradient rectangles
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
                            Text("My Checklist")
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

                // Bottom mirrored shape
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

            // Main content
            VStack(spacing: 12) {
                Spacer().frame(height: 100)

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

                        Button("Add") {
                            addItem()
                        }
                        .font(.headline)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)

                    Button {
                        localItems.sort { $0.title.lowercased() < $1.title.lowercased() }
                        saveBack()
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
                    ForEach(Array(visibleIndices.enumerated()), id: \.element) { position, idx in
                        ChecklistRow(
                            item: localItems[idx],
                            index: position,
                            onToggle: {
                                localItems[idx].isCompleted.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    saveBack()
                                }
                            },
                            onEdit: { newTitle in
                                localItems[idx].title = newTitle
                                saveBack()
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
                        localItems.removeAll { $0.category == selectedCategory }
                        saveBack()
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
        .onAppear {
            guard tripIndex < trips.count else { return }
            localItems = trips[tripIndex].checklist
        }
    }

    // Appends new CheckListItem to localItems.
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        localItems.append(CheckListItem(title: newItemText, isCompleted: false, category: selectedCategory))
        saveBack()
        newItemText = ""
    }

    // Handles swipe-to-delete.
    private func deleteItems(at offsets: IndexSet) {
        let toDelete = offsets.map { visibleIndices[$0] }
        localItems.remove(atOffsets: IndexSet(toDelete))
        saveBack()
    }
}

// Sample data for preview.
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
    return ChecklistView(trips: $trips, tripIndex: 0)
}
