// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 확정 명세서 스냅숏. 확정한 뒤에는 다시 계산하지 않는다 — 근무를 고쳐도 이 값은 그대로다.
/// 계산은 Domain/Payroll이 하고, 여기는 결과만 받아 둔다. 금액은 모두 정수 원.
/// 항목은 이름 · 금액 두 배열로 나눠 저장한다(Codable 구조체 배열보다 CloudKit 저장이 단순).
@Model
final class Payslip {
    /// 명세서 항목 한 줄(이름 · 금액(원)).
    struct Line: Equatable {
        var name: String
        var amount: Int
    }

    var year: Int = 0
    var month: Int = 0
    /// 직원이 지워져도 명세서에 남도록 이름을 따로 보존.
    var employeeName: String = ""
    var payItemNames: [String] = []
    var payItemAmounts: [Int] = []
    var deductionItemNames: [String] = []
    var deductionItemAmounts: [Int] = []
    var grossPay: Int = 0
    var totalDeduction: Int = 0
    var netPay: Int = 0
    /// 계산 근거 줄 목록(Trace).
    var traceLines: [String] = []
    /// 근무일 수 · 인정 근무(분) — 명세서 근무 요약용
    var workDays: Int = 0
    var workedMinutes: Int = 0
    var createdAt: Date = Date.now

    var employee: Employee?
    var payrollMonth: PayrollMonth?

    init(year: Int, month: Int, employeeName: String, payItems: [Line],
         deductionItems: [Line], grossPay: Int, totalDeduction: Int, netPay: Int,
         traceLines: [String], createdAt: Date = .now) {
        self.year = year
        self.month = month
        self.employeeName = employeeName
        self.payItemNames = payItems.map(\.name)
        self.payItemAmounts = payItems.map(\.amount)
        self.deductionItemNames = deductionItems.map(\.name)
        self.deductionItemAmounts = deductionItems.map(\.amount)
        self.grossPay = grossPay
        self.totalDeduction = totalDeduction
        self.netPay = netPay
        self.traceLines = traceLines
        self.createdAt = createdAt
    }

    var payItems: [Line] {
        zip(payItemNames, payItemAmounts).map { Line(name: $0, amount: $1) }
    }

    var deductionItems: [Line] {
        zip(deductionItemNames, deductionItemAmounts).map { Line(name: $0, amount: $1) }
    }
}
