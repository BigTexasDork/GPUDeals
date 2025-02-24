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
        
        if let data = alertsData.data(using: .utf8),
           let savedAlerts = try? decoder.decode([Alert].self, from: data) {
            self.alerts = savedAlerts
        } else {
            // Updated hard-coded JSON using only "HH:mm" for the time.
            let jsonString = """
            [
                {
                    "brand": "RTX 3060 Ti",
                    "price": 230,
                    "endDateTime": "23:59"
                },
                {
                    "brand": "RTX 3070",
                    "price": 400,
                    "endDateTime": "23:59"
                }
            ]
            """
            if let jsonData = jsonString.data(using: .utf8),
               let hardCodedAlerts = try? decoder.decode([Alert].self, from: jsonData) {
                self.alerts = hardCodedAlerts
                saveAlerts() // Persist the hard-coded alerts.
            }
        }
    }
    
    func saveAlerts() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(alerts),
           let jsonString = String(data: data, encoding: .utf8) {
            alertsData = jsonString
        }
    }}
