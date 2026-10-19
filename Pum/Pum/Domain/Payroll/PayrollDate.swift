// DEC-029 · DEC-031 — 월급 계산 모듈: 날짜(Asia/Seoul 기준 연월일)
// 계산 안에서는 시간대 없이 「서울 달력의 날짜」만 다룬다. Date 변환은 진입점 한 곳(init(seoul:))에서만.
import Foundation

/// 요일(ISO: 월요일 = 1 … 일요일 = 7). 주는 월요일에 시작해 일요일에 끝난다.
nonisolated enum PayrollWeekday: Int, CaseIterable, Comparable, Sendable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var koreanShort: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }
}

/// Asia/Seoul 달력의 연 · 월 · 일. 시간대 계산 없이 날짜 산술만 한다(그레고리력).
nonisolated struct PayrollDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// 순간(Date)을 서울 기준 날짜로 바꾼다.
    init(seoul date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = PayrollDate.seoul
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    static let seoul = TimeZone(identifier: "Asia/Seoul")!

    /// 1970-01-01부터 지난 날 수(그레고리력, Howard Hinnant days_from_civil).
    var dayNumber: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }

    init(dayNumber z0: Int) {
        let z = z0 + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        self.init(yoe + era * 400 + (m <= 2 ? 1 : 0), m, d)
    }

    func adding(days: Int) -> PayrollDate { PayrollDate(dayNumber: dayNumber + days) }

    /// 1970-01-01은 목요일.
    var weekday: PayrollWeekday {
        let mondayBased = ((dayNumber + 3) % 7 + 7) % 7 // 0 = 월요일
        return PayrollWeekday(rawValue: mondayBased + 1)!
    }

    /// 이 날이 속한 주(월–일)의 월요일.
    var weekMonday: PayrollDate { adding(days: -(weekday.rawValue - 1)) }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.dayNumber < rhs.dayNumber }

    var description: String { "\(year)-\(month)-\(day)" }

    /// 「10월 5일(월)」
    var koreanLabel: String { "\(month)월 \(day)일(\(weekday.koreanShort))" }
}

/// 급여 기간: 한 달(1일–말일).
nonisolated struct PayrollPeriod: Hashable, Sendable {
    let year: Int
    let month: Int

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    var firstDay: PayrollDate { PayrollDate(year, month, 1) }

    var lastDay: PayrollDate {
        let next = month == 12 ? PayrollDate(year + 1, 1, 1) : PayrollDate(year, month + 1, 1)
        return next.adding(days: -1)
    }

    func contains(_ date: PayrollDate) -> Bool { date >= firstDay && date <= lastDay }

    /// 기간과 하루라도 겹치는 주(월–일)의 월요일 목록, 오래된 순.
    var overlappingWeekMondays: [PayrollDate] {
        var result: [PayrollDate] = []
        var monday = firstDay.weekMonday
        while monday <= lastDay {
            result.append(monday)
            monday = monday.adding(days: 7)
        }
        return result
    }
}
