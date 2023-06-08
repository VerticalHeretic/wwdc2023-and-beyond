//
//  ContentView.swift
//  wwdc2023-and-beyond
//
//  Created by Łukasz Stachnik on 08/06/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            NavigationLink("Workout Kit 🏋🏻") {
                WorkoutKitView()
            }
        }
    }
}

#Preview {
    ContentView()
}
