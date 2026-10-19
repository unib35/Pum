// DEC-031 · REQ-071 — 월급 계산 결과 + 계산 근거(Trace)
import Foundation

/// 계산 근거 한 줄이 어느 항목에 속하는지.
nonisolated enum PayrollTraceItem: Equatable, Sendable {
    case basePay
    case weeklyHolidayPay
    case overtime
    case night
    case holiday
    case gross
    case incomeTax
    case localIncomeTax
    case deductionTotal
    case netPay
    /// 규칙 · 가정 안내(금액 없음)
    case note
}

/// 사람이 읽는 계산 근거 한 줄(한국어).
nonisolated struct PayrollTraceLine: Equatable, Sendable, CustomStringConvertible {
    let item: PayrollTraceItem
    let text: String

    var description: String { text }
}

/// 계산 결과. 금액은 모두 정수 원.
nonisolated struct PayrollResult: Equatable, Sendable {
    /// 기본급
    var basePay: Int
    /// 주휴수당
    var weeklyHolidayPay: Int
    /// 연장 가산(50%분)
    var overtimePay: Int
    /// 야간 가산(50%분)
    var nightPay: Int
    /// 휴일 가산(8시간 이내 50% · 초과 100%분)
    var holidayPay: Int
    /// 지급 합계
    var grossPay: Int
    /// 소득세(3.3% 공제일 때)
    var incomeTax: Int
    /// 지방소득세(3.3% 공제일 때)
    var localIncomeTax: Int
    /// 공제 합계
    var totalDeduction: Int
    /// 실지급액 = 지급 합계 − 공제 합계
    var netPay: Int

    /// 근무일 수(기간 안, 결근 아닌 근무가 있는 날)
    var workDays: Int
    /// 인정 근무시간 합계(분, 휴게 제외, 기간 안)
    var workedMinutes: Int
    /// 연장 · 야간 · 휴일 시간(분, 기간 안). 5인 미만이어도 시간은 센다.
    var overtimeMinutes: Int
    var nightMinutes: Int
    var holidayMinutes: Int
    /// 주휴수당을 받은 주 수
    var weeklyHolidayWeeks: Int

    var trace: [PayrollTraceLine]

    /// 근거 문장만
    var traceText: [String] { trace.map(\.text) }
}
