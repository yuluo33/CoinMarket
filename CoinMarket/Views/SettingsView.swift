import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("设置".localized)
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .frame(height: 56)
                .background(Color(.windowBackgroundColor))
                
                Divider()
                
                VStack(alignment: .leading, spacing: 20) {
                    SettingsOptionView(
                        title: "语言".localized,
                        buttons: AppLanguage.allCases.map { lang in
                            SettingsButton(
                                title: lang.displayName,
                                isSelected: settings.language == lang,
                                action: { settings.language = lang }
                            )
                        }
                    )
                    
                    SettingsOptionView(
                        title: "价格单位".localized,
                        buttons: PriceUnit.allCases.map { unit in
                            SettingsButton(
                                title: "\(unit.symbol) \(unit.displayName)",
                                isSelected: settings.priceUnit == unit,
                                action: { settings.priceUnit = unit }
                            )
                        }
                    )
                    
                    SettingsOptionView(
                        title: "自动刷新间隔".localized,
                        buttons: [5, 10, 15, 30, 60].map { interval in
                            SettingsButton(
                                title: "\(interval)" + "秒".localizedSeconds,
                                isSelected: settings.refreshInterval == interval,
                                action: { settings.refreshInterval = interval }
                            )
                        }
                    )
                    
                    SettingsOptionView(
                        title: "状态栏轮播间隔".localized,
                        buttons: [3, 5, 10, 15, 20].map { interval in
                            SettingsButton(
                                title: "\(interval)" + "秒".localizedSeconds,
                                isSelected: settings.carouselInterval == interval,
                                action: { settings.carouselInterval = interval }
                            )
                        }
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                .padding(.horizontal, 22)
                
                Spacer()
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Powered by ")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Link("Binance", destination: URL(string: "https://www.binance.com")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text(" & ")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Link("Frankfurter", destination: URL(string: "https://www.frankfurter.app")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    
                    Link("Designed by yuluo33", destination: URL(string: "https://github.com/yuluo33")!)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.blue)
                    .padding(.bottom, 16)
                }
            }
            .frame(width: 500, height: 480)
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct SettingsOptionView: View {
    let title: String
    let buttons: [SettingsButton]
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            
            HStack(spacing: 10) {
                ForEach(buttons.indices, id: \.self) { index in
                    Button(action: buttons[index].action) {
                        Text(buttons[index].title)
                            .font(.system(size: 13, weight: buttons[index].isSelected ? .semibold : .regular))
                            .foregroundColor(buttons[index].isSelected ? .white : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(buttons[index].isSelected ? Color.blue : Color.gray.opacity(0.2))
                            }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }
}

struct SettingsButton {
    let title: String
    let isSelected: Bool
    let action: () -> Void
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

#Preview {
    SettingsView()
}
