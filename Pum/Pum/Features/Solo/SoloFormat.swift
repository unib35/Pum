import Foundation

/// MVP 화면 문구 — 저장 값(분 · 날짜 키 · 요일 번호)을 디자인 표기로 바꾼다.
enum SoloFormat {
    private static let weekdayNames = ["월", "화", "수", "목", "금", "토", "일"]

    /// [1, 3, 5] → 「월·수·금」, 3일 이상 이어지면 [1…5] → 「월–금」
    static func weekdays(_ days: Set<Int>) -> String {
        let sorted = days.filter { (1...7).contains($0) }.sorted()
        guard let first = sorted.first, let last = sorted.last else { return "" }
        if sorted.count >= 3 && last - first + 1 == sorted.count {
            return "\(weekdayNames[first - 1])\u{2013}\(weekdayNames[last - 1])"
        }
        return sorted.map { weekdayNames[$0 - 1] }.joined(separator: "\u{00B7}")
    }

    /// 1020 → 「17」, 570 → 「09:30」, 1560(다음 날 02:00) → 「02」
    static func hourMark(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        return m % 60 == 0 ? String(format: "%02d", m / 60) : String(format: "%02d:%02d", m / 60, m % 60)
    }

    /// 「17–22」
    static func hours(start: Int, end: Int) -> String { "\(hourMark(start))\u{2013}\(hourMark(end))" }

    /// 1020 → 「17:00」
    static func clock(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    /// 「휴게 30분 · 하루 4시간 30분」
    static func breakAndDuration(start: Int, end: Int, breakMinutes: Int) -> String {
        let span = end > start ? end - start : end + 1440 - start
        let work = max(span - breakMinutes, 0)
        let rest = breakMinutes == 0 ? "휴게 없음" : "휴게 \(duration(breakMinutes))"
        return "\(rest) \u{00B7} 하루 \(duration(work))"
    }

    /// 270 → 「4시간 30분」
    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)분" }
        return m == 0 ? "\(h)시간" : "\(h)시간 \(m)분"
    }

    /// 20260701 → 「2026. 7. 1 수」
    static func date(_ key: Int) -> String {
        let weekday = SeoulDayKey.weekday(key)
        let name = (1...7).contains(weekday) ? " \(weekdayNames[weekday - 1])" : ""
        return "\(SeoulDayKey.year(key)). \(SeoulDayKey.month(key)). \(SeoulDayKey.day(key))\(name)"
    }
}

/// 최저임금(원, 시간당). 고시가 나오면 해를 더한다.
enum MinimumWage {
    static let table: [Int: Int] = [2025: 10_030, 2026: 10_320]

    static func hourly(year: Int) -> Int {
        table[year] ?? table[table.keys.filter { $0 <= year }.max() ?? 2026] ?? 10_320
    }
}
