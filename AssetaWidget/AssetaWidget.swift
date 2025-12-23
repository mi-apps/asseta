//
//  AssetaWidget.swift
//  AssetaWidget
//
//  Created by Steven on 19.12.25.
//

import WidgetKit
import SwiftUI

// Widget Data Helper (duplicated for widget extension)
struct WidgetDataHelper {
    static let appGroupIdentifier = "group.com.milabs.Asseta.widget"
    static let netWorthKey = "netWorth"
    
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    struct NetWorthData {
        let currentValue: Decimal
        let historicalValues: [(Date, Decimal)]
        let currencyCode: String
        let isAnonymized: Bool
        let lastUpdated: Date
    }
    
    static func loadNetWorthData() -> NetWorthData? {
        guard let defaults = sharedUserDefaults,
              let dict = defaults.dictionary(forKey: netWorthKey) else {
            return nil
        }
        
        guard let currentValueDouble = dict["currentValue"] as? Double,
              let historicalValuesArray = dict["historicalValues"] as? [[String: Any]],
              let currencyCode = dict["currencyCode"] as? String,
              let isAnonymized = dict["isAnonymized"] as? Bool,
              let lastUpdatedInterval = dict["lastUpdated"] as? TimeInterval else {
            print("WIDGET ERROR: [WidgetDataHelper] Failed to deserialize widget data - missing or invalid fields")
            return nil
        }
        
        let currentValue = Decimal(currentValueDouble)
        let historicalValues = historicalValuesArray.compactMap { item -> (Date, Decimal)? in
            guard let dateInterval = item["date"] as? TimeInterval,
                  let valueDouble = item["value"] as? Double else {
                return nil
            }
            return (Date(timeIntervalSince1970: dateInterval), Decimal(valueDouble))
        }
        
        return NetWorthData(
            currentValue: currentValue,
            historicalValues: historicalValues,
            currencyCode: currencyCode,
            isAnonymized: isAnonymized,
            lastUpdated: Date(timeIntervalSince1970: lastUpdatedInterval)
        )
    }
}

struct NetWorthEntry: TimelineEntry {
    let date: Date
    let currentValue: Decimal
    let historicalValues: [(Date, Decimal)]
    let currencyCode: String
    let isAnonymized: Bool
    let change: (percentage: Double, absolute: Decimal)?
}

struct NetWorthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NetWorthEntry {
        NetWorthEntry(
            date: Date(),
            currentValue: 100000,
            historicalValues: generateSampleData(),
            currencyCode: "USD",
            isAnonymized: false,
            change: (percentage: 5.2, absolute: 5000)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NetWorthEntry) -> Void) {
        let entry = loadNetWorthEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NetWorthEntry>) -> Void) {
        let entry = loadNetWorthEntry()
        
        // If no data found, check again in 5 minutes (handles cold start scenarios)
        // Otherwise update every hour
        let hasData = entry.currentValue > 0 || !entry.historicalValues.isEmpty
        let updateInterval: TimeInterval = hasData ? 3600 : 300 // 1 hour if data exists, 5 minutes if not
        let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadNetWorthEntry() -> NetWorthEntry {
        guard let data = WidgetDataHelper.loadNetWorthData() else {
            return NetWorthEntry(
                date: Date(),
                currentValue: 0,
                historicalValues: [],
                currencyCode: "USD",
                isAnonymized: false,
                change: nil
            )
        }
        
        // Calculate change
        let change: (percentage: Double, absolute: Decimal)? = {
            guard let firstValue = data.historicalValues.first?.1,
                  firstValue > 0 else { return nil }
            let absoluteChange = data.currentValue - firstValue
            let percentageChange = (absoluteChange / firstValue * 100)
            return (
                percentage: Double(truncating: percentageChange as NSDecimalNumber),
                absolute: absoluteChange
            )
        }()
        
        return NetWorthEntry(
            date: data.lastUpdated,
            currentValue: data.currentValue,
            historicalValues: data.historicalValues,
            currencyCode: data.currencyCode,
            isAnonymized: data.isAnonymized,
            change: change
        )
    }
    
    private func generateSampleData() -> [(Date, Decimal)] {
        let calendar = Calendar.current
        var data: [(Date, Decimal)] = []
        var value: Decimal = 95000
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -29 + i, to: Date()) {
                let randomChange = Decimal(Double.random(in: -500...2000))
                value += randomChange
                data.append((date, value))
            }
        }
        
        return data
    }
}

