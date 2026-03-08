import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置".localized)
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("语言".localized)
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack {
                        ForEach(AppLanguage.allCases, id: \.self) {
                            lang in
                            Button(action: {
                                settings.language = lang
                            }) {
                                Text(lang.displayName)
                                    .font(.system(size: 12, weight: settings.language == lang ? .semibold : .regular))
                                    .foregroundColor(settings.language == lang ? .white : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background {
                                        Capsule()
                                            .fill(settings.language == lang ? Color.blue : Color.gray.opacity(0.2))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("价格单位".localized)
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 8) {
                        ForEach(PriceUnit.allCases, id: \.self) {
                            unit in
                            Button(action: {
                                settings.priceUnit = unit
                            }) {
                                HStack(spacing: 4) {
                                    Text(unit.symbol)
                                        .font(.system(size: 12, weight: settings.priceUnit == unit ? .semibold : .regular))
                                    Text(unit.displayName)
                                        .font(.system(size: 12, weight: settings.priceUnit == unit ? .semibold : .regular))
                                }
                                .foregroundColor(settings.priceUnit == unit ? .white : .primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(settings.priceUnit == unit ? Color.blue : Color.gray.opacity(0.2))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("自动刷新间隔".localized)
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack {
                        ForEach([5, 10, 15, 30, 60], id: \.self) {
                            interval in
                            Button(action: {
                                settings.refreshInterval = interval
                            }) {
                                Text("\(interval)" + "秒".localizedSeconds)
                                    .font(.system(size: 12, weight: settings.refreshInterval == interval ? .semibold : .regular))
                                    .foregroundColor(settings.refreshInterval == interval ? .white : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background {
                                        Capsule()
                                            .fill(settings.refreshInterval == interval ? Color.blue : Color.gray.opacity(0.2))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("状态栏轮播间隔".localized)
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack {
                        ForEach([3, 5, 10, 15, 20], id: \.self) {
                            interval in
                            Button(action: {
                                settings.carouselInterval = interval
                            }) {
                                Text("\(interval)" + "秒".localizedSeconds)
                                    .font(.system(size: 12, weight: settings.carouselInterval == interval ? .semibold : .regular))
                                    .foregroundColor(settings.carouselInterval == interval ? .white : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background {
                                        Capsule()
                                            .fill(settings.carouselInterval == interval ? Color.blue : Color.gray.opacity(0.2))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API 数据源".localized)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Button(action: {
                        if let url = URL(string: "https://www.binance.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.yellow)
                            Text("Powered by Binance")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 20) // 增加顶部内边距，使内容距离标题不要太近
        }
        .frame(width: 400, height: 450)
    }
}

extension String {
    var localizedSeconds: String {
        switch SettingsManager.shared.language {
        case .zh: return "秒"
        case .en: return "s"
        case .ja: return "秒"
        case .ko: return "초"
        case .vi: return "giây"
        }
    }
}
