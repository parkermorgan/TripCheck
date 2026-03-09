import Foundation

// MARK: - Message types

struct Message: Codable {
    let role: String
    let content: MessageContent
}

enum MessageContent: Codable {
    case text(String)
    case blocks([ContentBlock])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let str):
            var container = encoder.singleValueContainer()
            try container.encode(str)
        case .blocks(let blocks):
            var container = encoder.singleValueContainer()
            try container.encode(blocks)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .text(str)
        } else {
            let blocks = try container.decode([ContentBlock].self)
            self = .blocks(blocks)
        }
    }
}

// MARK: - Content blocks

struct ContentBlock: Codable {
    let type: String
    // text block
    var text: String?
    // tool_use block
    var id: String?
    var name: String?
    var input: AnyCodable?
    // tool_result block
    var tool_use_id: String?
    var content: String?
}

// Lets us encode/decode arbitrary JSON (tool inputs)
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: String].self) {
            value = dict
        } else if let str = try? container.decode(String.self) {
            value = str
        } else {
            value = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let dict = value as? [String: String] {
            try container.encode(dict)
        } else if let str = value as? String {
            try container.encode(str)
        }
    }
}

// MARK: - Tool definitions

struct ToolInputSchema: Codable {
    let type: String
    let properties: [String: ToolProperty]
    let required: [String]
}

struct ToolProperty: Codable {
    let type: String
    let description: String
    var enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}

struct ToolDefinition: Codable {
    let name: String
    let description: String
    let input_schema: ToolInputSchema
}

// MARK: - Request / Response

struct RequestBody: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let tools: [ToolDefinition]
    let messages: [Message]
}

struct APIResponse: Decodable {
    let content: [ContentBlock]
    let stop_reason: String?
}

// MARK: - Tool result

enum ToolCallResult {
    case addChecklistItem(tripName: String, itemTitle: String, category: String)
    case getTrips
    case createTrip(tripName: String, location: String, startDate: Date, endDate: Date, useDefaultChecklist: Bool)
    case unknown
}

// MARK: - AnthropicService

struct AnthropicService {
    let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ANTHROPIC_API_KEY"] as? String else {
            return ""
        }
        return key
    }()
    let url = URL(string: "https://api.anthropic.com/v1/messages")!

    let tools: [ToolDefinition] = [
        ToolDefinition(
            name: "create_trip",
            description: "Add a new trip with a name, location, and date. IMPORTANT: Before calling this tool, you MUST ask the user if they want the default checklist items added to the trip. Wait for their response before proceeding.",
            input_schema: ToolInputSchema(
                type: "object",
                properties: [
                    "trip_name": ToolProperty(
                        type: "string",
                        description: "The name of the trip"
                    ),
                    "location": ToolProperty(
                        type: "string",
                        description: "The location of the trip"
                    ),
                    "start_date": ToolProperty(
                        type: "string",
                        description: "The start date of the trip in YYYY-MM-DD format"
                    ),
                    "end_date": ToolProperty(
                        type: "string",
                        description: "The end date of the trip in YYYY-MM-DD format"
                    ),
                    "use_default_checklist": ToolProperty(
                        type: "string",
                        description: "Whether to add the default checklist items to the trip. Ask the user if they want this before creating. Use 'yes' or 'no'.",
                        enumValues: ["yes", "no"]
                    )
                ],
                required: ["trip_name", "location", "start_date", "end_date", "use_default_checklist"]
            )
        ),
        ToolDefinition(
            name: "get_trips",
            description: "Get all the user's current trips including their names, locations, dates, and checklist items.",
            input_schema: ToolInputSchema(
                type: "object",
                properties: [:],
                required: []
            )
        ),
        ToolDefinition(
            name: "add_checklist_item",
            description: "Add a new item to a trip's checklist.",
            input_schema: ToolInputSchema(
                type: "object",
                properties: [
                    "trip_name": ToolProperty(
                        type: "string",
                        description: "The name of the trip to add the item to"
                    ),
                    "item_title": ToolProperty(
                        type: "string",
                        description: "The checklist item to add"
                    ),
                    "category": ToolProperty(
                        type: "string",
                        description: "The category for the item",
                        enumValues: ["Travel Prep", "Packing", "At the Park"]
                    )
                ],
                required: ["trip_name", "item_title", "category"]
            )
        )
    ]

    // Main entry point — handles tool use loop automatically
    func sendMessage(messages: [Message], trips: [Trip], onToolCall: @escaping (ToolCallResult) -> String) async throws -> String {

        var conversationMessages = messages

        // Loop to handle tool use (Claude may call multiple tools)
        for _ in 0..<5 {
            let response = try await callAPI(messages: conversationMessages)

            // Check if Claude wants to use a tool
            if response.stop_reason == "tool_use" {
                var toolResults: [ContentBlock] = []

                for block in response.content {
                    if block.type == "tool_use", let toolName = block.name, let toolID = block.id {
                        let input = block.input?.value as? [String: String] ?? [:]
                        let toolCall = parseToolCall(name: toolName, input: input)
                        let result = onToolCall(toolCall)
                        toolResults.append(ContentBlock(
                            type: "tool_result",
                            text: nil,
                            id: nil,
                            name: nil,
                            input: nil,
                            tool_use_id: toolID,
                            content: result
                        ))
                    }
                }

                // Append Claude's tool_use response and our tool_result to conversation
                conversationMessages.append(Message(role: "assistant", content: .blocks(response.content)))
                conversationMessages.append(Message(role: "user", content: .blocks(toolResults)))

            } else {
                // No tool use — return the text response
                let text = response.content.first(where: { $0.type == "text" })?.text ?? ""
                return text
            }
        }

        return "Something went wrong processing your request."
    }

    private func callAPI(messages: [Message]) async throws -> APIResponse {
        let body = RequestBody(
            model: "claude-sonnet-4-20250514",
            max_tokens: 1024,
            system: "You are a helpful assistant for TripCheck, a trip planning app. Help users plan trips, manage their checklists, and answer questions about the app. Be friendly and concise. When users ask to add items or get trip info, use the available tools. Today's date is \(formattedToday()). Always use the current year when interpreting dates unless the user specifies otherwise.",
            tools: tools,
            messages: messages
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8) ?? "no data")
        return try JSONDecoder().decode(APIResponse.self, from: data)
    }
    
    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func parseToolCall(name: String, input: [String: String]) -> ToolCallResult {
        switch name {
        case "get_trips":
            return .getTrips
        case "add_checklist_item":
            guard let tripName = input["trip_name"],
                  let itemTitle = input["item_title"],
                  let category = input["category"] else {
                return .unknown
            }
            return .addChecklistItem(tripName: tripName, itemTitle: itemTitle, category: category)
        case "create_trip":
            guard let tripName = input["trip_name"],
                  let location = input["location"],
                  let startDateString = input["start_date"],
                  let endDateString = input["end_date"] else {
                return .unknown
            }
            let useDefaultChecklist = input["use_default_checklist"] == "yes"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let startDate = formatter.date(from: startDateString),
                  let endDate = formatter.date(from: endDateString) else {
                return .unknown
            }
            return .createTrip(tripName: tripName, location: location, startDate: startDate, endDate: endDate, useDefaultChecklist: useDefaultChecklist)
        default:
            return .unknown
        }
    }
}
