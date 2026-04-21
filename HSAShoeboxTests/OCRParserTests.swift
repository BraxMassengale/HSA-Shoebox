import Foundation
import Testing
@testable import HSAShoebox

struct OCRParserTests {
    private let parser = OCRParser()

    @Test
    func extractsMerchantFromFirstMeaningfulLine() {
        let lines = ["RECEIPT", "", "City Health Clinic", "123 Main Street"]

        #expect(parser.extractMerchant(from: lines) == "City Health Clinic")
    }

    @Test
    func extractsLargestTotalNearKeyword() {
        let lines = [
            "Subtotal 18.44",
            "Tax 1.22",
            "TOTAL $19.66",
            "Balance 19.66"
        ]

        #expect(parser.extractAmount(from: lines) == Decimal(string: "19.66"))
    }

    @Test
    func extractsUSDateFormats() {
        let lines = [
            "Service Date 03/14/2026",
            "Thank you"
        ]

        let expected = Calendar.current.startOfDay(for: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14))!)
        #expect(parser.extractDate(from: lines) == expected)
    }
}
