//
//  ChecklistView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct ChecklistRow: View {
    let item: CheckListItem
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
        }
    }
}

struct ChecklistView: View {
    @Binding var items: [CheckListItem]
    @State private var localItems: [CheckListItem] = []
    @State private var newItemText = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative banner shape
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
                        items = localItems
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
                    ForEach(localItems.indices, id: \.self) { index in
                        ChecklistRow(
                            item: localItems[index],
                            onToggle: {
                                localItems[index].isCompleted.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    items = localItems
                                }
                            },
                            onEdit: { newTitle in
                                localItems[index].title = newTitle
                                items = localItems
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
            }
        }
        .onAppear {
            localItems = items
        }
    }

    private func addItem() {
        guard !newItemText.isEmpty else { return }
        localItems.append(CheckListItem(title: newItemText, isCompleted: false))
        items = localItems
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        localItems.remove(atOffsets: offsets)
        items = localItems
    }
}

#Preview {
    ChecklistView(items: .constant([CheckListItem(title: "Sample item", isCompleted: false)]))
}
