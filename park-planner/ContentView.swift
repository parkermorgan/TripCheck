//
//  ContentView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var trips: [Trip] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Welcome to Park Planner!")
                    .font(.largeTitle)

                NavigationLink {
                    CreateTripView(trips: $trips)
                } label: {
                    Text("Add Trip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
    }
}



#Preview {

    ContentView()
}
