import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: CryptoViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    private var settings: SettingsManager {
        SettingsManager.shared
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("我的收藏".localized)
                    .font(.headline)
                Spacer()
                Text(settings.carouselInterval.localizedInterval)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)
            
            HStack(spacing: 8) {
                Text("价格单位:".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(PriceUnit.allCases, id: \.self) {
                        unit in
                        Button(action: {
                            settings.priceUnit = unit
                            Task {
                                await viewModel.loadCurrencies()
                            }
                        }) {
                            HStack {
                                Text(unit.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(unit.name)
                                    .font(.system(size: 12))
                                Spacer()
                                if settings.priceUnit == unit {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(settings.priceUnit.symbol)
                            .font(.caption.weight(.bold))
                        Text(settings.priceUnit.name)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
            } else {
                favoritesList
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("打开主窗口".localized) {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .frame(width: 300, height: 260)
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "star")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("暂无收藏".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("点击货币旁的星标添加收藏".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(favoriteCurrencies) { crypto in
                    FavoriteRowView(currency: crypto)
                }
            }
        }
    }
    
    private var favoriteCurrencies: [CryptoCurrency] {
        viewModel.currencies.filter { favoritesManager.favoriteIds.contains($0.id) }
    }
}

struct FavoriteRowView: View {
    let currency: CryptoCurrency
    
    private var priceChangeColor: Color {
        currency.isPositiveChange ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
    
    private var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = SettingsManager.shared.priceUnit.symbol
        formatter.maximumFractionDigits = currency.currentPrice >= 1 ? 2 : 6
        return formatter.string(from: NSNumber(value: currency.currentPrice)) ?? "\(SettingsManager.shared.priceUnit.symbol)0.00"
    }
    
    var body: some View {
        HStack {
            Text(currency.symbol.uppercased())
                .font(.system(size: 12, weight: .medium))
            
            Spacer()
            
            Text(displayPrice)
                .font(.system(size: 12, weight: .medium))
            
            Text(currency.formattedChange)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(priceChangeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        }
    }
}

extension Int {
    var localizedInterval: String {
        "每秒更新".localized(String(self))
    }
}
