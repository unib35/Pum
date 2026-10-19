// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 직원. 날짜는 `SeoulDayKey`(yyyyMMdd 정수).
/// 지우면 근로조건 · 근무 · 계약서 사진은 함께 지워지고, 확정 명세서는 남는다(직원 연결만 끊기고 이름은 명세서에 보존).
@Model
final class Employee {
    var name: String = ""
    var phone: String?
    var birthDayKey: Int?
    var hireDayKey: Int = 0
    var leaveDayKey: Int?
    /// 아바타 색 번호(디자인 토큰 팔레트 인덱스).
    var colorIndex: Int = 0
    var memo: String = ""
    var createdAt: Date = Date.now

    var workplace: Workplace?

    @Relationship(deleteRule: .cascade, inverse: \WorkTerms.employee)
    var terms: [WorkTerms]? = []

    @Relationship(deleteRule: .cascade, inverse: \WorkDay.employee)
    var workDays: [WorkDay]? = []

    @Relationship(deleteRule: .cascade, inverse: \ContractPhoto.employee)
    var contractPhotos: [ContractPhoto]? = []

    @Relationship(deleteRule: .nullify, inverse: \Payslip.employee)
    var payslips: [Payslip]? = []

    init(name: String, phone: String? = nil, birthDayKey: Int? = nil, hireDayKey: Int,
         leaveDayKey: Int? = nil, colorIndex: Int = 0, memo: String = "", createdAt: Date = .now) {
        self.name = name
        self.phone = phone
        self.birthDayKey = birthDayKey
        self.hireDayKey = hireDayKey
        self.leaveDayKey = leaveDayKey
        self.colorIndex = colorIndex
        self.memo = memo
        self.createdAt = createdAt
    }

    /// 그 날짜에 재직 중인지(입사일 ≤ 날짜 ≤ 퇴사일).
    func isEmployed(on dayKey: Int) -> Bool {
        dayKey >= hireDayKey && (leaveDayKey.map { dayKey <= $0 } ?? true)
    }

    /// 그 날짜에 적용되는 근로조건(적용 시작일이 그 날짜 이전인 것 중 가장 늦은 것).
    func terms(on dayKey: Int) -> WorkTerms? {
        WorkTermsPicker.pick(terms ?? [], on: dayKey) { $0.effectiveFromDayKey }
    }
}
