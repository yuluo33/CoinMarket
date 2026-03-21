import Foundation

enum CryptoCategory: String, CaseIterable, Codable, Identifiable {
    case mainstream
    case meme
    
    var id: String { rawValue }
    
    var titleKey: String {
        switch self {
        case .mainstream:
            return "主流币"
        case .meme:
            return "Meme币"
        }
    }
}

struct CryptoCurrency: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let priceChangePercentage24h: Double?
    let sparklineIn7d: SparklineData?
    let marketCap: Double?
    let marketCapRank: Int?

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case sparklineIn7d = "sparkline_in_7d"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
    }

    var formattedPrice: String {
        PriceDisplayFormatter.usdCurrencyString(for: currentPrice)
    }

    var formattedChange: String {
        guard let change = priceChangePercentage24h else { return "0.00%" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))%"
    }

    var isPositiveChange: Bool {
        (priceChangePercentage24h ?? 0) >= 0
    }
}

enum PriceDisplayFormatter {
    static func maximumFractionDigits(for price: Double) -> Int {
        let absolutePrice = abs(price)
        switch absolutePrice {
        case 1000...:
            return 2
        case 1..<1000:
            return 3
        case 0.01..<1:
            return 4
        case 0.0001..<0.01:
            return 6
        default:
            return 8
        }
    }
    
    static func minimumFractionDigits(for price: Double) -> Int {
        let absolutePrice = abs(price)
        switch absolutePrice {
        case 0.0001..<0.01:
            return 4
        case ..<0.0001:
            return 6
        default:
            return 2
        }
    }
    
    static func currencyString(for price: Double, unit: PriceUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = unit.symbol
        formatter.minimumFractionDigits = minimumFractionDigits(for: price)
        formatter.maximumFractionDigits = maximumFractionDigits(for: price)
        return formatter.string(from: NSNumber(value: price)) ?? "\(unit.symbol)0.00"
    }
    
    static func usdCurrencyString(for price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = minimumFractionDigits(for: price)
        formatter.maximumFractionDigits = maximumFractionDigits(for: price)
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
    
    static func decimalString(for price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits(for: price)
        formatter.maximumFractionDigits = maximumFractionDigits(for: price)
        return formatter.string(from: NSNumber(value: price)) ?? "0.00"
    }
}

struct SparklineData: Codable, Hashable {
    let price: [Double]?
    
    var chartData: [Double] {
        price ?? []
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let price: Double
}
