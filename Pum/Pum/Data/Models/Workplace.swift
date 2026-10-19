// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 사업장(MVP는 1곳). 직원 · 월 마감을 품는다. 지우면 직원 · 월 마감 · 명세서까지 함께 지워진다.
@Model
final class Workplace {
    /// 공제 방식(DEC-031). 저장은 `deductionRaw`(String).
    enum Deduction: String, CaseIterable, Codable {
        case none
        case business3_3
    }

    var name: String = ""
    /// 아바타 등에 쓰는 첫 글자.
    var initial: String = ""
    /// 상시 5인 이상 여부(가산수당 적용 기준).
    var isFiveOrMore: Bool = false
    var deductionRaw: String = Deduction.none.rawValue
    /// 급여일(1–31). 그 달에 없는 날이면 말일로 본다.
    var payday: Int = 10
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Employee.workplace)
    var employees: [Employee]? = []

    @Relationship(deleteRule: .cascade, inverse: \PayrollMonth.workplace)
    var payrollMonths: [PayrollMonth]? = []

    var deduction: Deduction {
        get { Deduction(rawValue: deductionRaw) ?? .none }
        set { deductionRaw = newValue.rawValue }
    }

    init(name: String, initial: String? = nil, isFiveOrMore: Bool = false,
         deduction: Deduction = .none, payday: Int = 10, createdAt: Date = .now) {
        self.name = name
        self.initial = initial ?? String(name.prefix(1))
        self.isFiveOrMore = isFiveOrMore
        self.deductionRaw = deduction.rawValue
        self.payday = Workplace.clampedPayday(payday)
        self.createdAt = createdAt
    }

    static func clampedPayday(_ value: Int) -> Int { min(max(value, 1), 31) }
}
