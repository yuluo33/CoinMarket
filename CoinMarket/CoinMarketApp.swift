import SwiftUI
import AppKit
import Combine

@main
struct CoinMarketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 600)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var statusBarTimer: Timer?
    var currentFavoriteIndex: Int = 0
    var cancellables = Set<AnyCancellable>()
    
    private let viewModel = CryptoViewModel()
    private let settings = SettingsManager.shared
    private let favoritesManager = FavoritesManager.shared
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupStatusBar()
        }
    }
    
    nonisolated func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            statusBarTimer?.invalidate()
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = nil
            button.title = " CoinMarket"
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 280)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: StatusBarView(viewModel: viewModel)
        )
        
        startStatusBarTimer()
        
        settings.$priceUnit
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateStatusBarTitle()
                }
            }
            .store(in: &cancellables)
        
        favoritesManager.$favoriteIds
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateStatusBarTitle()
                }
            }
            .store(in: &cancellables)
        
        settings.$carouselInterval
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.restartTimer()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startStatusBarTimer() {
        statusBarTimer?.invalidate()
        statusBarTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.carouselInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusBarTitle()
            }
        }
    }
    
    private func restartTimer() {
        startStatusBarTimer()
    }
    
    private func updateStatusBarTitle() {
        guard let button = statusItem?.button else { return }
        
        let favorites = favoritesManager.favoriteIds
        guard !favorites.isEmpty else {
            button.title = " 添加收藏"
            button.image = nil
            return
        }
        
        let favoriteList = viewModel.currencies.filter { favorites.contains($0.id) }
        guard !favoriteList.isEmpty else {
            button.title = " 添加收藏"
            button.image = nil
            return
        }
        
        let currentIndex = currentFavoriteIndex % favoriteList.count
        let crypto = favoriteList[currentIndex]
        
        let unit = settings.priceUnit
        let changeText = crypto.isPositiveChange ? "+" : ""
        let change = String(format: "%.2f", crypto.priceChangePercentage24h ?? 0)
        
        let price = formatPrice(crypto.currentPrice, unit: unit)
        
        button.title = " \(crypto.symbol.uppercased()) \(unit.symbol)\(price) \(changeText)\(change)%"
        
        currentFavoriteIndex = (currentFavoriteIndex + 1) % max(1, favoriteList.count)
    }
    
    private func formatPrice(_ price: Double, unit: PriceUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = price >= 1 ? 2 : 6
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "0.00"
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
