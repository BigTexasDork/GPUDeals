import SwiftUI
import Combine

// MARK: - Data Models

// The API returns JSON with the "id", "vendor", "benchmark", and "listings" fields.
struct ResultItem: Identifiable, Decodable {
    let id: String       // Maps to "id" (e.g., "RTX 4090")
    let vendor: String   // Maps to "vendor" (e.g., "nvidia")
    let benchmark: Int   // Maps to "benchmark" (e.g., 35000)
    let listings: [String: Listing]
}

struct Listing: Decodable {
    let price: String
    let url: String
}

// Helper extension to convert a price string to a Double.
extension String {
    var currencyValue: Double? {
        // Remove non-digit and non-decimal characters.
        let filtered = self.filter { "0123456789.".contains($0) }
        return Double(filtered)
    }
}

// Computed properties to get the lowest price and the calculated "Value".
extension ResultItem {
    var lowestPrice: Double? {
        let prices = listings.values.compactMap { $0.price.currencyValue }
        return prices.min()
    }
    
    var calculatedValue: Int? {
        guard let lowest = lowestPrice, lowest != 0 else { return nil }
        let computed = Double(benchmark) / lowest
        return Int(computed.rounded())
    }
}

// The ViewModel handles API calls and persists settings using @AppStorage.
class AppViewModel: ObservableObject {
    @Published var results: [ResultItem] = []
    @Published var lastAPICall: Date? = nil
    
    // Persist the cadence and apiUrl settings.
    @AppStorage("cadence") var cadence: Int = 5 {
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
