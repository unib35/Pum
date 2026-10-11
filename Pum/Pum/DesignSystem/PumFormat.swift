// F4 Numbers — 금액은 정수(원), 콤마 묶음, 공제는 빨간 U+2212, 시간 범위는 en dash, 길이는 「N시간 NN분」
import Foundation

nonisolated enum PumFormat {
    private static let grouping: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ko_KR")
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return f
    }()

    /// 1188000 → "1,188,000". 단위 「원」은 화면에서 숫자보다 작게 따로 붙인다. `+`는 붙이지 않는다.
    static func amount(_ won: Int) -> String {
        grouping.string(from: NSNumber(value: abs(won))).map { won < 0 ? "\u{2212}" + $0 : $0 } ?? "\(won)"
    }

    /// 공제 금액: 항상 U+2212 마이너스.
    static func deduction(_ won: Int) -> String {
        "\u{2212}" + amount(abs(won))
    }

    /// 303분 → "5시간 03분", 45분 → "45분"
    static func duration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return h == 0 ? "\(m)분" : String(format: "%d시간 %02d분", h, m)
    }

    /// "17:00 – 22:00" (en dash, 앞뒤 공백)
    static func timeRange(_ start: String, _ end: String) -> String {
        "\(start) \u{2013} \(end)"
    }
}
