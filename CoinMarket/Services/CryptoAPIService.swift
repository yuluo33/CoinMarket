import Foundation

enum CryptoAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case allAPIsFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .noData:
            return "未获取到数据"
        case .allAPIsFailed:
            return "所有 API 服务暂时不可用，请稍后重试"
        }
    }
}

protocol CryptoAPIProvider {
    var name: String { get }
    func fetchCryptoCurrencies(currency: PriceUnit, limit: Int) async throws -> [CryptoCurrency]
}

final class ExchangeRateService {
    static let shared = ExchangeRateService()
    
    private var exchangeRates: [String: Double] = [:]
    private var lastFetchTime: Date?
    private let fetchInterval: TimeInterval = 3600
    
    private init() {}
    
    func getRate(to: String) -> Double {
        var toCurrency = to
        if toCurrency == "USDT" { toCurrency = "USD" }
        
        if let rate = exchangeRates["USD_\(toCurrency)"] {
            return rate
        }
        
        return 1.0
    }
    
    func fetchRates() async {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=USD") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(FrankfurterResponse.self, from: data)
            
            if let cny = response.rates["CNY"] {
                exchangeRates["USD_CNY"] = cny
            }
            if let krw = response.rates["KRW"] {
                exchangeRates["USD_KRW"] = krw
            }
            if let jpy = response.rates["JPY"] {
                exchangeRates["USD_JPY"] = jpy
            }
            if let vnd = response.rates["VND"] {
                exchangeRates["USD_VND"] = vnd
            }
            
            lastFetchTime = Date()
        } catch {
            // 使用默认汇率
        }
    }
    
    func shouldFetch() -> Bool {
        guard let lastTime = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastTime) > fetchInterval
    }
}

struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}

final class CryptoAPIService: CryptoAPIProvider {
    static let shared = CryptoAPIService()
    
    let name: String = "Binance"
    
    private let settings = SettingsManager.shared
    
    private init() {
        Task {
            if ExchangeRateService.shared.shouldFetch() {
                await ExchangeRateService.shared.fetchRates()
            }
        }
    }
    
    func fetchCryptoCurrencies(limit: Int = 20) async throws -> [CryptoCurrency] {
        return try await fetchCryptoCurrencies(currency: settings.priceUnit, limit: limit)
    }
    
    func fetchCryptoCurrencies(currency: PriceUnit, limit: Int = 20) async throws -> [CryptoCurrency] {
        if ExchangeRateService.shared.shouldFetch() {
            await ExchangeRateService.shared.fetchRates()
        }
        
        let provider = BinanceProvider()
        let currencies = try await provider.fetchCryptoCurrencies(currency: .usd, limit: limit)
        
        let rate = ExchangeRateService.shared.getRate(to: currency.rawValue)
        
        return currencies.map { crypto in
            let convertedPrice = crypto.currentPrice * rate
            
            return CryptoCurrency(
                id: crypto.id,
                symbol: crypto.symbol,
                name: crypto.name,
                image: crypto.image,
                currentPrice: convertedPrice,
                priceChangePercentage24h: crypto.priceChangePercentage24h,
                sparklineIn7d: crypto.sparklineIn7d,
                marketCap: crypto.marketCap,
                marketCapRank: crypto.marketCapRank
            )
        }
    }
}

struct BinanceProvider: CryptoAPIProvider {
    let name = "Binance"
    
    private let baseURL = "https://api.binance.com/api/v3"
    private let session: URLSession
    
