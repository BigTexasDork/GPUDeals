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
    
    // Persist the cadence and apiUrl settings.
    @AppStorage("cadence") var cadence: Int = 5 {
        didSet {
            startTimer()
        }
    }
    @AppStorage("apiUrl") var apiUrl: String = "https://api.gpudeals.net/"
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        // fetch the data
        fetchData()
        startTimer()
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
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ResultsView(viewModel: viewModel)) {
                    Text("Results")
                }
                NavigationLink(destination: ConfigView(viewModel: viewModel)) {
                    Text("Config")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 150)
            
            Text("Select a tab")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


// The "Results" view displays a table with five columns.
struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        Table(viewModel.results) {
            TableColumn("Model", value: \.id)
            TableColumn("Brand", value: \.vendor)
            TableColumn("3DMark") { item in
                Text("\(item.benchmark)")
            }
            TableColumn("Value") { item in
                if let calcValue = item.calculatedValue {
                    Text("\(calcValue)")
                } else {
                    Text("")  // Blank if calculation isn't available.
                }
            }
            TableColumn("Price") { _ in
                Text("")  // Placeholder; blank for now.
            }
        }
        .padding()
    }
}

// The "Config" view allows users to adjust the API URL and refresh cadence.
struct ConfigView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("API URL", text: $viewModel.apiUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section(header: Text("Refresh Settings")) {
                Stepper(value: $viewModel.cadence, in: 1...60) {
                    Text("Cadence: \(viewModel.cadence) minutes")
                }
            }
        }
        .padding()
    }
}

// App entry point.
//@main
//struct MyApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
