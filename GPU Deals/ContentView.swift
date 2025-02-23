import SwiftUI
import Combine

// Define a simple model for the API data.
struct ResultItem: Identifiable, Decodable {
    let id: UUID = UUID() // Replace with a real identifier if available.
    let name: String
    let value: String
}

// ViewModel that handles API calls and configuration persistence.
class AppViewModel: ObservableObject {
    @Published var results: [ResultItem] = []
    
    // Use @AppStorage to persist the settings.
    @AppStorage("cadence") var cadence: Int = 5 {
        didSet {
            startTimer()
        }
    }
    @AppStorage("apiUrl") var apiUrl: String = "https://api.example.com/data"
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    // Sets up a timer that fires every `cadence` minutes.
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

// The "Results" view displays a table of data returned by the API.
struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        // Using Table (available in macOS 12+). Replace with List for earlier versions.
        Table(viewModel.results) {
            TableColumn("Name", value: \.name)
            TableColumn("Value", value: \.value)
        }
        .padding()
    }
}

// The "Config" view lets the user set the cadence (in minutes) and the API URL.
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
