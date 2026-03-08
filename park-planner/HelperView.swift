import SwiftUI
import CoreLocation

enum Sender: Codable {
    case user
    case bot
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id = UUID()
    let text: String
    let sender: Sender
}

struct HelperView: View {
    @Binding var trips: [Trip]
    @State private var chatMessages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false

    func sendMessage() async {
        let userMessage = newMessage
        newMessage = ""
        chatMessages.append(.init(text: userMessage, sender: .user))

        // Build message history for API (only text messages)
        let messages = chatMessages.dropLast().map { message in
            Message(
                role: message.sender == .user ? "user" : "assistant",
                content: .text(message.text)
            )
        } + [Message(role: "user", content: .text(userMessage))]

        isLoading = true
        do {
            let response = try await AnthropicService().sendMessage(
                messages: Array(messages),
                trips: trips
            ) { toolCall in
                // Handle tool calls on main thread
                return handleToolCall(toolCall)
            }
            chatMessages.append(.init(text: response, sender: .bot))
        } catch {
            print("Error: \(error)")
            chatMessages.append(.init(text: "Something went wrong.", sender: .bot))
        }
        isLoading = false
    }

    // Executes tool calls and returns a result string for Claude
    func handleToolCall(_ toolCall: ToolCallResult) -> String {
        switch toolCall {

        case .getTrips:
            if trips.isEmpty {
                return "The user has no trips planned yet."
            }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let tripSummaries = trips.map { trip in
                let items = trip.checklist.map { "- \($0.title) [\($0.category)] \($0.isCompleted ? "(done)" : "")" }.joined(separator: "\n")
                return """
                Trip: \(trip.name)
                Location: \(trip.locationName)
                Dates: \(formatter.string(from: trip.startDate)) – \(formatter.string(from: trip.endDate))
                Checklist:
                \(items.isEmpty ? "No items" : items)
                """
            }.joined(separator: "\n\n")
            return tripSummaries

        case .addChecklistItem(let tripName, let itemTitle, let category):
            if let index = trips.firstIndex(where: { $0.name.lowercased() == tripName.lowercased() }) {
                let newItem = CheckListItem(title: itemTitle, isCompleted: false, category: category)
                DispatchQueue.main.async {
                    trips[index].checklist.append(newItem)
                    saveTrips(trips)
                }
                return "Successfully added '\(itemTitle)' to the \(category) checklist for \(trips[index].name)."
            } else {
                // Try fuzzy match
                if let index = trips.firstIndex(where: { $0.name.lowercased().contains(tripName.lowercased()) }) {
                    let newItem = CheckListItem(title: itemTitle, isCompleted: false, category: category)
                    DispatchQueue.main.async {
                        trips[index].checklist.append(newItem)
                        saveTrips(trips)
                    }
                    return "Successfully added '\(itemTitle)' to the \(category) checklist for \(trips[index].name)."
                }
                return "Could not find a trip named '\(tripName)'. Available trips: \(trips.map { $0.name }.joined(separator: ", "))"
            }
        
        case .createTrip(let tripName, let location, let startDate, let endDate):
            let newTrip = Trip(
                name: tripName,
                locationName: location,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                startDate: startDate,
                endDate: endDate,
                checklist: []
            )
            DispatchQueue.main.async {
                trips.append(newTrip)
                saveTrips(trips)
            }
            return "Successfully created trip '\(tripName)' with location '\(location)', starting on \(startDate) and ending on \(endDate)."
        case .unknown:
            return "Unknown tool call."
        }
    }

    func saveMessages() {
        if let encoded = try? JSONEncoder().encode(chatMessages) {
            UserDefaults.standard.set(encoded, forKey: "chatHistory")
        }
    }

    func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: "chatHistory"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            chatMessages = decoded
        } else {
            chatMessages = [
                .init(text: "Hey there! ✈️ I'm your TripCheck Assistant. Ask me anything about planning your trip or using the app!", sender: .bot)
            ]
            saveMessages()
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: 80)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 60,
                                topTrailingRadius: 0
                            )
                        )
                        .overlay(
                            HStack {
                                Image(systemName: "sparkles")
                                Text("TripCheck Assistant")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.leading, 20),
                            alignment: .leading
                        )
                    Spacer()
                    Button {
                        chatMessages = []
                        UserDefaults.standard.removeObject(forKey: "chatHistory")
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.bottom, 12)

                // Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatMessages) { message in
                            HStack {
                                if message.sender == .user { Spacer() }
                                Text(message.text)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        message.sender == .user
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        : AnyShapeStyle(Color(.systemBackground).opacity(0.85))
                                    )
                                    .foregroundColor(message.sender == .user ? .white : .primary)
                                    .cornerRadius(20)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.sender == .user ? .trailing : .leading)
                                if message.sender == .bot { Spacer() }
                            }
                            .padding(.horizontal, 16)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemBackground).opacity(0.85))
                                    .cornerRadius(20)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask me anything...", text: $newMessage)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground).opacity(0.85))
                        .cornerRadius(25)

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(newMessage.isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.15))
            }
            .onAppear { loadMessages() }
            .onChange(of: chatMessages) { saveMessages() }
        }
    }
}

#Preview {
    HelperView(trips: .constant([]))
}
