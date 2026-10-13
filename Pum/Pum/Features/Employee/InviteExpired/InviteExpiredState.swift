// UI-IOS-15f · REQ-002 — 초대 만료 화면 데이터
// 날짜 · 이름 · 주소 · 업종 · 인증 여부는 서버 값 그대로(화면에서 만들거나 계산하지 않는다).
import SwiftUI

nonisolated struct InviteExpiredState: Equatable, Sendable {
    var ownerName: String          // 「박민수」 — 사장님 호칭은 화면이 붙임
    var workplaceName: String
    /// 사업장 색은 팔레트 번호(PumAvatarPalette.stores, 충돌 #20)
    var colorIndex: Int
    var address: String
    var category: String
    /// 사업장 인증 여부 — 미인증이면 배지를 숨긴다(미인증 문구는 이 화면 디자인에 없음)
    var isVerified: Bool
    var roleName: String           // 「직원」
    /// 만료일 문구 — 서버가 준 「10월 14일」 그대로
    var expiryDate: String
    /// 알림에 들어갈 요청자(나) 이름 — 「한지우」
    var requesterName: String

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    var initial: String { workplaceName.first.map(String.init) ?? "" }

    var subtitleText: String { "\(address) · \(category)" }
    var expiredLine: String { "\(expiryDate)에 만료됐어요 · 이 초대로는 수락할 수 없어요" }
    var expiryValue: String { "\(expiryDate) 만료" }
    /// VoiceOver — 색만으로 알리지 않는다
    var expiryAccessibilityText: String { "초대 유효, \(expiryValue)" }
    var requestTitle: String { "\(ownerName) 사장님에게 다시 요청" }
    var requestNote: String { "사장님 앱에 \"\(requesterName)님이 새 초대를 요청했어요\" 알림이 가요" }

    static let sample = InviteExpiredState(
        ownerName: "박민수", workplaceName: "종민김밥 본점", colorIndex: 0,
        address: "서울 마포구 양화로 12", category: "음식점", isVerified: true,
        roleName: "직원", expiryDate: "10월 14일", requesterName: "한지우")
}

/// 「다시 요청」 한 번만 보내기 — 처리 중 잠금, 실패하면 풀림(성공 뒤 결과 화면은 디자인에 없음)
nonisolated struct InviteRequestLock: Equatable, Sendable {
    private(set) var isSending = false
    /// 보낼 수 있으면 true를 돌려주고 잠근다. 이미 처리 중이면 false.
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    /// 실패하면 풀어 다시 누를 수 있게, 성공이면 잠근 채 둔다
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
