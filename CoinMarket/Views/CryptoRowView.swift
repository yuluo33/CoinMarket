import SwiftUI

struct CryptoRowView: View {
    let currency: CryptoCurrency
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    private var priceChangeColor: Color {
        currency.isPositiveChange ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
    
    private var priceChangeIcon: String {
        currency.isPositiveChange ? "arrow.up.right" : "arrow.down.right"
    }
    
    private var displayPrice: String {
        PriceDisplayFormatter.currencyString(for: currency.currentPrice, unit: settings.priceUnit)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                favoritesManager.toggle(currency.id, coinName: currency.name, coinSymbol: currency.symbol)
            }) {
                Image(systemName: favoritesManager.isFavorite(currency.id) ? "star.fill" : "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(favoritesManager.isFavorite(currency.id) ? .yellow : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(width: 22)
            
            logoView
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currency.symbol.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(currency.name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 70, maxWidth: 90, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(displayPrice)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 2) {
                    Image(systemName: priceChangeIcon)
                        .font(.system(size: 10, weight: .medium))
                    
                    Text(currency.formattedChange)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(priceChangeColor)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var logoView: some View {
        AsyncImage(url: URL(string: currency.image)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            case .failure, .empty:
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(String(currency.symbol.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
            @unknown default:
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
            }
        }
    }
}