struct AssetaWidgetEntryView: View {
    var entry: NetWorthTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: NetWorthEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatCurrency(entry.currentValue))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if let change = entry.change {
                HStack(spacing: 4) {
                    Image(systemName: change.absolute >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(formatPercentage(change.percentage))
                        .font(.caption)
                }
                .foregroundColor(change.absolute >= 0 ? .green : .red)
            }
            
            Spacer()
            
            if !entry.historicalValues.isEmpty {
                MiniChartWidget(values: entry.historicalValues)
                    .frame(height: 40)
            } else if entry.currentValue > 0 {
                // Show a simple indicator when we have current value but no history
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(height: 40)
            } else {
                Text("Add assets in app")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: 40)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        if entry.isAnonymized {
            return "****.**"
        }
        
        let symbol = getCurrencySymbol(entry.currencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        let formattedNumber = formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
        return "\(formattedNumber) \(symbol)"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private func getCurrencySymbol(_ code: String) -> String {
        Currency.commonCurrencies.first(where: { $0.code == code })?.symbol ?? code
    }
}

struct MediumWidgetView: View {
    let entry: NetWorthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Net Worth")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(entry.currentValue))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let change = entry.change {
                    HStack(spacing: 4) {
                        Image(systemName: change.absolute >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(formatPercentage(change.percentage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(change.absolute >= 0 ? .green : .red)
                }
            }
            
            Spacer()
            
            if !entry.historicalValues.isEmpty {
                MiniChartWidget(values: entry.historicalValues)
                    .frame(width: 120, height: 60)
            } else if entry.currentValue > 0 {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("No history")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 60)
            } else {
                VStack {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Add assets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 60)
            }
        }
        .padding()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        if entry.isAnonymized {
            return "****.**"
        }
        
        let symbol = getCurrencySymbol(entry.currencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        let formattedNumber = formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
        return "\(formattedNumber) \(symbol)"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private func getCurrencySymbol(_ code: String) -> String {
        Currency.commonCurrencies.first(where: { $0.code == code })?.symbol ?? code
    }
}

struct LargeWidgetView: View {
    let entry: NetWorthEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Net Worth")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formatCurrency(entry.currentValue))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let change = entry.change {
                    HStack(spacing: 4) {
                        Image(systemName: change.absolute >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(formatPercentage(change.percentage))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(change.absolute >= 0 ? .green : .red)
                }
            }
            
            if !entry.historicalValues.isEmpty {
                MiniChartWidget(values: entry.historicalValues)
                    .frame(height: 80)
            } else if entry.currentValue > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No historical data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Add more values to see trends")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Open the app to add assets")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            }
        }
        .padding()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        if entry.isAnonymized {
            return "****.**"
        }
        
        let symbol = getCurrencySymbol(entry.currencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        let formattedNumber = formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
        return "\(formattedNumber) \(symbol)"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private func getCurrencySymbol(_ code: String) -> String {
        Currency.commonCurrencies.first(where: { $0.code == code })?.symbol ?? code
    }
}

struct MiniChartWidget: View {
    let values: [(Date, Decimal)]
    
    var body: some View {
        GeometryReader { geometry in
            if values.count <= 1 {
                // Draw a straight line
                Path { path in
                    let y = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.accentColor, lineWidth: 2)
            } else {
                // Draw a line chart
                let minValue = values.map { Double(truncating: $0.1 as NSDecimalNumber) }.min() ?? 0
                let maxValue = values.map { Double(truncating: $0.1 as NSDecimalNumber) }.max() ?? 1
                let range = max(maxValue - minValue, 1)
                
                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) / CGFloat(max(values.count - 1, 1)) * geometry.size.width
                        let normalizedValue = (Double(truncating: value.1 as NSDecimalNumber) - minValue) / range
                        let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

// Currency struct for widget
struct Currency: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let symbol: String
    
    static let commonCurrencies: [Currency] = [
        Currency(id: "USD", code: "USD", name: "US Dollar", symbol: "$"),
        Currency(id: "EUR", code: "EUR", name: "Euro", symbol: "€"),
        Currency(id: "GBP", code: "GBP", name: "British Pound", symbol: "£"),
        Currency(id: "JPY", code: "JPY", name: "Japanese Yen", symbol: "¥"),
        Currency(id: "CNY", code: "CNY", name: "Chinese Yuan", symbol: "¥"),
        Currency(id: "CAD", code: "CAD", name: "Canadian Dollar", symbol: "C$"),
        Currency(id: "AUD", code: "AUD", name: "Australian Dollar", symbol: "A$"),
        Currency(id: "CHF", code: "CHF", name: "Swiss Franc", symbol: "CHF"),
        Currency(id: "INR", code: "INR", name: "Indian Rupee", symbol: "₹"),
        Currency(id: "BRL", code: "BRL", name: "Brazilian Real", symbol: "R$"),
        Currency(id: "KRW", code: "KRW", name: "South Korean Won", symbol: "₩"),
        Currency(id: "MXN", code: "MXN", name: "Mexican Peso", symbol: "$"),
        Currency(id: "SGD", code: "SGD", name: "Singapore Dollar", symbol: "S$"),
        Currency(id: "HKD", code: "HKD", name: "Hong Kong Dollar", symbol: "HK$"),
        Currency(id: "NZD", code: "NZD", name: "New Zealand Dollar", symbol: "NZ$"),
    ]
}

struct AssetaWidget: Widget {
    let kind: String = "AssetaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetWorthTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                AssetaWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                AssetaWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Net Worth")
        .description("View your current net worth and growth over time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    AssetaWidget()
} timeline: {
    NetWorthEntry(
        date: Date(),
        currentValue: 100000,
        historicalValues: [
            (Date().addingTimeInterval(-86400 * 7), 95000),
            (Date().addingTimeInterval(-86400 * 5), 97000),
            (Date().addingTimeInterval(-86400 * 3), 98000),
            (Date(), 100000)
        ],
        currencyCode: "USD",
        isAnonymized: false,
        change: (percentage: 5.2, absolute: 5000)
    )
}
