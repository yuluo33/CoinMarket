import SwiftUI

struct ToastView: View {
    enum ToastType {
        case success
        case error
        case loading
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .loading: return "arrow.clockwise"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return Color(hex: "34C759")
            case .error: return Color(hex: "FF3B30")
            case .loading: return Color(hex: "007AFF")
            }
        }
    }
    
    let type: ToastType
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            if type == .loading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(type.color)
            }
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct ToastModifierWithTimer: ViewModifier {
    @Binding var isShowing: Bool
    let type: ToastView.ToastType
    let message: String
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    ToastView(type: type, message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .onChange(of: isShowing) {
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, type: ToastView.ToastType, message: String, duration: Double = 2.0) -> some View {
        modifier(ToastModifierWithTimer(isShowing: isShowing, type: type, message: message, duration: duration))
    }
}