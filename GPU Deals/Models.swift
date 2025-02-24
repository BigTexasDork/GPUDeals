//
//  Models.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//
import Foundation

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

// Alerts
struct Alert: Codable, Identifiable {
    let id: UUID
    let brand: String
    let price: Int
    let endDateTime: Date

    init(id: UUID = UUID(), brand: String, price: Int, endDateTime: Date) {
        // Truncate the date to whole seconds
        let truncatedTime = Date(timeIntervalSince1970: floor(endDateTime.timeIntervalSince1970))
        self.id = id
        self.brand = brand
        self.price = price
        self.endDateTime = truncatedTime
    }
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
