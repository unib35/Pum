// UI-IOS-15g · REQ-004 — 번호가 다를 때: 사장님 확인 후 소속 화면 데이터
// 번호 가림(010-7731-****)은 서버가 준 글자 그대로(화면에서 가리지 않는다). 전화번호는 로그에 남기지 않는다.
import SwiftUI

nonisolated struct InvitePhoneMismatchState: Equatable, Sendable {
    /// 서버가 가려서 준 「010-7731-****」 그대로
    let invitedPhoneMasked: String
    /// 지금 로그인한 번호 「010-5520-1934」
    let loginPhone: String
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
    /// 「사장님에게 확인 요청」 처리 중 — 이 버튼에만 표시
    let isRequesting: Bool

    init(invitedPhoneMasked: String, loginPhone: String, ownerName: String, workplaceName: String,
         colorIndex: Int, address: String, category: String, isVerified: Bool, roleName: String,
         expiryDate: String, isRequesting: Bool = false) {
        self.invitedPhoneMasked = invitedPhoneMasked
        self.loginPhone = loginPhone
        self.ownerName = ownerName
        self.workplaceName = workplaceName
        self.colorIndex = colorIndex
        self.address = address
        self.category = category
        self.isVerified = isVerified
        self.roleName = roleName
        self.expiryDate = expiryDate
        self.isRequesting = isRequesting
    }

    static let title = "초대"
    static let headline = "초대받은 번호와\n지금 번호가 달라요"
    static let invitedLabel = "초대받은 번호"
    static let loginLabel = "지금 로그인한 번호"
    static let notice = "번호를 바꿨다면 사장님이 확인한 뒤 소속돼요. 확인 전에는 출퇴근을 기록할 수 없어요."
    static let requestTitle = "사장님에게 확인 요청"
    static let loginWithInvitedTitle = "초대받은 번호로 로그인"

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    var initial: String { workplaceName.first.map(String.init) ?? "" }
    var subtitleText: String { "\(address) · \(category)" }
    var expiryValue: String { "\(expiryDate)까지" }

    /// VoiceOver — 가린 글자 「*」는 「별표 n개」로 읽는다(원문 없음 · 정한 방식)
    static func spokenPhone(_ masked: String) -> String {
        var out = ""
        var stars = 0
        for ch in masked {
            if ch == "*" {
                stars += 1
            } else {
                if stars > 0 { out += "별표 \(stars)개"; stars = 0 }
                out.append(ch)
            }
        }
        if stars > 0 { out += "별표 \(stars)개" }
        return out
    }
    var invitedAccessibilityText: String { "\(Self.invitedLabel), \(Self.spokenPhone(invitedPhoneMasked))" }
    var loginAccessibilityText: String { "\(Self.loginLabel), \(loginPhone)" }
    var cardAccessibilityText: String {
        isVerified ? "\(workplaceName), 인증된 사업장, \(subtitleText)" : "\(workplaceName), \(subtitleText)"
    }

    static let sample = InvitePhoneMismatchState(
        invitedPhoneMasked: "010-7731-****", loginPhone: "010-5520-1934", ownerName: "박민수",
        workplaceName: "종민김밥 본점", colorIndex: 0, address: "서울 마포구 양화로 12",
        category: "음식점", isVerified: true, roleName: "직원", expiryDate: "10월 14일")
}
