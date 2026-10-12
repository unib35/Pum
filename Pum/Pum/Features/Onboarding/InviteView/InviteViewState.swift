// UI-IOS-5f · REQ-013 — 직원이 보는 초대 화면 데이터
// 이름 · 주소 · 번호(서버가 가린 값) · 인원 · 날짜 · 조건은 서버 값 그대로(화면에서 만들거나 계산하지 않는다).
import Foundation
import SwiftUI

nonisolated struct InviteViewState: Equatable, Sendable {
    var workplaceName: String
    /// 사업장 색은 팔레트 번호(PumAvatarPalette.stores, 충돌 #20)
    var colorIndex: Int
    var category: String
    var address: String
    /// 사업장 인증 여부 — false면 배지 · 본인확인 · 영업 중을 숨기고 경고 상자를 보인다(충돌 #36)
    var isVerified: Bool
    var ownerName: String
    var ownerIdentityVerified: Bool
    /// 서버가 가린 값 「123-45-*****」 — 앱은 가리지 않는다
    var businessNumberMasked: String
    var isOperating: Bool
    var inviterName: String
    var inviterRole: String
    var staffCount: Int
    /// 운영 시작 — 서버가 준 「2024.03」 그대로
    var operatingSince: String
    var hourlyWage: Int
    var schedule: String           // 「월·수·금 17:00 – 22:00」
    var payday: String             // 「매월 10일」

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    /// 네모 안 글자 — 서버가 따로 주면 그 값(21g 「율」), 없으면 이름 첫 글자
    var tileInitial: String?
    var initial: String { tileInitial ?? workplaceName.first.map(String.init) ?? "" }

    var titleText: String { "\(workplaceName)에서\n직원으로 초대했어요" }
    var subtitleText: String { "\(category) · \(address)" }
    var inviterValue: String { "\(inviterName) · \(inviterRole)" }
    var staffValue: String { "\(staffCount)명 · \(operatingSince)부터 운영" }
    var wageText: String { PumFormat.amount(hourlyWage) + "원" }

    /// 인증된 사업장에서만 보이는 작은 표시
    var ownerTag: String? { isVerified && ownerIdentityVerified ? "본인확인" : nil }
    var operatingTag: String? { isVerified && isOperating ? "영업 중" : nil }

    /// 미인증(21g) 문구 — 상태 문구는 서버 값(여기선 미리보기 값)
    static let unverifiedBadge = "인증 전"
    static let unverifiedFact = "확인 전"
    static let unverifiedNoticeTitle = "아직 인증되지 않은 사업장이에요"
    static let unverifiedNoticeDetail = "개인정보 제출과 계약 서명은 인증 후에 진행돼요"
    static let unverifiedAllowedNow = "지금은 초대 수락 · 출퇴근 기록"
    static let unverifiedAfterVerify = "인증되면 계약 서명 알림"

    /// 미인증 사업장 카드 VoiceOver — 「종민김밥 율하점, 인증 전」
    var unverifiedCardAccessibility: String { "\(workplaceName), \(Self.unverifiedBadge)" }
    /// 미인증 행 값 — 대표자 · 사업자등록은 확인 전, 초대한 사람은 이름만
    var unverifiedOwnerValue: String { Self.unverifiedFact }
    var unverifiedBusinessValue: String { Self.unverifiedFact }
    var unverifiedInviterValue: String { inviterName }

    /// VoiceOver — 「대표자, 박민수, 본인확인」
    var ownerAccessibility: String { ["대표자", ownerName, ownerTag].compactMap { $0 }.joined(separator: ", ") }
    var businessAccessibility: String { ["사업자등록", businessNumberMasked, operatingTag].compactMap { $0 }.joined(separator: ", ") }

    static let sample = InviteViewState(
        workplaceName: "종민김밥 본점", colorIndex: 0, category: "음식점", address: "부산 김해시 장유로 12",
        isVerified: true, ownerName: "박민수", ownerIdentityVerified: true,
        businessNumberMasked: "123-45-*****", isOperating: true,
        inviterName: "박민수", inviterRole: "대표", staffCount: 4, operatingSince: "2024.03",
        hourlyWage: 12_000, schedule: "월·수·금 17:00 – 22:00", payday: "매월 10일")

    /// 미인증 미리보기(21g) — 대표자 · 사업자등록 확인 전
    static var unverifiedSample: InviteViewState {
        var s = sample
        s.workplaceName = "종민김밥 율하점"
        s.colorIndex = 2 // 남색
        s.tileInitial = "율"
        s.address = "김해시 율하로 40"
        s.isVerified = false
        s.inviterName = "박민수"
        return s
    }
}

/// 「참여하기」 한 번만 — 처리 중 잠금, 실패하면 풀림
nonisolated struct InviteJoinLock: Equatable, Sendable {
    private(set) var isSending = false
    /// 보낼 수 있으면 true를 돌려주고 잠근다. 이미 처리 중이면 false.
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
