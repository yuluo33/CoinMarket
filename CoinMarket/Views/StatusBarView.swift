import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: CryptoViewModel = .shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的收藏".localized)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(settings.carouselInterval.localizedInterval)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 10) {
                Text("价格单位:".localized)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(PriceUnit.allCases, id: \.self) { unit in
                        Button(action: {
                            settings.priceUnit = unit
                        }) {
                            HStack(spacing: 8) {
                                Text(unit.symbol)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(unit.name)
                                    .font(.system(size: 14))
                                Text(unit.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                if settings.priceUnit == unit {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(minWidth: 200)
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(settings.priceUnit.symbol)
                            .font(.system(size: 14, weight: .bold))
                        Text(settings.priceUnit.name)
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
            
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
            } else {
                favoritesList
            }
            
            Spacer()
            
            Button("打开主窗口".localized) {
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.openMainWindow()
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 360, height: 300)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无收藏".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Text("点击货币旁的星标添加收藏".localized)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
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
        PriceDisplayFormatter.currencyString(for: currency.currentPrice, unit: SettingsManager.shared.priceUnit)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(currency.symbol.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .frame(minWidth: 40, alignment: .leading)
            
            Spacer()
            
            Text(displayPrice)
                .font(.system(size: 14, weight: .medium))
                .frame(minWidth: 80, alignment: .trailing)
            
            Text(currency.formattedChange)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(priceChangeColor)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        }
    }
}

extension Int {
    var localizedInterval: String {
        "每秒更新".localized(String(self))
    }
}
