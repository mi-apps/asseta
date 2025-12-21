//
//  AnalyticsHelper.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation

struct AnalyticsHelper {
    static func aggregateByPeriod(
        values: [(Date, Decimal)],
        period: Period,
        calendar: Calendar = .current
    ) -> [(Date, Decimal)] {
        // If empty, create a placeholder flat line at 0 for the current period
        guard !values.isEmpty else {
            if let dateRange = getDateRange(for: period, calendar: calendar) {
                // Create a flat line at 0 from period start to end
                return [
                    (dateRange.start, 0),
                    (dateRange.end, 0)
                ]
            } else {
                // For allTime, create a simple placeholder
                let today = Date()
                let todayStart = calendar.startOfDay(for: today)
                if let pastDate = calendar.date(byAdding: .day, value: -7, to: todayStart) {
                    return [(pastDate, 0), (todayStart, 0)]
                }
                return [(todayStart, 0)]
            }
        }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        
        // Filter by time range first (for week/month/year), then aggregate
        let filtered: [(Date, Decimal)]
        switch period {
        case .week, .month, .year:
            // Filter to current period (current week, month, or year)
            if let dateRange = getDateRange(for: period, calendar: calendar) {
                let tempFiltered = sorted.filter { $0.0 >= dateRange.start && $0.0 <= dateRange.end }
                // If filtering results in empty, use the latest data at that point in time (forward fill)
                if tempFiltered.isEmpty {
                    // Find the latest value before or at period end
                    let valuesBeforePeriodEnd = sorted.filter { $0.0 <= dateRange.end }
                    if let latestValue = valuesBeforePeriodEnd.last {
                        // Create a flat line from period start to end with the latest value
                        filtered = [
                            (dateRange.start, latestValue.1),
                            (dateRange.end, latestValue.1)
                        ]
                    } else {
                        // No data at all, return empty
                        filtered = []
                    }
                } else {
                    filtered = tempFiltered
                }
            } else {
                filtered = sorted
            }
        case .allTime:
            // Show all data
            filtered = sorted
        }
        
        // If only one data point after filtering, create a horizontal line (no change)
        if filtered.count == 1 {
            if let dateRange = getDateRange(for: period, calendar: calendar) {
                let singleValue = filtered.first!
                // Create flat line from period start to end
                return [
                    (dateRange.start, singleValue.1),
                    (dateRange.end, singleValue.1)
                ]
            } else {
                // For allTime, use the existing flat line logic
                return createFlatLineForSingleValue(value: filtered.first!, period: period, calendar: calendar)
            }
        }
        
        // Forward fill the filtered data
        let forwardFilled = forwardFillValues(values: filtered, calendar: calendar)
        
        let aggregated: [(Date, Decimal)]
        switch period {
        case .week:
            // Show daily data for the last week
            aggregated = forwardFilled
            
        case .month:
            // Show weekly bins for the last month, but if we have few points, show daily
            if forwardFilled.count <= 7 {
                aggregated = forwardFilled
            } else {
                aggregated = aggregateByWeek(values: forwardFilled, calendar: calendar)
            }
            
        case .year:
            // Show monthly bins for the last year, but if we have few points, show weekly or daily
            if forwardFilled.count <= 7 {
                aggregated = forwardFilled
            } else if forwardFilled.count <= 30 {
                aggregated = aggregateByWeek(values: forwardFilled, calendar: calendar)
            } else {
                aggregated = aggregateByMonth(values: forwardFilled, calendar: calendar)
            }
            
        case .allTime:
            // Auto-select best bin size based on data span
            aggregated = aggregateForAllTime(values: forwardFilled, calendar: calendar)
        }
        
        // Always limit to 5 points for clean X-axis, but ensure we include actual data points
        // Use original sorted data (before filtering) to ensure we include actual data points
        return limitToFivePointsWithActualData(values: aggregated, originalData: sorted, calendar: calendar)
    }
    
    private static func createFlatLineForSingleValue(
        value: (Date, Decimal),
        period: Period,
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        let (date, amount) = value
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        let valueDate = calendar.startOfDay(for: date)
        
        var result: [(Date, Decimal)] = []
        
        // Determine range based on period
        let daysBack: Int
        let daysForward: Int
        
        switch period {
        case .week:
            daysBack = 14 // 2 weeks back
            daysForward = 7 // 1 week forward
        case .month:
            daysBack = 60 // ~2 months back
            daysForward = 30 // ~1 month forward
        case .year:
            daysBack = 180 // ~6 months back
            daysForward = 180 // ~6 months forward
        case .allTime:
            daysBack = 30
            daysForward = 30
        }
        
        // Add past point
        if let pastDate = calendar.date(byAdding: .day, value: -daysBack, to: valueDate) {
            result.append((pastDate, amount))
        }
        
        // Add the actual value point
        result.append((valueDate, amount))
        
        // Add future point (today or value date + forward days, whichever is later)
        let futureDate = max(todayStart, calendar.date(byAdding: .day, value: daysForward, to: valueDate) ?? todayStart)
        result.append((futureDate, amount))
        
        return result
    }
    
