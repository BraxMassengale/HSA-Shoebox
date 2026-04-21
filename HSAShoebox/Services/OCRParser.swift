import Foundation

struct OCRParseResult: Equatable, Sendable {
    var merchant: String
    var amount: Decimal?
    var dateOfService: Date?
    var normalizedLines: [String]
}

struct OCRParser: Sendable {
    private let excludedMerchantHeaders: Set<String> = [
        "RECEIPT",
        "INVOICE",
        "CUSTOMER COPY",
        "MERCHANT COPY",
        "THANK YOU",
        "MEDICAL RECEIPT"
    ]

    private let keywordTokens = [
        "TOTAL",
        "AMOUNT DUE",
        "BALANCE DUE",
        "AMOUNT",
        "PAYMENT"
    ]

    func parse(lines: [String]) -> OCRParseResult {
        let normalizedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        return OCRParseResult(
            merchant: extractMerchant(from: normalizedLines),
            amount: extractAmount(from: normalizedLines),
            dateOfService: extractDate(from: normalizedLines),
            normalizedLines: normalizedLines
        )
    }

    func extractMerchant(from lines: [String]) -> String {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else { continue }
            guard trimmed.range(of: #"[A-Za-z]{3,}"#, options: .regularExpression) != nil else { continue }

            let normalized = trimmed
                .uppercased()
                .replacingOccurrences(of: "[^A-Z ]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            guard excludedMerchantHeaders.contains(normalized) == false else { continue }
            guard normalized.contains("TOTAL") == false else { continue }
            guard normalized.contains("AMOUNT") == false else { continue }
            guard normalized.contains("DATE") == false else { continue }

            return trimmed
        }

        return ""
    }

    func extractAmount(from lines: [String]) -> Decimal? {
        struct AmountCandidate: Comparable {
            let value: Decimal
            let lineIndex: Int
            let keywordDistance: Int

            static func < (lhs: AmountCandidate, rhs: AmountCandidate) -> Bool {
                if lhs.keywordDistance != rhs.keywordDistance {
                    return lhs.keywordDistance > rhs.keywordDistance
                }

                if lhs.value != rhs.value {
                    return lhs.value < rhs.value
                }

                return lhs.lineIndex > rhs.lineIndex
            }
        }

        let regex = try? NSRegularExpression(
            pattern: #"\$?\d{1,3}(?:,\d{3})*(?:\.\d{2})|\$?\d+(?:\.\d{2})"#,
            options: []
        )

        let keywordLines = lines.enumerated().compactMap { index, line -> Int? in
            let uppercased = line.uppercased()
            return keywordTokens.contains(where: uppercased.contains) ? index : nil
        }

        guard let regex else { return nil }

        let candidates: [AmountCandidate] = lines.enumerated().flatMap { index, line -> [AmountCandidate] in
            let nsRange = NSRange(line.startIndex..., in: line)

            return regex.matches(in: line, options: [], range: nsRange).compactMap { match -> AmountCandidate? in
                guard let range = Range(match.range, in: line) else { return nil }
                let raw = String(line[range])
                    .replacing(",", with: "")
                    .replacing("$", with: "")
                guard let value = Decimal(string: raw) else { return nil }

                let distance = keywordLines
                    .map { abs($0 - index) }
                    .min() ?? .max

                return AmountCandidate(value: value, lineIndex: index, keywordDistance: distance)
            }
        }

        if let nearbyBest = candidates
            .filter({ $0.keywordDistance <= 1 })
            .max() {
            return nearbyBest.value
        }

        return candidates.max()?.value
    }

    func extractDate(from lines: [String], timeZone: TimeZone = .current) -> Date? {
        let formats = [
            "MM/dd/yyyy",
            "M/d/yyyy",
            "MM/dd/yy",
            "M/d/yy",
            "MM-dd-yyyy",
            "M-d-yyyy",
            "MM-dd-yy",
            "M-d-yy",
            "MMMM d, yyyy",
            "MMM d, yyyy",
            "MMMM d yyyy",
            "MMM d yyyy"
        ]

        let patterns = [
            #"\b\d{1,2}/\d{1,2}/\d{2,4}\b"#,
            #"\b\d{1,2}-\d{1,2}-\d{2,4}\b"#,
            #"\b(?:Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|Sept|September|Oct|October|Nov|November|Dec|December)\.?\s+\d{1,2},?\s+\d{2,4}\b"#
        ]

        for line in lines {
            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let nsRange = NSRange(line.startIndex..., in: line)
                guard let match = regex.firstMatch(in: line, options: [], range: nsRange),
                      let range = Range(match.range, in: line) else {
                    continue
                }

                let candidate = String(line[range]).replacingOccurrences(of: ".", with: "")

                for format in formats {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = timeZone
                    formatter.dateFormat = format
                    if let date = formatter.date(from: candidate) {
                        return Calendar.current.startOfDay(for: date)
                    }
                }
            }
        }

        return nil
    }
}
