import SwiftUI

struct CryptoListView: View {
    let currencies: [CryptoCurrency]
    
    @State private var appearedIds: Set<String> = []
    @State private var currenciesHash: Int = 0
    
    private var groupedCurrencies: [[CryptoCurrency]] {
        stride(from: 0, to: currencies.count, by: 2).map {
            Array(currencies[$0..<min($0 + 2, currencies.count)])
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 10) {
                ForEach(Array(groupedCurrencies.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 10) {
                        ForEach(row) { currency in
                            CryptoRowView(currency: currency)
                                .opacity(appearedIds.contains(currency.id) ? 1 : 0)
                                .scaleEffect(appearedIds.contains(currency.id) ? CGSize(width: 1, height: 1) : CGSize(width: 0.8, height: 0.8))
                                .onAppear {
                                    var ids = appearedIds
                                    ids.insert(currency.id)
                                    let animation = Animation.easeOut(duration: 0.3)
                                    withAnimation(animation) {
                                        appearedIds = ids
                                    }
                                }
                        }
                        if row.count == 1 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onChange(of: currenciesHash) { _ in
            appearedIds.removeAll()
            for (index, currency) in currencies.enumerated() {
                let animation = Animation.easeOut(duration: 0.3)
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    var ids = appearedIds
                    ids.insert(currency.id)
                    withAnimation(animation) {
                        appearedIds = ids
                    }
                }
            }
        }
        .onAppear {
            currenciesHash = currencies.count
            for (index, currency) in currencies.enumerated() {
                let animation = Animation.easeOut(duration: 0.3)
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    var ids = appearedIds
                    ids.insert(currency.id)
                    withAnimation(animation) {
                        appearedIds = ids
                    }
                }
            }
        }
    }
}