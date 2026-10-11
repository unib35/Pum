// UI-IOS-4a · REQ-001 — 내 정보: 서버 값 문구 조합 · 서명 대기 표시
import Testing
@testable import Pum

struct MyInfoTests {
    let s = MyInfoState.sample

    @Test func 소속_사업장_머리는_개수() {
        #expect(s.workplaceHeader == "소속 사업장 3")
        var empty = s
        empty.workplaces = []
        #expect(empty.workplaceHeader == "소속 사업장 0")
    }

    @Test func 사업장_둘째_줄은_서버_값_조합() {
        #expect(s.workplaces[0].subtitle == "직원 · 시급 12,000원 · 계약 체결")
        #expect(s.workplaces[2].subtitle == "직원 · 시급 15,000원 · 계약 체결")
    }

    @Test func 서명_대기_사업장은_안내_문구가_둘째_줄이다() {
        let w = s.workplaces[1]
        #expect(w.hasAttention)
        #expect(w.subtitle == "변경 계약서 서명 대기")
        #expect(w.accessibilityText == "B카페 서면점, 변경 계약서 서명 대기")
        #expect(!s.workplaces[0].hasAttention)
    }

    @Test func 값_행_문구() {
        #expect(s.personalWageText == "시급 12,000원")
        #expect(s.contractCountText == "3건")
        #expect(s.healthCertText == "보건증 42일")
        #expect(s.bankText == "카카오뱅크 ****821")
    }

    @Test func 보건증_값이_없으면_표시_없음() {
        var t = s
        t.healthCertDaysLeft = nil
        #expect(t.healthCertText == nil)
    }

    @Test func 계정_아바타_글자() {
        #expect(s.avatarInitial == "종")
        #expect(s.accountLine == "010-4821-7733 · 카카오 로그인")
    }
}
