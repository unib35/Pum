// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 직원의 하루 근무. 날짜는 `SeoulDayKey`(Asia/Seoul).
/// 시각은 그날 0시부터의 분. 자정을 넘기면 끝이 1440보다 크다(예: 22:00–02:00 = 1320–1560).
/// unique 제약을 쓸 수 없으므로 (직원, 날짜)당 한 건 규칙은 Repository가 지킨다.
@Model
final class WorkDay {
    enum Status: String, CaseIterable, Codable {
        /// 근로조건대로(자동 채움).
        case scheduled
        /// 시간을 고친 날.
        case edited
        /// 결근.
        case absent
        /// 근로조건에 없는 추가 근무.
        case extra
    }

    var dayKey: Int = 0
    var statusRaw: String = Status.scheduled.rawValue
    var startMinute: Int = 0
    var endMinute: Int = 0
    var breakMinutes: Int = 0
    var isHolidayWork: Bool = false
    var reason: String = ""
    /// 사용자가 고친 시각(자동 채움이면 nil).
    var editedAt: Date?

    var employee: Employee?

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    init(dayKey: Int, status: Status, startMinute: Int, endMinute: Int, breakMinutes: Int,
         isHolidayWork: Bool = false, reason: String = "", editedAt: Date? = nil) {
        self.dayKey = dayKey
        self.statusRaw = status.rawValue
        self.startMinute = startMinute
        self.endMinute = WorkDay.normalizedEnd(start: startMinute, end: endMinute)
        self.breakMinutes = breakMinutes
        self.isHolidayWork = isHolidayWork
        self.reason = reason
        self.editedAt = editedAt
    }

    /// 끝이 시작보다 작거나 같으면 다음 날로 넘긴다(+1440). 시작 == 끝 == 0은 근무 없음(결근 등)으로 둔다.
    static func normalizedEnd(start: Int, end: Int) -> Int {
        if start == 0 && end == 0 { return 0 }
        return end <= start ? end + 1440 : end
    }
}
