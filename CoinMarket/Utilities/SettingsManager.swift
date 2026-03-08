import Foundation
import Combine

enum PriceUnit: String, CaseIterable, Codable {
    case usdt = "USDT"
    case cny = "CNY"
    case krw = "KRW"
    case jpy = "JPY"
    case usd = "USD"
    case vnd = "VND"
    
    var symbol: String {
        switch self {
        case .usdt: return "₮"
        case .cny: return "¥"
        case .krw: return "₩"
        case .jpy: return "¥"
        case .usd: return "$"
        case .vnd: return "₫"
        }
    }
    
    var name: String {
        switch self {
        case .usdt: return "USDT"
        case .cny: return "人民币"
        case .krw: return "韩元"
        case .jpy: return "日元"
        case .usd: return "美元"
        case .vnd: return "越南盾"
        }
    }
    
    var displayName: String {
        switch self {
        case .usdt: return "USDT"
        case .cny: return "CNY"
        case .krw: return "KRW"
        case .jpy: return "JPY"
        case .usd: return "USD"
        case .vnd: return "VND"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case zh = "zh"
    case en = "en"
    case ja = "ja"
    case ko = "ko"
    case vi = "vi"
    
    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .vi: return "Tiếng Việt"
        }
    }
    
    var defaultPriceUnit: PriceUnit {
        switch self {
        case .zh: return .cny
        case .en: return .usd
        case .ja: return .jpy
        case .ko: return .krw
        case .vi: return .vnd
        }
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var refreshInterval: Int {
        didSet { save() }
    }
    
    @Published var carouselInterval: Int {
        didSet { save() }
    }
    
    @Published var priceUnit: PriceUnit {
        didSet { save() }
    }
    
    @Published var language: AppLanguage {
        didSet { save() }
    }
    
    private let refreshIntervalKey = "refresh_interval"
    private let carouselIntervalKey = "carousel_interval"
    private let priceUnitKey = "price_unit"
    private let languageKey = "app_language"
    
    private init() {
        let storedInterval = UserDefaults.standard.integer(forKey: refreshIntervalKey)
        self.refreshInterval = storedInterval == 0 ? 45 : storedInterval
        
        let storedCarouselInterval = UserDefaults.standard.integer(forKey: carouselIntervalKey)
        self.carouselInterval = storedCarouselInterval == 0 ? 10 : storedCarouselInterval
        
        if let langString = UserDefaults.standard.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: langString) {
            self.language = lang
        } else {
            self.language = .zh
        }
        
        if let unitString = UserDefaults.standard.string(forKey: priceUnitKey),
           let unit = PriceUnit(rawValue: unitString) {
            self.priceUnit = unit
        } else {
            self.priceUnit = .cny
        }
    }
    
    private func save() {
        UserDefaults.standard.set(refreshInterval, forKey: refreshIntervalKey)
        UserDefaults.standard.set(carouselInterval, forKey: carouselIntervalKey)
        UserDefaults.standard.set(priceUnit.rawValue, forKey: priceUnitKey)
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }
    
    func togglePriceUnit() {
        let currentIndex = PriceUnit.allCases.firstIndex(of: priceUnit) ?? 0
        let nextIndex = (currentIndex + 1) % PriceUnit.allCases.count
        priceUnit = PriceUnit.allCases[nextIndex]
    }
}
