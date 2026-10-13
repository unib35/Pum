// UI-IOS-17i · 17k · REQ-014 — 관리자 초대 받음 / 대표 권한 이전 요청 받음 (같은 틀)
// 권한 목록 · 문구는 서버 값 — 화면이 권한을 정하지 않는다. 모든 값 let.
// 본인인증 화면은 호출하는 쪽 몫이다.
import Foundation

/// 어느 버튼이 처리 중인지 — 누른 버튼에만 처리 중 표시, 다른 버튼은 모양 그대로 누르기만 막는다
nonisolated enum RoleOfferResponse: Equatable, Sendable { case decline, accept }

/// 권한 섹션 — allowed true면 체크(할 수 있음), false면 ✕(할 수 없음)
nonisolated struct RoleOfferSection: Equatable, Sendable {
    let title: String
    let allowed: Bool
    /// 서버 값 — 「스케줄 · 근태 · 요청 처리」
    let rows: [String]

    /// 「할 수 있음, 스케줄 · 근태 · 요청 처리」
    func spoken(_ row: String) -> String {
        "\(allowed ? RoleOfferReceivedState.allowedSpoken : RoleOfferReceivedState.deniedSpoken), \(row)"
    }
}

nonisolated struct RoleOfferPair: Equatable, Sendable {
    let label: String
    let value: String
    /// 「표시, 위임받은 대표」
    var spoken: String { "\(label), \(value)" }
}

nonisolated struct RoleOfferReceivedState: Equatable, Sendable {
    static let backTitle = "소식"
    static let needsDecisionTitle = "결정 필요"
    static let verifiedBadge = "✓ 인증된 사업장"
    static let declineTitle = "거절"
    static let acceptTitle = "본인인증 후 수락"
    static let allowedSpoken = "할 수 있음"
    static let deniedSpoken = "할 수 없음"

    /// 「박민수 · 오늘 11:05」
    let sentText: String
    let title: String
    /// 「종민김밥 본점 · 대표 박민수」
    let businessText: String
    let sections: [RoleOfferSection]
    let pairs: [RoleOfferPair]
    let footerNotice: String
    let responding: RoleOfferResponse?

    init(sentText: String, title: String, businessText: String, sections: [RoleOfferSection],
         pairs: [RoleOfferPair] = [], footerNotice: String, responding: RoleOfferResponse? = nil) {
        self.sentText = sentText
        self.title = title
        self.businessText = businessText
        self.sections = sections
        self.pairs = pairs
        self.footerNotice = footerNotice
        self.responding = responding
    }

    var isResponding: Bool { responding != nil }
    func isLoading(_ button: RoleOfferResponse) -> Bool { responding == button }

    /// 처리 중으로 바꾼 사본 — 이미 처리 중이면 nil(두 번 보내지 않기)
    func beginning(_ button: RoleOfferResponse) -> RoleOfferReceivedState? {
        guard responding == nil else { return nil }
        return with(responding: button)
    }

    /// 실패했을 때만 풀린다
    func ended() -> RoleOfferReceivedState { with(responding: nil) }

    /// 「인증된 사업장, 종민김밥 본점 · 대표 박민수」
    var verifiedReadout: String { "인증된 사업장, \(businessText)" }

    private func with(responding: RoleOfferResponse?) -> RoleOfferReceivedState {
        RoleOfferReceivedState(sentText: sentText, title: title, businessText: businessText, sections: sections,
                               pairs: pairs, footerNotice: footerNotice, responding: responding)
    }

    /// 17i 원문 캡처 값
    static let managerInvite = RoleOfferReceivedState(
        sentText: "박민수 · 오늘 11:05", title: "관리자 초대", businessText: "종민김밥 본점 · 대표 박민수",
        sections: [
            RoleOfferSection(title: "할 수 있는 것", allowed: true, rows: [
                "스케줄 · 근태 · 요청 처리", "급여 확정 · 명세서 발행 · 지급 처리", "직원 정보 · 서류 열람"]),
            RoleOfferSection(title: "할 수 없는 것", allowed: false, rows: [
                "대표 변경 · 사업장 삭제", "관리자 지정"])
        ],
        footerNotice: "직원으로 일하던 기록과 급여는 그대로예요")

    /// 17k 원문 캡처 값
    static let ownerTransfer = RoleOfferReceivedState(
        sentText: "박민수 · 오늘 10:12", title: "대표 권한 이전", businessText: "종민김밥 본점 · 대표 박민수",
        sections: [
            RoleOfferSection(title: "받는 권한", allowed: true, rows: [
                "관리자 지정 · 권한 변경", "대표 변경 · 사업장 삭제", "지급 처리 · 강한 인증"])
        ],
        pairs: [
            RoleOfferPair(label: "표시", value: "위임받은 대표"),
            RoleOfferPair(label: "사업자 대표자", value: "박민수"),
            RoleOfferPair(label: "박민수", value: "관리자로 남음")
        ],
        footerNotice: "거절하면 지금 그대로예요")
}
