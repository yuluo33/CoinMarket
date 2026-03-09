import Foundation
import Combine
import SwiftUI

@MainActor
final class CryptoViewModel: ObservableObject {
    static let shared = CryptoViewModel()
    
    @Published var currencies: [CryptoCurrency] = []
    @Published var filteredCurrencies: [CryptoCurrency] = []
    @Published var searchText: String = "" {
        didSet { filterCurrencies() }
    }
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
    }
    
    func loadCurrencies() async {
        let oldCurrencies = currencies
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedCurrencies = try await apiService.fetchCryptoCurrencies(limit: 20)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currencies = fetchedCurrencies
                self.lastUpdated = Date()
                filterCurrencies()
            }
        } catch {
            errorMessage = error.localizedDescription
            if currencies.isEmpty {
                currencies = oldCurrencies
                filterCurrencies()
            }
        }
        
        isLoading = false
    }
    
    func refresh() async {
        isRefreshing = true
        await loadCurrencies()
        isRefreshing = false
    }
    
    private func filterCurrencies() {
        if searchText.isEmpty {
            filteredCurrencies = currencies
        } else {
            let lowercasedSearch = searchText.lowercased()
            filteredCurrencies = currencies.filter {
                $0.name.lowercased().contains(lowercasedSearch) ||
                $0.symbol.lowercased().contains(lowercasedSearch)
            }
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadCurrencies()
            }
        }
        
        // 只在第一次启动时加载数据
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
