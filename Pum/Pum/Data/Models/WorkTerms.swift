// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 직원별 근로조건 이력 한 건. 조건이 바뀌면 고치지 않고 새 적용 시작일로 한 건 더 만든다.
/// 시각은 0시부터의 분(예: 09:00 = 540). 끝이 시작보다 작거나 같으면 자정을 넘긴 것으로 본다.
@Model
final class WorkTerms {
    enum WageType: String, CaseIterable, Codable {
        case hourly
        case monthly
    }

    var effectiveFromDayKey: Int = 0
    var wageTypeRaw: String = WageType.hourly.rawValue
    /// 시급 또는 월급(원, 정수).
    var amount: Int = 0
    /// 근무 요일(ISO 1 = 월 … 7 = 일). 저장은 정렬된 배열.
    var workWeekdaysRaw: [Int] = []
    var startMinute: Int = 0
    var endMinute: Int = 0
    var breakMinutes: Int = 0
    /// 주휴일 요일(ISO). 기본 일요일.
    var weeklyHolidayWeekday: Int = 7
    var createdAt: Date = Date.now

    var employee: Employee?

    var wageType: WageType {
        get { WageType(rawValue: wageTypeRaw) ?? .hourly }
        set { wageTypeRaw = newValue.rawValue }
    }

    var workWeekdays: Set<Int> {
        get { Set(workWeekdaysRaw) }
        set { workWeekdaysRaw = WorkTerms.sortedWeekdays(newValue) }
    }

    init(effectiveFromDayKey: Int, wageType: WageType, amount: Int, workWeekdays: Set<Int>,
         startMinute: Int, endMinute: Int, breakMinutes: Int, weeklyHolidayWeekday: Int = 7,
         createdAt: Date = .now) {
        self.effectiveFromDayKey = effectiveFromDayKey
        self.wageTypeRaw = wageType.rawValue
        self.amount = amount
        self.workWeekdaysRaw = WorkTerms.sortedWeekdays(workWeekdays)
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.breakMinutes = breakMinutes
        self.weeklyHolidayWeekday = weeklyHolidayWeekday
        self.createdAt = createdAt
    }

    static func sortedWeekdays(_ days: Set<Int>) -> [Int] {
        days.filter { (1...7).contains($0) }.sorted()
    }
}

/// 근로조건 이력에서 날짜에 맞는 것 고르기(순수 함수).
enum WorkTermsPicker {
    /// 적용 시작일 ≤ 날짜 중 가장 늦은 것. 시작일이 같으면 목록에서 뒤에 있는 것.
    static func pick<T>(_ items: [T], on dayKey: Int, effectiveFrom: (T) -> Int) -> T? {
        var best: T?
        var bestKey = Int.min
        for item in items {
            let key = effectiveFrom(item)
            if key <= dayKey && key >= bestKey {
                best = item
                bestKey = key
            }
        }
        return best
    }
}
