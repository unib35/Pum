// UI-IOS-10p · REQ-073 — 사업장 설정 › 휴가 · 퇴직: 법정 대상은 자동, 방식만 선택.
// 상시 근로자 수 · 판정 · 대상 기준 문구 · 선택지 · 설명은 서버 값 — 화면에서 근로자 수나 대상 판정을 계산하지 않는다.
// 법정 대상 자체를 끄는 설정은 없다(끌 수 없음). 「퇴직금 제도 없음」 같은 선택지도 없다 — 서버가 주는 선택지만.
import Foundation

/// 퇴직급여 방식 — 서버가 주는 값
nonisolated enum RetirementKind: Equatable, Hashable, Sendable {
    case severance, definedBenefit, definedContribution
}

nonisolated struct RetirementOption: Equatable, Identifiable, Sendable {
    var kind: RetirementKind
    var title: String
    var detail: String
    var id: RetirementKind { kind }
}

/// 저장하는 값 — 방식만
nonisolated struct LeaveRetirementSettings: Equatable, Sendable {
    /// 예: 「입사일 기준」 (고르는 화면은 onPickBasisDate가 연다 — 서버가 새 값을 준다)
    var basisText: String
    var hourlyUse: Bool
    var promotion: Bool
    var agreedLeave: Bool
    var retirement: RetirementKind
}

nonisolated struct LeaveRetirementState: Equatable, Sendable {
    /// 예: 「상시 근로자 5.4명 · 5인 이상」 — 서버가 판정한 문구
    var headcountText: String
    /// 예: 「10월 1일 자동 판정 · 법정 연차 적용」
    var judgmentText: String
    /// 예: 「연차 · 대상은 주 15시간 이상 직원」
    var leaveHeader: String
    var hourlyDetail: String
    /// 노무 검토 권장 문구는 서버 값 그대로
    var promotionDetail: String
    var agreedDetail: String
    /// 예: 「퇴직급여 · 1년 이상 · 주 15시간 이상이면 자동 대상」
    var retirementHeader: String
    var retirementOptions: [RetirementOption]
    /// 지금 저장된 값
    var settings: LeaveRetirementSettings

    static let headerTitle = "휴가 · 퇴직"
    static let basisLink = "근거"
    static let basisTitle = "기준일"
    static let hourlyTitle = "시간 단위로 쓰기"
    static let promotionTitle = "연차 사용 촉진"
    static let agreedTitle = "약정 연차"
    static let saveTitle = "저장"
    static let notice = "법정 기준보다 적게는 설정할 수 없어요"

    /// VoiceOver — 「퇴직금, 퇴사 때 평균임금 30일분 × 근속연수, 선택됨, 3개 중 1번째」
    func optionAccessibility(_ option: RetirementOption, isOn: Bool) -> String {
        let index = (retirementOptions.firstIndex(of: option) ?? 0) + 1
        var parts = [option.title, option.detail]
        if isOn { parts.append("선택됨") }
        parts.append("\(retirementOptions.count)개 중 \(index)번째")
        return parts.joined(separator: ", ")
    }

    /// 원문 캡처 값
    static let sample = LeaveRetirementState(
        headcountText: "상시 근로자 5.4명 · 5인 이상",
        judgmentText: "10월 1일 자동 판정 · 법정 연차 적용",
        leaveHeader: "연차 · 대상은 주 15시간 이상 직원",
        hourlyDetail: "단시간 직원은 시간으로 생기고 차감돼요",
        promotionDetail: "기한 전 서면 통지 · 노무 검토 권장",
        agreedDetail: "법정 대상이 아닌 직원에게 따로 주기",
        retirementHeader: "퇴직급여 · 1년 이상 · 주 15시간 이상이면 자동 대상",
        retirementOptions: [
            RetirementOption(kind: .severance, title: "퇴직금", detail: "퇴사 때 평균임금 30일분 × 근속연수"),
            RetirementOption(kind: .definedBenefit, title: "퇴직연금 DB형", detail: "퇴직금과 같은 금액 · 연금사업자가 지급"),
            RetirementOption(kind: .definedContribution, title: "퇴직연금 DC형", detail: "매년 적립 · 앱은 적립 할 일만 알려요"),
        ],
        settings: LeaveRetirementSettings(basisText: "입사일 기준", hourlyUse: true, promotion: false,
                                          agreedLeave: false, retirement: .severance))
}

/// 사용자가 고른 값. 시작값은 서버가 준 저장값.
nonisolated struct LeaveRetirementDraft: Equatable, Sendable {
    var hourlyUse: Bool
    var promotion: Bool
    var agreedLeave: Bool
    var retirement: RetirementKind

    init(_ s: LeaveRetirementSettings) {
        hourlyUse = s.hourlyUse
        promotion = s.promotion
        agreedLeave = s.agreedLeave
        retirement = s.retirement
    }

    /// 서버가 준 선택지 밖 값은 받지 않는다
    mutating func select(_ kind: RetirementKind, in state: LeaveRetirementState) {
        guard state.retirementOptions.contains(where: { $0.kind == kind }) else { return }
        retirement = kind
    }

    /// 저장하는 값 — 기준일은 서버 값 그대로
    func settings(basisText: String) -> LeaveRetirementSettings {
        LeaveRetirementSettings(basisText: basisText, hourlyUse: hourlyUse, promotion: promotion,
                                agreedLeave: agreedLeave, retirement: retirement)
    }
}

/// 저장은 처리 중에만 한 번 — 설정 저장은 다시 해도 되는 일이라 끝나면(성공 · 실패 모두) 풀린다(10l과 같은 규칙)
nonisolated struct LeaveRetirementLock: Equatable, Sendable {
    private(set) var isSaving = false
    mutating func begin() -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        return true
    }
    mutating func finish() { isSaving = false }
}
