//
//  ConfigView.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//
import SwiftUI
import Combine

struct ConfigView: View {
    @ObservedObject var viewModel: AppViewModel
    
    // Adjust this if needed so that the longest key fits on one line
    private let configKeyWidth: CGFloat = 160
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Title at the top
            Text("Configuration")
                .font(.title)
                .padding(.top)
            
            // Use a simple VStack to lay out each config row
            VStack(alignment: .leading, spacing: 12) {
                
                // Row 1: API URL
                HStack(alignment: .center, spacing: 8) {
                    Text("API URL:")
                        .frame(width: configKeyWidth, alignment: .trailing)
                        .lineLimit(1)
                    
                    TextField("", text: $viewModel.apiUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.leading)
                }
                
                // Row 2: Cadence (minutes)
                HStack(alignment: .center, spacing: 8) {
                    Text("Cadence (minutes):")
                        .frame(width: configKeyWidth, alignment: .trailing)
                        .lineLimit(1)
                    
                    Stepper(value: $viewModel.cadence, in: 1...60) {
                        // Show the numeric value inline with the stepper
                        Text("\(viewModel.cadence)")
                    }
                }
            }
            
            Spacer() // Pushes everything to the top
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
