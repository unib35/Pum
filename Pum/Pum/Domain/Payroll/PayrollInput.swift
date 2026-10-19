// DEC-029 · DEC-031 · REQ-071 — 월급 계산 모듈 입력(값 타입). 화면 · 저장소에 의존하지 않는다.
import Foundation

/// 공제 방식(DEC-031). 4대보험 · 근로소득세는 다음 버전.
nonisolated enum PayrollDeductionMethod: Equatable, Sendable {
    /// 공제 없음
    case none
    /// 사업소득 3.3%(소득세 3% + 지방소득세 0.3%)
    case business3_3
}

/// 사업장 조건.
nonisolated struct PayrollWorkplace: Equatable, Sendable {
    /// 상시 5인 이상이면 연장 · 야간 · 휴일 50% 가산을 적용한다.
    var isFiveOrMore: Bool
    var deduction: PayrollDeductionMethod

    init(isFiveOrMore: Bool, deduction: PayrollDeductionMethod) {
        self.isFiveOrMore = isFiveOrMore
        self.deduction = deduction
    }
}

/// 임금 형태. 금액은 정수 원.
nonisolated enum PayrollWage: Equatable, Sendable {
    /// 시급(원)
    case hourly(Int)
    /// 월급(원)
    case monthly(Int)
}

/// 근로조건. 주휴 판단에 쓰는 소정근로(약정 근무 요일 · 하루 시간)를 담는다.
nonisolated struct PayrollWorkTerms: Equatable, Sendable {
    var wage: PayrollWage
    /// 주 소정근로 요일
    var scheduledWeekdays: Set<PayrollWeekday>
    /// 하루 소정근로 시간(분, 휴게 제외)
    var dailyScheduledMinutes: Int

    init(wage: PayrollWage, scheduledWeekdays: Set<PayrollWeekday>, dailyScheduledMinutes: Int) {
        self.wage = wage
        self.scheduledWeekdays = scheduledWeekdays
        self.dailyScheduledMinutes = dailyScheduledMinutes
    }

    /// 주 소정근로시간(분) = 요일 수 × 하루 소정근로 시간
    var weeklyScheduledMinutes: Int { scheduledWeekdays.count * max(0, dailyScheduledMinutes) }
}

/// 근무 기록 하루치.
nonisolated struct PayrollWorkRecord: Equatable, Sendable {
    /// 근무를 시작한 날(서울 기준). 자정을 넘긴 근무도 시작한 날에 속한다.
    var date: PayrollDate
    /// 시작 시각 — 그날 0시부터 지난 분(0 ..< 1440)
    var startMinute: Int
    /// 끝 시각 — 그날 0시부터 지난 분. 자정을 넘기면 1440 이상(예: 다음날 02:00 = 1560)
    var endMinute: Int
    /// 휴게(분)
    var breakMinutes: Int
    /// 휴일 근무(약정 휴일 · 주휴일에 일한 날)
    var isHolidayWork: Bool
    /// 결근(이 날 근무 시간은 0으로 본다)
    var isAbsent: Bool

    init(
        date: PayrollDate,
        startMinute: Int,
        endMinute: Int,
        breakMinutes: Int = 0,
        isHolidayWork: Bool = false,
        isAbsent: Bool = false
    ) {
        self.date = date
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.breakMinutes = breakMinutes
        self.isHolidayWork = isHolidayWork
        self.isAbsent = isAbsent
    }

    /// 결근 기록
    static func absent(_ date: PayrollDate) -> PayrollWorkRecord {
        PayrollWorkRecord(date: date, startMinute: 0, endMinute: 0, isAbsent: true)
    }

    /// 인정 근무시간(분) = 끝 − 시작 − 휴게. 결근이거나 값이 거꾸로면 0.
    var workedMinutes: Int {
        guard !isAbsent else { return 0 }
        return max(0, endMinute - startMinute - max(0, breakMinutes))
    }
}

/// 계산 입력 전체.
nonisolated struct PayrollInput: Equatable, Sendable {
    var workplace: PayrollWorkplace
    var period: PayrollPeriod
    var terms: PayrollWorkTerms
    /// 기간 안 기록은 지급 대상. 기간 밖(앞뒤 달에 걸친 주의) 기록은 주 40시간 · 주휴 판단에만 쓰고 지급하지 않는다.
    var records: [PayrollWorkRecord]

    init(workplace: PayrollWorkplace, period: PayrollPeriod, terms: PayrollWorkTerms, records: [PayrollWorkRecord]) {
        self.workplace = workplace
        self.period = period
        self.terms = terms
        self.records = records
    }
}
