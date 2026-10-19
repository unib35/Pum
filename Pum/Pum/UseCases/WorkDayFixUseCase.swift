import Foundation

/// 하루 고치기(20f) 저장 규칙.
/// - 근무함: 근로조건 근무일이면 「고침」, 아니면 「추가 근무」
/// - 결근: 결근(시간 0)
/// - 쉬는 날: 근무 없음(고침 · 0–0). 기록을 지우면 자동 채움이 다시 만들기 때문에 남겨 둔다
struct WorkDayFixUseCase {
    enum Kind: Equatable { case worked(start: Int, end: Int, breakMinutes: Int), absent, dayOff }

    let workDays: WorkDayRepository
    var now: () -> Date = { .now }

    @discardableResult
    func execute(_ kind: Kind, reason: String, for employee: Employee, on dayKey: Int) throws -> WorkDay {
        switch kind {
        case .worked(let start, let end, let breakMinutes):
            let planned = Self.isPlannedDay(employee, dayKey)
            let edit = WorkDayEdit(status: planned ? .edited : .extra, startMinute: start, endMinute: end,
                                   breakMinutes: breakMinutes, reason: reason)
            return try workDays.save(edit, for: employee, on: dayKey, at: now())
        case .absent:
            return try workDays.markAbsent(employee, on: dayKey, reason: reason, at: now())
        case .dayOff:
            let edit = WorkDayEdit(status: .edited, startMinute: 0, endMinute: 0, breakMinutes: 0, reason: reason)
            return try workDays.save(edit, for: employee, on: dayKey, at: now())
        }
    }

    /// 그날 적용되는 근로조건의 근무 요일인지
    static func isPlannedDay(_ employee: Employee, _ dayKey: Int) -> Bool {
        guard let terms = employee.terms(on: dayKey) else { return false }
        return terms.workWeekdays.contains(SeoulDayKey.weekday(dayKey))
    }
}
