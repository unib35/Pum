// DEC-031 — 금액 반올림 · 절사 규칙은 이 파일 한 곳에만 둔다(docs/mvp/payroll-rules.md · PayrollRoundingTests로 고정).
import Foundation

nonisolated enum PayrollRounding {
    /// 항목별 금액: numerator ÷ denominator를 원 미만 반올림(0.5원은 올림). 음수는 0으로 본다.
    /// 부동소수점 없이 정수로만 계산한다.
    static func won(_ numerator: Int, over denominator: Int) -> Int {
        precondition(denominator > 0)
        guard numerator > 0 else { return 0 }
        return (numerator * 2 + denominator) / (denominator * 2)
    }

    /// 원천징수 세액: 10원 미만 절사.
    static func truncateToTen(_ amount: Int) -> Int {
        guard amount > 0 else { return 0 }
        return amount / 10 * 10
    }
}

/// 계산 근거 문장에 쓰는 표기(로캘에 의존하지 않는다).
nonisolated enum PayrollText {
    /// 1234567 → "1,234,567원"
    static func won(_ amount: Int) -> String { grouped(amount) + "원" }

    static func grouped(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return value < 0 ? "-" + out : out
    }

    /// 4950 → "82시간 30분", 480 → "8시간", 30 → "30분", 0 → "0분"
    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m)분"
        case (_, 0): return "\(h)시간"
        default: return "\(h)시간 \(m)분"
        }
    }
}
