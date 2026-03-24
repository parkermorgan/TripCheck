# Park Planner

An AI-integrated iOS travel management application that blends intuitive SwiftUI design with an autonomous agent. Unlike static planners, Park Planner features a Claude-powered assistant that uses function calling to interact directly with the app's state—creating trips, setting locations, and managing checklists via natural language.

---

## Demonstration

- **YouTube Demo:** https://youtu.be/9FmvkPrtvX8

---

## Architecture

The application implements a shared data architecture to ensure the main app and Home Screen widgets stay in sync via App Groups. It features an **Agentic AI layer** that bridges natural language intent with Swift execution.

Rather than just returning text, the AI assistant is equipped with a specific toolset that allows it to perform data mutations directly within the app's local storage.

---

## Agent Tools

The Claude-powered agent (via `AnthropicService`) has access to the following tools:

- **`create_trip`**  
  Generates a new trip object with a name, location, and date range, then persists it to shared storage.

- **`add_checklist_item`**  
  Finds a specific trip by name and appends new tasks (e.g., "Pack chargers") to the associated checklist.

- **`get_trips`**  
  Allows the agent to "read" the current list of upcoming travel to answer questions or provide context for new plans.

The agent decides which tools to call based on the user's request. It can intelligently map a location string from a chat message to a structured trip object without the user filling out a form.

---

## AI Integration Flow

1. **User Input**  
   User sends a request like:  
   _"Plan a 3-day trip to Zion starting next Friday."_

2. **Context Injection**  
   The app sends the current date and existing trip list to Claude to provide temporal and logical context.

3. **Tool Selection**  
   Claude identifies the intent and returns a JSON payload defining the `create_trip` tool call.

4. **Swift Execution**  
   The app parses the tool call using a custom `AnyCodable` implementation, initializes a `Trip` model, and saves it to `UserDefaults`.

5. **System Side-Effects**  
   The app automatically schedules local push notifications for the new trip and triggers a `WidgetCenter` reload.

---

## Tech Stack

| Layer                | Technology                          |
|---------------------|------------------------------------|
| Frontend Framework  | SwiftUI                            |
| LLM & Agent         | Anthropic Claude (via AnthropicService) |
| Location Services   | MapKit & CoreLocation              |
| Notifications       | UserNotifications Framework        |
| Persistence         | Shared UserDefaults (App Groups)   |
| Widget Extension    | WidgetKit                          |

---

## Project Structure

park-planner/
├── park_planner/
│ ├── Models.swift # Codable Trip and Checklist items
│ ├── AnthropicService.swift # API integration and Tool Logic
│ ├── Views/
│ │ ├── MainView.swift # Tab navigation and Sparkle overlay
│ │ ├── HelperView.swift # AI Chat Interface
│ │ ├── CreateTripView.swift # Manual entry & MapKit search
│ │ └── CountdownView.swift # Dynamic timer UI
│ └── park_plannerApp.swift # App entry & AppGroup configuration
├── ParkWidget/ # WidgetKit Extension
└── park-planner.xcodeproj


---


---

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Anthropic API Key

### Setup Steps

#### Configure API Key
1. Open `AnthropicService.swift`
2. Add your Anthropic API Key to the `apiKey` constant

#### Set App Group
1. In Project Settings, enable the **App Groups** capability
2. Ensure it matches the `appGroupID` defined in `park_plannerApp.swift`

#### Build and Run
1. Select an iOS Simulator or physical device
2. Press `Cmd + R`

---

## Design Decisions

### Tool-Calling over Text Generation

Using Claude as a controller rather than just a chatbot creates a "zero-UI" experience. By providing the agent with discrete tools to modify the `Trip` models, the app removes the need for complex multi-step forms.

### Shared App Groups for Widgets

To enable real-time updates on the iOS Home Screen, a shared `UserDefaults` suite is implemented. This allows the background Widget process to react immediately to changes made by the AI agent in the foreground app.

### Decoupled Service Layer

The `AnthropicService` is designed to be independent of the SwiftUI views. This separation allows the AI logic to be tested or swapped for different models (like GPT-4) without refactoring the UI components.
