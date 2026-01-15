//
//  CountdownView.swift
//  park-planner
//
//  Created by Parker Morgan on 1/14/26.
//

import SwiftUI

struct CountdownView: View {
    
    @State private var selectedDate = Date()
    
    var body: some View {
        DatePicker("Start Date", selection: $selectedDate, displayedComponents: [.date])
            .padding()
        
    }
}

#Preview {
    CountdownView()
}
