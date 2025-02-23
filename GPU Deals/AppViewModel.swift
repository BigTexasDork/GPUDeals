//
//  AppViewModel.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//
import SwiftUI
import Combine

// The ViewModel handles API calls and persists settings using @AppStorage.
class AppViewModel: ObservableObject {
    @Published var results: [ResultItem] = []
    @Published var lastAPICall: Date? = nil
    
    // Persist the cadence and apiUrl settings.
    @AppStorage("cadence") var cadence: Int = 15 {
        didSet {
            startTimer()
        }
    }
    @AppStorage("apiUrl") var apiUrl: String = "https://api.gpudeals.net/"
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        startTimer()
        fetchData()
    }
    
    // Sets up a timer that fires every 'cadence' minutes.
    func startTimer() {
        timerCancellable?.cancel()
        let cadenceSeconds = TimeInterval(cadence * 60)
        timerCancellable = Timer.publish(every: cadenceSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchData()
            }
    }
    
    // API call to fetch and decode data.
    func fetchData() {
        // Record the time of the API call.
        DispatchQueue.main.async {
            self.lastAPICall = Date()
        }
        
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL: \(apiUrl)")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResults = try JSONDecoder().decode([ResultItem].self, from: data)
                    DispatchQueue.main.async {
                        self.results = decodedResults
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
            } else if let error = error {
                print("Network error: \(error)")
            }
        }.resume()
    }
}
