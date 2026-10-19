// CloudKit 호환: 날짜는 시간대 없는 yyyyMMdd 정수로 저장한다(기기 시간대가 바뀌어도 날짜가 밀리지 않게). 기준 시간대는 Asia/Seoul.
import Foundation

/// 날짜 키(yyyyMMdd 정수) 도우미. 모든 계산은 Asia/Seoul 그레고리력 기준.
/// 요일 번호는 ISO 방식: 1 = 월요일 … 7 = 일요일.
enum SeoulDayKey {
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// 연 · 월 · 일로 키를 만든다. 예) 2026, 2, 28 → 20260228
    static func make(year: Int, month: Int, day: Int) -> Int {
        year * 10_000 + month * 100 + day
    }

    static func year(_ key: Int) -> Int { key / 10_000 }
    static func month(_ key: Int) -> Int { (key / 100) % 100 }
    static func day(_ key: Int) -> Int { key % 100 }

    /// 서울 시간 기준 그 순간의 날짜 키.
    static func from(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return make(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    /// 서울 시간 기준 그 날짜의 0시.
    static func date(_ key: Int) -> Date? {
        calendar.date(from: DateComponents(year: year(key), month: month(key), day: day(key)))
    }

    /// 그 달의 날 수(윤년 2월 포함).
    static func daysInMonth(year: Int, month: Int) -> Int {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else { return 0 }
        return range.count
    }

    /// 그 달의 모든 날짜 키(1일부터 말일까지).
    static func keys(year: Int, month: Int) -> [Int] {
        (1...max(daysInMonth(year: year, month: month), 1)).map { make(year: year, month: month, day: $0) }
    }

    /// 그 달 키의 범위(조회용). 예) 2026년 2월 → 20260201...20260231
    static func monthRange(year: Int, month: Int) -> ClosedRange<Int> {
        make(year: year, month: month, day: 1)...make(year: year, month: month, day: 31)
    }

    /// ISO 요일(1 = 월 … 7 = 일).
    static func weekday(_ key: Int) -> Int {
        guard let date = date(key) else { return 0 }
        let gregorian = calendar.component(.weekday, from: date) // 1 = 일 … 7 = 토
        return (gregorian + 5) % 7 + 1
    }
}
