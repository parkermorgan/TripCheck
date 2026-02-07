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
        }
        .buttonStyle(.plain)
    }
}

struct TripChecklistTab: View {
    @Binding var trips: [Trip]
    @State private var selectedTripID: UUID?

    var body: some View {
        VStack {
            Picker("Select Trip", selection: $selectedTripID) {
                ForEach(trips) { trip in
                    Text(trip.name).tag(trip.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .padding()

            if let id = selectedTripID,
               let index = trips.firstIndex(where: { $0.id == id }) {
                ChecklistView(items: $trips[index].checklist)
            } else {
                Text("Select a trip to see its checklist")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear {
            if let lastTrip = trips.last {
                selectedTripID = lastTrip.id
            }
        }
    }
}

struct ChecklistView: View {
    @Binding var items: [CheckListItem]
    @State private var newItemText = ""

    var body: some View {
        VStack {
            HStack {
                TextField("New item", text: $newItemText)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    addItem()
                }
            }
            .padding()

            List {
                ForEach($items) { $item in
                    ChecklistRow(item: $item)
                }
                .onDelete(perform: deleteItems)
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
