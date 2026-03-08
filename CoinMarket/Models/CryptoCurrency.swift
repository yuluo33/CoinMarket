import Foundation

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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = currentPrice >= 1 ? 2 : 6
        return formatter.string(from: NSNumber(value: currentPrice)) ?? "$0.00"
    }

    var formattedChange: String {
        guard let change = priceChangePercentage24h else { return "0.00%" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))%"
    }

    var isPositiveChange: Bool {
        return (priceChangePercentage24h ?? 0) >= 0
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
