//
//  ResultsView.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//
import SwiftUI
import Combine

// The Results view now displays the current cadence and the time of the last API call above the table.
struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    // Sorted results by calculated "Value" in descending order.
    var sortedResults: [ResultItem] {
        viewModel.results.sorted {
            ($0.calculatedValue ?? 0) > ($1.calculatedValue ?? 0)
        }
    }
    
    // Date formatter for displaying the last API call time.
    static let dateFormatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateStyle = .medium
         formatter.timeStyle = .medium
         return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Use HStacks with a fixed-width label to align the colons.
            HStack {
                Text("Current Cadence:")
                    .frame(width: 150, alignment: .trailing)
                Text("\(viewModel.cadence) minutes")
            }
            HStack {
                Text("Last API call:")
                    .frame(width: 150, alignment: .trailing)
                if let lastCall = viewModel.lastAPICall {
                    Text("\(lastCall, formatter: Self.dateFormatter)")
                } else {
                    Text("Never")
                }
            }
            
            // The table displaying the sorted results.
            Table(sortedResults) {
                TableColumn("Model", value: \.id)
                TableColumn("Brand", value: \.vendor)
                TableColumn("3DMark") { item in
                    Text("\(item.benchmark)")
                }
                TableColumn("Value") { item in
                    if let calcValue = item.calculatedValue {
                        Text("\(calcValue)")
                    } else {
                        Text("")
                    }
                }
                TableColumn("Price") { _ in
                    Text("")  // Placeholder for Price column.
                }
            }
            .padding(.top)
        }
        .padding()
    }
}
