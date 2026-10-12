// UI-IOS-15g — 번호가 다를 때: 원문 값 · 읽기 문구 · 미인증 배지 없음
import Testing
@testable import Pum

struct InvitePhoneMismatchTests {
    let s = InvitePhoneMismatchState.sample

    @Test func 원문_값() {
        #expect(s.invitedPhoneMasked == "010-7731-****")
        #expect(s.loginPhone == "010-5520-1934")
        #expect(InvitePhoneMismatchState.headline == "초대받은 번호와\n지금 번호가 달라요")
        #expect(InvitePhoneMismatchState.notice == "번호를 바꿨다면 사장님이 확인한 뒤 소속돼요. 확인 전에는 출퇴근을 기록할 수 없어요.")
        #expect(s.subtitleText == "서울 마포구 양화로 12 · 음식점")
        #expect(s.expiryValue == "10월 14일까지")
        #expect(s.initial == "종")
    }

    @Test func 읽기_문구() {
        #expect(s.invitedAccessibilityText == "초대받은 번호, 010-7731-별표 4개")
        #expect(s.loginAccessibilityText == "지금 로그인한 번호, 010-5520-1934")
        #expect(s.cardAccessibilityText == "종민김밥 본점, 인증된 사업장, 서울 마포구 양화로 12 · 음식점")
    }

    @Test func 미인증_사업장은_인증_문구가_없다() {
        let x = InvitePhoneMismatchState(
            invitedPhoneMasked: s.invitedPhoneMasked, loginPhone: s.loginPhone, ownerName: s.ownerName,
            workplaceName: s.workplaceName, colorIndex: -3, address: s.address, category: s.category,
            isVerified: false, roleName: s.roleName, expiryDate: s.expiryDate)
        #expect(x.cardAccessibilityText == "종민김밥 본점, 서울 마포구 양화로 12 · 음식점")
        #expect(!x.isRequesting)
    }
}
