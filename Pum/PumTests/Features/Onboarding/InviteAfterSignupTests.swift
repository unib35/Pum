// UI-IOS-15c — 가입 직후 받은 초대: 원문 값 · 읽기 문구 · 미인증 배지
import Testing
@testable import Pum

struct InviteAfterSignupTests {
    let s = InviteAfterSignupState.sample

    @Test func 원문_값() {
        #expect(s.phoneLine == "가입 완료 · 010-7731-2048")
        #expect(s.titleText == "이 번호로 받은 초대 1건")
        #expect(s.subtitleText == "서울 마포구 양화로 12 · 음식점")
        #expect(s.expiryValue == "10월 14일까지")
        #expect(s.initial == "종")
    }

    @Test func 읽기_문구() {
        #expect(s.cardAccessibilityText == "종민김밥 본점, 인증된 사업장, 서울 마포구 양화로 12 · 음식점")
        #expect(s.brandAccessibilityText == "품, 가입 완료 · 010-7731-2048")
    }

    @Test func 미인증_사업장은_인증_문구가_없다() {
        let x = InviteAfterSignupState(
            phone: s.phone, inviteCount: 2, ownerName: s.ownerName, workplaceName: s.workplaceName,
            colorIndex: -3, address: s.address, category: s.category, isVerified: false,
            roleName: s.roleName, expiryDate: s.expiryDate)
        #expect(x.cardAccessibilityText == "종민김밥 본점, 서울 마포구 양화로 12 · 음식점")
        #expect(x.titleText == "이 번호로 받은 초대 2건")
        _ = x.tileColor
    }
}
