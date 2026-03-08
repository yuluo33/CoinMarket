import SwiftUI
import Charts

struct PriceChartView: View {
    let data: [Double]
    let isPositive: Bool
    
    private var chartData: [ChartDataPoint] {
        data.enumerated().map { ChartDataPoint(day: $0.offset, price: $0.element) }
    }
    
    private var chartColor: Color {
        isPositive ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
    
    private var gradientColors: [Color] {
        [chartColor.opacity(0.3), chartColor.opacity(0.0)]
    }
    
    var body: some View {
        if !data.isEmpty {
            Chart(chartData) { point in
                LineMark(
                    x: .value("Time", point.day),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", point.day),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
