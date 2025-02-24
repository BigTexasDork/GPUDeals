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
    @Published var alerts: [Alert] = []
    
    // Persisting with AppStorage
    @AppStorage("cadence") var cadence: Int = 15 {
        didSet {
            startTimer()
        }
    }
    @AppStorage("apiUrl") var apiUrl: String = "https://api.gpudeals.net/"
    @AppStorage("alerts") private var alertsData: String = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        startTimer()
        loadAlerts()
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
    
    func loadAlerts() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        if let data = alertsData.data(using: .utf8),
           let savedAlerts = try? decoder.decode([Alert].self, from: data) {
            self.alerts = savedAlerts
        } else {
            // If no saved alerts, calculate default endDateTime as now + 12 hours.
            let defaultDate = Date().addingTimeInterval(12 * 60 * 60)
            let defaultAlerts = [
                Alert(brand: "RTX 3060 Ti", price: 230, endDateTime: defaultDate),
                Alert(brand: "RTX 3070", price: 400, endDateTime: defaultDate)
            ]
            self.alerts = defaultAlerts
            saveAlerts()
        }
    }
    
    func saveAlerts() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        if let data = try? encoder.encode(alerts),
           let jsonString = String(data: data, encoding: .utf8) {
            alertsData = jsonString
        }
    }
}
