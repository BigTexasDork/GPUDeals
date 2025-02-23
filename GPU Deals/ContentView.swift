//
//  ResultItem.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//
import SwiftUI
import Combine

// The main view uses a NavigationView with a sidebar style.
struct ContentView: View {
    @ObservedObject var viewModel = AppViewModel()
    @State private var selection: String? = "Results" // Default selection
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink("Results", value: "Results")
                NavigationLink("Config", value: "Config")
            }
            .navigationTitle("Tabs")
        } detail: {
            // Display the appropriate detail view based on the selection.
            if selection == "Results" {
                ResultsView(viewModel: viewModel)
            } else if selection == "Config" {
                ConfigView(viewModel: viewModel)
            } else {
                Text("Select a tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