    private let topSymbols = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT", "XRPUSDT", 
                            "ADAUSDT", "DOGEUSDT", "AVAXUSDT", "DOTUSDT", "MATICUSDT",
                            "LINKUSDT", "LTCUSDT", "UNIUSDT", "ATOMUSDT", "XLMUSDT",
                            "ETCUSDT", "XMRUSDT", "BCHUSDT", "APTUSDT", "FILUSDT"]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    func fetchCryptoCurrencies(currency: PriceUnit, limit: Int) async throws -> [CryptoCurrency] {
        guard let tickerUrl = URL(string: "\(baseURL)/ticker/24hr") else {
            throw CryptoAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: tickerUrl)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CryptoAPIError.noData
        }
        
        let binanceTickers = try JSONDecoder().decode([BinanceTicker].self, from: data)
        
        let filteredTickers = binanceTickers
            .filter { topSymbols.contains($0.symbol) }
            .prefix(limit)
        
        return filteredTickers.enumerated().map { index, ticker in
            let price = Double(ticker.lastPrice) ?? 0
            
            let symbol = ticker.symbol.replacingOccurrences(of: "USDT", with: "")
            
            return CryptoCurrency(
                id: symbol.lowercased(),
                symbol: symbol.lowercased(),
                name: getCoinName(symbol: symbol),
                image: getCoinImage(symbol: symbol),
                currentPrice: price,
                priceChangePercentage24h: Double(ticker.priceChangePercent),
                sparklineIn7d: nil,
                marketCap: nil,
                marketCapRank: index + 1
            )
        }
    }
    
    private func getCoinImage(symbol: String) -> String {
        let coinImages: [String: String] = [
            "BTC": "https://assets.coingecko.com/coins/images/1/small/bitcoin.png",
            "ETH": "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
            "BNB": "https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png",
            "SOL": "https://assets.coingecko.com/coins/images/4128/small/solana.png",
            "XRP": "https://assets.coingecko.com/coins/images/44/small/xrp-symbol-white-128.png",
            "ADA": "https://assets.coingecko.com/coins/images/975/small/cardano.png",
            "DOGE": "https://assets.coingecko.com/coins/images/5/small/dogecoin.png",
            "AVAX": "https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png",
            "DOT": "https://assets.coingecko.com/coins/images/12171/small/polkadot.png",
            "MATIC": "https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png",
            "LINK": "https://assets.coingecko.com/coins/images/877/small/chainlink-new-logo.png",
            "LTC": "https://assets.coingecko.com/coins/images/2/small/litecoin.png",
            "UNI": "https://assets.coingecko.com/coins/images/12504/small/uniswap-uni.png",
            "ATOM": "https://assets.coingecko.com/coins/images/1481/small/cosmos_hub.png",
            "XLM": "https://assets.coingecko.com/coins/images/100/small/Stellar_symbol_black_RGB.png",
            "ETC": "https://assets.coingecko.com/coins/images/453/small/ethereum-classic-logo.png",
            "XMR": "https://assets.coingecko.com/coins/images/69/small/monero_logo.png",
            "BCH": "https://assets.coingecko.com/coins/images/780/small/bitcoin-cash-circle.png",
            "APT": "https://assets.coingecko.com/coins/images/26455/small/aptos_round.png",
            "FIL": "https://assets.coingecko.com/coins/images/12817/small/filecoin.png"
        ]
        return coinImages[symbol.uppercased()] ?? ""
    }
    
    private func getCoinName(symbol: String) -> String {
        let coinNames: [String: String] = [
            "BTC": "Bitcoin",
            "ETH": "Ethereum",
            "BNB": "BNB",
            "SOL": "Solana",
            "XRP": "XRP",
            "ADA": "Cardano",
            "DOGE": "Dogecoin",
            "AVAX": "Avalanche",
            "DOT": "Polkadot",
            "MATIC": "Polygon",
            "LINK": "Chainlink",
            "LTC": "Litecoin",
            "UNI": "Uniswap",
            "ATOM": "Cosmos",
            "XLM": "Stellar",
            "ETC": "Ethereum Classic",
            "XMR": "Monero",
            "BCH": "Bitcoin Cash",
            "APT": "Aptos",
            "FIL": "Filecoin"
        ]
        return coinNames[symbol.uppercased()] ?? symbol
    }
}

struct BinanceTicker: Codable {
    let symbol: String
    let lastPrice: String
    let priceChangePercent: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case lastPrice
        case priceChangePercent
    }
}
