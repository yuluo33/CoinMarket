import SwiftUI
import AppKit
import Combine

@main
struct CoinMarketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("CoinMarket", id: AppDelegate.mainWindowID) {
            ContentView()
                .background(
                    MainWindowAccessor { window in
                        appDelegate.registerMainWindow(window)
                    }
                )
                .background(
                    OpenWindowActionAccessor { openWindow in
                        appDelegate.registerOpenWindowAction(openWindow)
                    }
                )
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 600)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static let mainWindowID = "main-window"
    
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var statusBarTimer: Timer?
    var currentFavoriteIndex: Int = 0
    var cancellables = Set<AnyCancellable>()
    
    private weak var mainWindow: NSWindow?
    private var openWindowAction: OpenWindowAction?
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
    
    nonisolated func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            Task { @MainActor in
                openMainWindow()
            }
        }
        return false
    }
    
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
    
    func registerOpenWindowAction(_ action: OpenWindowAction) {
        openWindowAction = action
    }
    
    func registerMainWindow(_ window: NSWindow?) {
        guard let window else { return }
        
        if mainWindow !== window {
            mainWindow?.delegate = nil
            mainWindow = window
            window.identifier = NSUserInterfaceItemIdentifier(Self.mainWindowID)
            window.delegate = self
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === mainWindow {
            sender.orderOut(nil)
            return false
        }
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === mainWindow else { return }
        mainWindow = nil
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = nil
            button.title = " CoinMarket"
            button.action = #selector(openMainWindow)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: StatusBarView()
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
        // 创建一个强引用副本，避免在并发代码中直接引用self
        let weakSelf = self
        statusBarTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.carouselInterval), repeats: true) { _ in
            Task { @MainActor in
                weakSelf.updateStatusBarTitle()
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
        
        let favoriteList = CryptoViewModel.shared.currencies.filter { favorites.contains($0.id) }
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
    
    @objc func openMainWindow() {
        popover?.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        if let mainWindow {
            if mainWindow.isMiniaturized {
                mainWindow.deminiaturize(nil)
            }
            mainWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        if let existingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == Self.mainWindowID }) {
            registerMainWindow(existingWindow)
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        openWindowAction?.callAsFunction(id: Self.mainWindowID)
    }
}

private struct OpenWindowActionAccessor: View {
    @Environment(\.openWindow) private var openWindow
    let onResolve: (OpenWindowAction) -> Void
    
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onAppear {
                onResolve(openWindow)
            }
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = WindowReaderView()
        view.onResolve = onResolve
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? WindowReaderView else { return }
        view.onResolve = onResolve
        view.resolveWindow()
    }
    
    private final class WindowReaderView: NSView {
        var onResolve: ((NSWindow?) -> Void)?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            resolveWindow()
        }
        
        func resolveWindow() {
            DispatchQueue.main.async { [weak self] in
                self?.onResolve?(self?.window)
            }
        }
    }
}
