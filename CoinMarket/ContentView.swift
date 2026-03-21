import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingSettings = false
    @State private var showToast = false
    @State private var toastType: ToastView.ToastType = .success
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.windowBackgroundColor).opacity(0.8),
                    Color(.windowBackgroundColor).opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                if viewModel.isLoading && viewModel.currencies.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.currencies.isEmpty {
                    errorView(message: error)
                } else if viewModel.filteredCurrencies.isEmpty {
                    emptyView
                } else {
                    CryptoListView(currencies: viewModel.filteredCurrencies)
                }
            }
        }
        .frame(minWidth: 750, minHeight: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toast(isShowing: $showToast, type: toastType, message: toastMessage, duration: 1.5)
        .onChange(of: favoritesManager.lastAction) { _, newValue in
            if let action = newValue {
                toastMessage = "\(action.action) \(action.coin)"
                toastType = action.action == "已收藏".localized ? .success : .error
                showToast = true
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Text("CoinMarket".localized)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer(minLength: 16)
            
            categoryPicker
                .frame(width: 200)
            
            SearchBar(text: $viewModel.searchText)
                .frame(width: 220)
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var categoryPicker: some View {
        Picker("", selection: $viewModel.selectedCategory) {
            ForEach(CryptoCategory.allCases) { category in
                Text(category.titleKey.localized)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载中...".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("加载失败".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadCurrencies()
                }
            }) {
                Text("重试".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "007AFF"))
                    }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("未找到相关币种".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("请尝试其他搜索词".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
