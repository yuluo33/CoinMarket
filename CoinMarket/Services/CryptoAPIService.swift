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
    func fetchCryptoCurrencies(limitPerCategory: Int) async throws -> [CryptoCategory: [CryptoCurrency]]
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

final class CryptoAPIService {
    static let shared = CryptoAPIService()
    
    let name: String = "Binance"
    
    private let settings = SettingsManager.shared
    private let provider: CryptoAPIProvider = BinanceProvider()
    
    private init() {
        Task {
            if ExchangeRateService.shared.shouldFetch() {
                await ExchangeRateService.shared.fetchRates()
            }
        }
    }
    
    func fetchAllCryptoCurrencies(limitPerCategory: Int = 20) async throws -> [CryptoCategory: [CryptoCurrency]] {
        try await fetchAllCryptoCurrencies(currency: settings.priceUnit, limitPerCategory: limitPerCategory)
    }
    
    func fetchAllCryptoCurrencies(currency: PriceUnit, limitPerCategory: Int = 20) async throws -> [CryptoCategory: [CryptoCurrency]] {
        if ExchangeRateService.shared.shouldFetch() {
            await ExchangeRateService.shared.fetchRates()
        }
        
        let categorizedCurrencies = try await provider.fetchCryptoCurrencies(limitPerCategory: limitPerCategory)
        let rate = ExchangeRateService.shared.getRate(to: currency.rawValue)
        
        return categorizedCurrencies.mapValues { currencies in
            currencies.map { crypto in
                CryptoCurrency(
                    id: crypto.id,
                    symbol: crypto.symbol,
                    name: crypto.name,
                    image: crypto.image,
                    currentPrice: crypto.currentPrice * rate,
                    priceChangePercentage24h: crypto.priceChangePercentage24h,
                    sparklineIn7d: crypto.sparklineIn7d,
                    marketCap: crypto.marketCap,
                    marketCapRank: crypto.marketCapRank
                )
            }
        }
    }
}

struct BinanceProvider: CryptoAPIProvider {
    let name = "Binance"
    
    private let baseURL = "https://api.binance.com/api/v3"
    private let session: URLSession
    
    private let mainstreamSymbols = [
        "BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT", "XRPUSDT",
        "ADAUSDT", "AVAXUSDT", "DOTUSDT", "MATICUSDT", "LINKUSDT",
        "LTCUSDT", "UNIUSDT", "ATOMUSDT", "XLMUSDT", "ETCUSDT",
        "XMRUSDT", "BCHUSDT", "APTUSDT", "FILUSDT", "TRXUSDT",
        "TONUSDT", "SUIUSDT", "HBARUSDT", "ICPUSDT", "NEARUSDT",
        "ARBUSDT", "OPUSDT", "INJUSDT", "SEIUSDT", "RENDERUSDT"
    ]
    
    private let memeSymbols = [
        "DOGEUSDT", "SHIBUSDT", "PEPEUSDT", "FLOKIUSDT", "BONKUSDT",
        "WIFUSDT", "BOMEUSDT", "MEMEUSDT", "TURBOUSDT", "PENGUUSDT",
        "TRUMPUSDT", "NEIROUSDT", "PNUTUSDT", "1000CHEEMSUSDT", "1MBABYDOGEUSDT",
        "DOGSUSDT", "1000SATSUSDT", "1000CATUSDT", "CATIUSDT", "ACTUSDT",
        "MUBARAKUSDT", "BANANAS31USDT", "BROCCOLI714USDT", "TSTUSDT", "GOATUSDT",
        "POPCATUSDT", "MEWUSDT"
    ]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    func fetchCryptoCurrencies(limitPerCategory: Int) async throws -> [CryptoCategory: [CryptoCurrency]] {
        guard let tickerURL = URL(string: "\(baseURL)/ticker/24hr") else {
            throw CryptoAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: tickerURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CryptoAPIError.noData
        }
        
        let tickers = try JSONDecoder().decode([BinanceTicker].self, from: data)
        
        return Dictionary(uniqueKeysWithValues: CryptoCategory.allCases.map { category in
            let selectedSymbols = Set(symbols(for: category))
            let currencies = tickers
                .filter { selectedSymbols.contains($0.symbol) }
                .sorted { $0.quoteVolumeValue > $1.quoteVolumeValue }
                .prefix(limitPerCategory)
                .enumerated()
                .map { index, ticker in
                    let symbol = normalizedSymbol(from: ticker.symbol)
                    let price = Double(ticker.lastPrice) ?? 0
                    
                    return CryptoCurrency(
                        id: symbol.lowercased(),
                        symbol: symbol.lowercased(),
                        name: getCoinName(symbol: symbol),
                        image: getCoinImage(symbol: symbol),
                        currentPrice: price,
                        priceChangePercentage24h: Double(ticker.priceChangePercent),
                        sparklineIn7d: nil,
                        marketCap: ticker.quoteVolumeValue,
                        marketCapRank: index + 1
                    )
                }
            
            return (category, currencies)
        })
    }
    
