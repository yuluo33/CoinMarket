import Foundation
import Combine
import SwiftUI

@MainActor
final class CryptoViewModel: ObservableObject {
    static let shared = CryptoViewModel()
    
    @Published private(set) var categorizedCurrencies: [CryptoCategory: [CryptoCurrency]] = [:]
    @Published var selectedCategory: CryptoCategory = .mainstream
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var isRefreshing: Bool = false
    
    private let apiService = CryptoAPIService.shared
    private let settings = SettingsManager.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedData = false
    
    private init() {
        setupSettingsObserver()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func setupSettingsObserver() {
        settings.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in
                self?.restartTimer()
            }
            .store(in: &cancellables)
        
        settings.$priceUnit
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCurrencies()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadCurrencies() async {
        let oldCategorizedCurrencies = categorizedCurrencies
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedCurrencies = try await apiService.fetchAllCryptoCurrencies(limitPerCategory: 20)
            categorizedCurrencies = fetchedCurrencies
            lastUpdated = Date()
        } catch {
            if oldCategorizedCurrencies.isEmpty {
                errorMessage = error.localizedDescription
                categorizedCurrencies = oldCategorizedCurrencies
            }
        }
        
        isLoading = false
    }
    
    func refresh() async {
        isRefreshing = true
        await loadCurrencies()
        isRefreshing = false
    }
    
    var currencies: [CryptoCurrency] {
        mergedCurrencies(from: categorizedCurrencies)
    }
    
    var filteredCurrencies: [CryptoCurrency] {
        let baseCurrencies = categorizedCurrencies[selectedCategory] ?? []
        let normalizedSearch = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !normalizedSearch.isEmpty else {
            return baseCurrencies
        }
        
        return baseCurrencies.filter {
            $0.name.lowercased().contains(normalizedSearch) ||
            $0.symbol.lowercased().contains(normalizedSearch)
        }
    }
    
    private func mergedCurrencies(from source: [CryptoCategory: [CryptoCurrency]]) -> [CryptoCurrency] {
        var merged: [CryptoCurrency] = []
        
        for category in CryptoCategory.allCases {
            guard let categoryCurrencies = source[category] else { continue }
            
            for currency in categoryCurrencies where !merged.contains(where: { $0.id == currency.id }) {
                merged.append(currency)
            }
        }
        
        return merged
    }
    
    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadCurrencies()
            }
        }
        
        if !hasLoadedData {
            hasLoadedData = true
            Task {
                await loadCurrencies()
            }
        }
    }
    
    private func restartTimer() {
        startAutoRefresh()
    }
    
    var formattedLastUpdated: String {
        guard let date = lastUpdated else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
