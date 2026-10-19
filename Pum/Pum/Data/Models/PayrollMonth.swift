// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 사업장의 한 달 급여(근무 마감 상태 + 확정 명세서 묶음). (사업장, 연, 월)당 한 건 규칙은 Repository가 지킨다.
@Model
final class PayrollMonth {
    var year: Int = 0
    var month: Int = 0
    var isClosed: Bool = false
    var closedAt: Date?

    var workplace: Workplace?

    @Relationship(deleteRule: .cascade, inverse: \Payslip.payrollMonth)
    var payslips: [Payslip]? = []

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
}
