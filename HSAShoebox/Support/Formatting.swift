import Foundation

enum Formatters {
    static func currencyString(for amount: Decimal, currencyCode: String) -> String {
        amount.formatted(
            .currency(code: currencyCode)
                .presentation(.standard)
                .precision(.fractionLength(2))
        )
    }

    static func monthYearString(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    static func dateString(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    static func sortableSectionDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}
