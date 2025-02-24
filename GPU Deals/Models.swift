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

    enum CodingKeys: String, CodingKey {
        case brand, price, endDateTime
    }

    init(id: UUID = UUID(), brand: String, price: Int, endDateTime: Date) {
        self.id = id
        self.brand = brand
        self.price = price
        self.endDateTime = endDateTime
    }

    // Custom decoding: if the string is already in "HH:mm" format, use that;
    // otherwise, decode using ISO8601 and then extract only hour and minute.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.brand = try container.decode(String.self, forKey: .brand)
        self.price = try container.decode(Int.self, forKey: .price)
        
        let dateString = try container.decode(String.self, forKey: .endDateTime)
        let calendar = Calendar.current
        
        var hmDate: Date?
        
        if dateString.count == 5 { // e.g. "23:59"
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let date = formatter.date(from: dateString) {
                // Normalize by setting a fixed date (e.g., Jan 1, 2000)
                var comps = calendar.dateComponents([.hour, .minute], from: date)
                comps.year = 2000
                comps.month = 1
                comps.day = 1
                hmDate = calendar.date(from: comps)
            }
        } else {
            // Try to decode as a full ISO8601 date (with fractional seconds)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let fullDate = isoFormatter.date(from: dateString) {
                let components = calendar.dateComponents([.hour, .minute], from: fullDate)
                var comps = DateComponents()
                comps.year = 2000
                comps.month = 1
                comps.day = 1
                comps.hour = components.hour
                comps.minute = components.minute
                hmDate = calendar.date(from: comps)
            }
        }
        
        guard let finalDate = hmDate else {
            throw DecodingError.dataCorruptedError(forKey: .endDateTime, in: container, debugDescription: "Unable to parse date string: \(dateString)")
        }
        self.endDateTime = finalDate
        
        self.id = UUID()
    }
    
    // Custom encoding: only encode hours and minutes using "HH:mm"
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(brand, forKey: .brand)
        try container.encode(price, forKey: .price)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let dateString = formatter.string(from: endDateTime)
        try container.encode(dateString, forKey: .endDateTime)
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