    private static func forwardFillValues(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        
        // Forward fill: each value persists until the next value
        // This is already handled by the binning logic, so we just return sorted values
        // The binning functions will use the latest value at or before each bin's end date
        return sorted
    }
    
    private static func aggregateByWeek(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let firstDate = sorted.first?.0, let lastDate = sorted.last?.0 else { return values }
        
        // Get the week intervals for the first and last dates
        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: firstDate),
              let lastWeek = calendar.dateInterval(of: .weekOfYear, for: lastDate) else {
            return values
        }
        
        // Create bins for all weeks in the range
        var weekBins: [(Date, Decimal)] = []
        var currentWeekStart = firstWeek.start
        var lastKnownValue: Decimal = sorted.first!.1
        
        // For each week in the range, find the latest value at or before the end of that week
        while currentWeekStart <= lastWeek.end {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeekStart) else {
                break
            }
            let weekEnd = weekInterval.end
            
            // Find the latest value at or before the end of this week (forward fill)
            let valuesInWeek = sorted.filter { $0.0 <= weekEnd }
            if let latestValue = valuesInWeek.last {
                lastKnownValue = latestValue.1
            }
            // Always add a bin, using the latest known value (forward filling)
            weekBins.append((weekEnd, lastKnownValue))
            
            // Move to next week
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = nextWeek
        }
        
        // Return sorted by date
        return weekBins.sorted { $0.0 < $1.0 }
    }
    
    private static func aggregateByMonth(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let firstDate = sorted.first?.0, let lastDate = sorted.last?.0 else { return values }
        
        // Get the month intervals for the first and last dates
        guard let firstMonth = calendar.dateInterval(of: .month, for: firstDate),
              let lastMonth = calendar.dateInterval(of: .month, for: lastDate) else {
            return values
        }
        
        // Create bins for all months in the range
        var monthBins: [(Date, Decimal)] = []
        var currentMonthStart = firstMonth.start
        var lastKnownValue: Decimal = sorted.first!.1
        
        // For each month in the range, find the latest value at or before the end of that month
        while currentMonthStart <= lastMonth.end {
            guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthStart) else {
                break
            }
            let monthEnd = monthInterval.end
            
            // Find the latest value at or before the end of this month (forward fill)
            let valuesInMonth = sorted.filter { $0.0 <= monthEnd }
            if let latestValue = valuesInMonth.last {
                lastKnownValue = latestValue.1
            }
            // Always add a bin, using the latest known value (forward filling)
            monthBins.append((monthEnd, lastKnownValue))
            
            // Move to next month
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonthStart) else {
                break
            }
            currentMonthStart = nextMonth
        }
        
        // Return sorted by date
        return monthBins.sorted { $0.0 < $1.0 }
    }
    
    private static func aggregateByYear(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let firstDate = sorted.first?.0, let lastDate = sorted.last?.0 else { return values }
        
        // Get the year intervals for the first and last dates
        guard let firstYear = calendar.dateInterval(of: .year, for: firstDate),
              let lastYear = calendar.dateInterval(of: .year, for: lastDate) else {
            return values
        }
        
        // Create bins for all years in the range
        var yearBins: [(Date, Decimal)] = []
        var currentYearStart = firstYear.start
        var lastKnownValue: Decimal = sorted.first!.1
        
        // For each year in the range, find the latest value at or before the end of that year
        while currentYearStart <= lastYear.end {
            guard let yearInterval = calendar.dateInterval(of: .year, for: currentYearStart) else {
                break
            }
            let yearEnd = yearInterval.end
            
            // Find the latest value at or before the end of this year (forward fill)
            let valuesInYear = sorted.filter { $0.0 <= yearEnd }
            if let latestValue = valuesInYear.last {
                lastKnownValue = latestValue.1
            }
            // Always add a bin, using the latest known value (forward filling)
            yearBins.append((yearEnd, lastKnownValue))
            
            // Move to next year
            guard let nextYear = calendar.date(byAdding: .year, value: 1, to: currentYearStart) else {
                break
            }
            currentYearStart = nextYear
        }
        
        // Return sorted by date
        return yearBins.sorted { $0.0 < $1.0 }
    }
    
    static func aggregateForAllTime(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let first = sorted.first, let last = sorted.last else { return values }
        
        let daysDiff = calendar.dateComponents([.day], from: first.0, to: last.0).day ?? 0
        let dataPointCount = sorted.count
        
        // Check if all data points are in the same month
        let firstYear = calendar.component(.year, from: first.0)
        let firstMonth = calendar.component(.month, from: first.0)
        let lastYear = calendar.component(.year, from: last.0)
        let lastMonth = calendar.component(.month, from: last.0)
        let allInSameMonth = (firstYear == lastYear && firstMonth == lastMonth)
        
        // Choose bin size based on data span and density to avoid too many overlapping points
        // Target: ~30-50 points for good visualization
        
        if allInSameMonth {
            // If all data is in the same month, use weekly bins for better visualization
            return aggregateByWeek(values: sorted, calendar: calendar)
        } else if daysDiff < 30 {
            // Less than 30 days (but different months): show daily, but sample if too many points
            if dataPointCount > 50 {
                return sampleValues(values: sorted, maxCount: 50)
            }
            return sorted
        } else if daysDiff < 90 {
            // 30-90 days: aggregate by week (should give ~4-13 points)
            return aggregateByWeek(values: sorted, calendar: calendar)
        } else if daysDiff < 365 {
            // 90-365 days: aggregate by week or month depending on density
            let weeklyBins = aggregateByWeek(values: sorted, calendar: calendar)
            if weeklyBins.count > 50 {
                // Too many weekly bins, use monthly instead
                return aggregateByMonth(values: sorted, calendar: calendar)
            }
            return weeklyBins
        } else if daysDiff < 1825 { // ~5 years
            // 1-5 years: aggregate by month (should give ~12-60 points)
            let monthlyBins = aggregateByMonth(values: sorted, calendar: calendar)
            if monthlyBins.count > 60 {
                // Too many monthly bins, use quarterly or sample
                return aggregateByQuarter(values: sorted, calendar: calendar)
            }
            return monthlyBins
        } else {
            // More than 5 years: aggregate by year (should give reasonable number)
            let yearlyBins = aggregateByYear(values: sorted, calendar: calendar)
            if yearlyBins.count > 50 {
                // Too many years, sample them
                return sampleValues(values: yearlyBins, maxCount: 50)
            }
            return yearlyBins
        }
    }
    
    private static func aggregateByQuarter(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let firstDate = sorted.first?.0, let lastDate = sorted.last?.0 else { return values }
        
        // Create bins for all quarters in the range
        var quarterBins: [Date: Decimal] = [:]
        var currentDate = firstDate
        
        while currentDate <= lastDate {
            // Get the quarter for current date
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3
            let quarterEndMonth = (quarter + 1) * 3
            
            // Calculate quarter end date
            guard let quarterEndDate = calendar.date(from: DateComponents(year: year, month: quarterEndMonth, day: 1)) else {
                break
            }
            guard let actualQuarterEnd = calendar.date(byAdding: .day, value: -1, to: quarterEndDate) else {
                break
            }
            
            // Find the latest value at or before the end of this quarter
            let valuesInQuarter = sorted.filter { $0.0 <= actualQuarterEnd }
            if let latestValue = valuesInQuarter.last {
                quarterBins[actualQuarterEnd] = latestValue.1
            }
            
            // Move to next quarter
            guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: currentDate) else {
                break
            }
            currentDate = nextQuarterStart
        }
        
        // Convert to sorted array
        return quarterBins.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    private static func limitToFivePointsWithActualData(
        values: [(Date, Decimal)],
        originalData: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        guard !values.isEmpty else { return values }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        let originalSorted = originalData.sorted { $0.0 < $1.0 }
        
        // If we have 5 or fewer points, return all
        if sorted.count <= 5 {
            return sorted
        }
        
        // Always include the first and last actual data points from original data
        var result: [(Date, Decimal)] = []
        if let firstOriginal = originalSorted.first {
            // Find the aggregated value for the first original date
            let valuesAtOrBefore = sorted.filter { $0.0 <= firstOriginal.0 }
            if let value = valuesAtOrBefore.last {
                result.append((firstOriginal.0, value.1))
            }
        }
        
        if let lastOriginal = originalSorted.last {
            // Find the aggregated value for the last original date
            let valuesAtOrBefore = sorted.filter { $0.0 <= lastOriginal.0 }
            if let value = valuesAtOrBefore.last {
                result.append((lastOriginal.0, value.1))
            }
        }
        
        // Get the date range
        guard let firstDate = sorted.first?.0, let lastDate = sorted.last?.0 else { return values }
        let startDate = calendar.startOfDay(for: firstDate)
        let endDate = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        if daysDiff <= 1 {
            return sorted
        }
        
        // Pick 3 more evenly spaced points between first and last
        let targetCount = 5
        let remainingSlots = targetCount - result.count
        if remainingSlots > 0 && daysDiff > 0 {
            for i in 1..<remainingSlots + 1 {
                let daysFromStart = (daysDiff * i) / (remainingSlots + 1)
                if let date = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) {
                    // Find the latest value at or before this date
                    let valuesBeforeDate = sorted.filter { $0.0 <= date }
                    if let latestValue = valuesBeforeDate.last {
                        let dateKey = calendar.startOfDay(for: date)
                        // Only add if not already included
                        if !result.contains(where: { calendar.startOfDay(for: $0.0) == dateKey }) {
                            result.append((date, latestValue.1))
                        }
                    }
                }
            }
        }
        
        // Sort and remove duplicates
        var uniqueResults: [(Date, Decimal)] = []
        var seenDates: Set<Date> = []
        for (date, value) in result.sorted(by: { $0.0 < $1.0 }) {
            let dateKey = calendar.startOfDay(for: date)
            if !seenDates.contains(dateKey) {
                seenDates.insert(dateKey)
                uniqueResults.append((date, value))
            }
        }
        
        // Ensure we have at least the first and last points
        if uniqueResults.count < 2 && !sorted.isEmpty {
            return [sorted.first!, sorted.last!]
        }
        
        return uniqueResults
    }
    
    private static func limitToFivePoints(
        values: [(Date, Decimal)],
        calendar: Calendar
    ) -> [(Date, Decimal)] {
        // Legacy function for backwards compatibility
        return limitToFivePointsWithActualData(values: values, originalData: values, calendar: calendar)
    }
    
    private static func sampleValues(
        values: [(Date, Decimal)],
        maxCount: Int
    ) -> [(Date, Decimal)] {
        guard values.count > maxCount else { return values }
        
        let step = values.count / maxCount
        var sampled: [(Date, Decimal)] = []
        
        for i in stride(from: 0, to: values.count, by: step) {
            sampled.append(values[i])
        }
        
        // Always include the last value
        if let last = values.last, sampled.last?.0 != last.0 {
            sampled.append(last)
        }
        
        return sampled
    }
    
    static func calculatePeriodChange(
        values: [(Date, Decimal)],
        period: Period,
        calendar: Calendar = .current
    ) -> (absolute: Decimal, percentage: Double, startValue: Decimal, endValue: Decimal)? {
        guard !values.isEmpty else { return nil }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let firstValue = sorted.first, let lastValue = sorted.last else { return nil }
        
        let startValue = firstValue.1
        let endValue = lastValue.1
        
        guard startValue > 0 else { return nil }
        
        let absolute = endValue - startValue
        let percentage = (absolute / startValue * 100)
        let percentageDouble = Double(truncating: percentage as NSDecimalNumber)
        
        return (absolute, percentageDouble, startValue, endValue)
    }
    
    static func calculateAssetAllocation(assets: [Asset], totalNetWorth: Decimal) -> [(Asset, Double)] {
        guard totalNetWorth > 0 else { return [] }
        
        return assets.compactMap { asset in
            guard let value = asset.currentValue, value > 0 else { return nil }
            let percentage = Double(truncating: (value / totalNetWorth * 100) as NSDecimalNumber)
            return (asset, percentage)
        }.sorted { $0.1 > $1.1 }
    }
    
    static func formatPlainLanguageChange(
        absolute: Decimal,
        percentage: Double,
        period: Period,
        currencyFormatter: (Decimal) -> String
    ) -> String {
        let absValue = abs(absolute)
        let formattedAmount = currencyFormatter(absValue)
        
        if absolute >= 0 {
            return "Up \(formattedAmount) this \(period.rawValue.lowercased())"
        } else {
            return "Down \(formattedAmount) this \(period.rawValue.lowercased())"
        }
    }
    
    static func formatPlainLanguagePercentage(
        percentage: Double,
        period: Period
    ) -> String {
        let absPercent = abs(percentage)
        let sign = percentage >= 0 ? "Up" : "Down"
        return "\(sign) \(String(format: "%.1f", absPercent))% this \(period.rawValue.lowercased())"
    }
    
    static func autoSelectPeriod(values: [(Date, Decimal)]) -> Period {
        guard !values.isEmpty else { return .month }
        
        let sorted = values.sorted { $0.0 < $1.0 }
        guard let first = sorted.first, let last = sorted.last else { return .month }
        
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: first.0, to: last.0).day ?? 0
        
        if daysDiff < 30 {
            return .week
        } else if daysDiff < 365 {
            return .month
        } else {
            return .year
        }
    }
    
    static func getDateRange(for period: Period, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        let now = Date()
        
        switch period {
        case .week:
            // Current week (start of this week to now)
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
            return (weekInterval.start, now)
            
        case .month:
            // Current month (start of this month to now)
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return (monthInterval.start, now)
            
        case .year:
            // Current year (start of this year to now)
            guard let yearInterval = calendar.dateInterval(of: .year, for: now) else { return nil }
            return (yearInterval.start, now)
            
        case .allTime:
            // Return nil to indicate all time (no filtering)
            return nil
        }
    }
}

