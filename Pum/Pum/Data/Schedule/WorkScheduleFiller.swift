import Foundation

/// 「근로조건대로 자동 채움」의 순수 계산 부분(저장과 분리 — 테스트 대상).
/// 그 달의 날짜마다 그날 적용되는 근로조건을 고르고, 근무 요일이면서 아직 기록이 없는 날만 예정 근무로 만든다.
/// 이미 있는 날(예정대로 · 고침 · 결근 · 추가 근무 모두)은 건드리지 않는다.
enum WorkScheduleFiller {
    /// 근로조건 한 건의 값(모델과 분리한 입력).
    struct Terms: Equatable {
        var effectiveFromDayKey: Int
        var workWeekdays: Set<Int>
        var startMinute: Int
        var endMinute: Int
        var breakMinutes: Int
    }

    /// 만들 예정 근무 한 건.
    struct PlannedDay: Equatable {
        var dayKey: Int
        var startMinute: Int
        var endMinute: Int
        var breakMinutes: Int
    }

    static func plannedDays(year: Int, month: Int, terms: [Terms], hireDayKey: Int,
                            leaveDayKey: Int?, existingDayKeys: Set<Int>) -> [PlannedDay] {
        SeoulDayKey.keys(year: year, month: month).compactMap { key in
            guard key >= hireDayKey,
                  leaveDayKey.map({ key <= $0 }) ?? true,
                  !existingDayKeys.contains(key),
                  let applied = WorkTermsPicker.pick(terms, on: key, effectiveFrom: { $0.effectiveFromDayKey }),
                  applied.workWeekdays.contains(SeoulDayKey.weekday(key)) else { return nil }
            return PlannedDay(dayKey: key,
                              startMinute: applied.startMinute,
                              endMinute: WorkDay.normalizedEnd(start: applied.startMinute, end: applied.endMinute),
                              breakMinutes: applied.breakMinutes)
        }
    }
}
