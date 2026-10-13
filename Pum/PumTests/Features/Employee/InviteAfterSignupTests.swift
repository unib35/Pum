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
    }

    private func with(colorIndex: Int, name: String? = nil) -> InviteAfterSignupState {
        InviteAfterSignupState(
            phone: s.phone, inviteCount: s.inviteCount, ownerName: s.ownerName, workplaceName: name ?? s.workplaceName,
            colorIndex: colorIndex, address: s.address, category: s.category, isVerified: s.isVerified,
            roleName: s.roleName, expiryDate: s.expiryDate)
    }

    @Test func 타일_색은_범위_밖_번호도_순환() {
        let stores = PumAvatarPalette.stores
        let n = stores.count
        #expect(with(colorIndex: 0).tileColor == stores[0])
        #expect(with(colorIndex: n).tileColor == stores[0])
        #expect(with(colorIndex: n + 1).tileColor == stores[1 % n])
        #expect(with(colorIndex: -1).tileColor == stores[n - 1])
    }

    @Test func 빈_사업장_이름이면_머리글자도_빈칸() {
        #expect(with(colorIndex: 0, name: "").initial == "")
    }
}