    private func symbols(for category: CryptoCategory) -> [String] {
        switch category {
        case .mainstream:
            return mainstreamSymbols
        case .meme:
            return memeSymbols
        }
    }
    
    private func normalizedSymbol(from marketSymbol: String) -> String {
        marketSymbol.replacingOccurrences(of: "USDT", with: "")
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
            "FIL": "https://assets.coingecko.com/coins/images/12817/small/filecoin.png",
            "TRX": "https://assets.coingecko.com/coins/images/1094/small/tron-logo.png",
            "TON": "https://assets.coingecko.com/coins/images/17980/small/ton_symbol.png",
            "SUI": "https://assets.coingecko.com/coins/images/26375/small/sui-ocean-square.png",
            "HBAR": "https://assets.coingecko.com/coins/images/3688/small/hbar.png",
            "ICP": "https://assets.coingecko.com/coins/images/14495/small/Internet_Computer_logo.png",
            "NEAR": "https://assets.coingecko.com/coins/images/10365/small/near.jpg",
            "ARB": "https://assets.coingecko.com/coins/images/16547/small/photo_2023-03-29_21.47.00.jpeg",
            "OP": "https://assets.coingecko.com/coins/images/25244/small/Optimism.png",
            "INJ": "https://assets.coingecko.com/coins/images/12882/small/Secondary_Symbol.png",
            "SEI": "https://assets.coingecko.com/coins/images/28205/small/Sei_Logo_-_Transparent.png",
            "RENDER": "https://assets.coingecko.com/coins/images/11636/small/rndr.png",
            "SHIB": "https://assets.coingecko.com/coins/images/11939/small/shiba.png",
            "PEPE": "https://assets.coingecko.com/coins/images/29850/small/pepe-token.jpeg",
            "FLOKI": "https://assets.coingecko.com/coins/images/16746/small/PNG_image.png",
            "BONK": "https://assets.coingecko.com/coins/images/28600/small/bonk.jpg",
            "WIF": "https://assets.coingecko.com/coins/images/33566/small/dogwifhat.jpg",
            "BOME": "https://assets.coingecko.com/coins/images/36020/small/bome.png",
            "MEME": "https://assets.coingecko.com/coins/images/33056/small/memecoin.png",
            "TURBO": "https://assets.coingecko.com/coins/images/30117/small/TurboMark-QL_200.png",
            "PENGU": "https://assets.coingecko.com/coins/images/52622/small/PUDGY_PENGUINS_PENGU_PFP.png",
            "TRUMP": "https://assets.coingecko.com/coins/images/53746/small/trump.png",
            "NEIRO": "https://assets.coingecko.com/coins/images/54541/small/neiro.jpeg",
            "PNUT": "https://assets.coingecko.com/coins/images/51264/small/peanut-the-squirrel.jpg",
            "DOGS": "https://assets.coingecko.com/coins/images/50925/small/dogs.jpg",
            "CATI": "https://assets.coingecko.com/coins/images/51690/small/catizen.jpg"
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
            "FIL": "Filecoin",
            "TRX": "TRON",
            "TON": "Toncoin",
            "SUI": "Sui",
            "HBAR": "Hedera",
            "ICP": "Internet Computer",
            "NEAR": "NEAR Protocol",
            "ARB": "Arbitrum",
            "OP": "Optimism",
            "INJ": "Injective",
            "SEI": "Sei",
            "RENDER": "Render",
            "SHIB": "Shiba Inu",
            "PEPE": "Pepe",
            "FLOKI": "FLOKI",
            "BONK": "Bonk",
            "WIF": "dogwifhat",
            "BOME": "BOOK OF MEME",
            "MEME": "Memecoin",
            "TURBO": "Turbo",
            "PENGU": "Pudgy Penguins",
            "TRUMP": "Official Trump",
            "NEIRO": "Neiro",
            "PNUT": "Peanut the Squirrel",
            "1000CHEEMS": "1000Cheems",
            "1MBABYDOGE": "Baby Doge Coin",
            "DOGS": "Dogs",
            "1000SATS": "SATS",
            "1000CAT": "1000CAT",
            "CATI": "Catizen",
            "ACT": "Act I : The AI Prophecy",
            "MUBARAK": "Mubarak",
            "BANANAS31": "Banana For Scale",
            "BROCCOLI714": "Broccoli",
            "TST": "Test Token",
            "GOAT": "Goatseus Maximus",
            "POPCAT": "Popcat",
            "MEW": "cat in a dogs world"
        ]
        
        return coinNames[symbol.uppercased()] ?? symbol
    }
}

struct BinanceTicker: Codable {
    let symbol: String
    let lastPrice: String
    let priceChangePercent: String
    let quoteVolume: String
    
    var quoteVolumeValue: Double {
        Double(quoteVolume) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case lastPrice
        case priceChangePercent
        case quoteVolume
    }
}
