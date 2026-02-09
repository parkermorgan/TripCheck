//
//  ChecklistView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct ChecklistRow: View {
    @Binding var item: CheckListItem

    var body: some View {
        Button {
            item.isCompleted.toggle()
        } label: {
            HStack {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isCompleted ? .blue : .secondary)

                Text(item.title)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
        
}

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
                       let index = trips.firstIndex(where: { $0.id == id }) {
                        ChecklistView(items: $trips[index].checklist)
                    } else {
                        Text("Select a trip to see its checklist")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer() // Pushes the trip selector to the bottom

                // Trip selector button + dropdown
                if !trips.isEmpty {
                    VStack(spacing: 0) {
                        // Only the button has a background
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
        }
    }
}

struct ChecklistView: View {
    @Binding var items: [CheckListItem]
    @State private var newItemText = ""

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
                    TextField("New item", text: $newItemText)
                        .textFieldStyle(.plain)


                    Button("Add") {
                        addItem()
                    }
                    .font(.headline)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal, 30)
                
                
                List {
                    ForEach($items) { $item in
                        ChecklistRow(item: $item)
                            .listRowBackground(Color.clear)
                            
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal)
            }
        }
    }

    private func addItem() {
        guard !newItemText.isEmpty else { return }
        items.append(CheckListItem(title: newItemText, isCompleted: false))
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

#Preview {
    ChecklistView(items: .constant([CheckListItem(title: "Sample item", isCompleted: false)]))
}
