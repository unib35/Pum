// UI-IOS-15c · REQ-003 · REQ-013 — 가입 직후: 인증한 번호로 받은 초대 화면 데이터
// 번호 · 건수 · 이름 · 주소 · 날짜 · 인증 여부는 서버 값 그대로(화면에서 만들거나 계산하지 않는다).
// 전화번호는 로그에 남기지 않는다.
import SwiftUI

nonisolated struct InviteAfterSignupState: Equatable, Sendable {
    /// 본인 번호 — 서버가 준 「010-7731-2048」 그대로
    let phone: String
    /// 이 번호로 받은 초대 건수(서버 정수)
    let inviteCount: Int
    let ownerName: String
    let workplaceName: String
    /// 사업장 색은 팔레트 번호(PumAvatarPalette.stores, 충돌 #20)
    let colorIndex: Int
    let address: String
    let category: String
    /// 사업장 인증 여부 — 미인증이면 배지를 숨긴다
    let isVerified: Bool
    let roleName: String
    /// 서버가 준 「10월 14일」 그대로
    let expiryDate: String

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    var initial: String { workplaceName.first.map(String.init) ?? "" }

    var phoneLine: String { "가입 완료 · \(phone)" }
    var titleText: String { "이 번호로 받은 초대 \(inviteCount)건" }
    var subtitleText: String { "\(address) · \(category)" }
    var expiryValue: String { "\(expiryDate)까지" }

    /// VoiceOver — 사업장 카드 한 덩어리
    var cardAccessibilityText: String {
        isVerified ? "\(workplaceName), 인증된 사업장, \(subtitleText)" : "\(workplaceName), \(subtitleText)"
    }
    var brandAccessibilityText: String { "품, \(phoneLine)" }

    static let sample = InviteAfterSignupState(
        phone: "010-7731-2048", inviteCount: 1, ownerName: "박민수",
        workplaceName: "종민김밥 본점", colorIndex: 0, address: "서울 마포구 양화로 12",
        category: "음식점", isVerified: true, roleName: "직원", expiryDate: "10월 14일")
}
