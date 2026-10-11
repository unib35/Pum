// UI-IOS-5a — 미인증 사업장 홈 단계 · 문구
import Foundation
import Testing
@testable import Pum

struct OwnerHomeUnverifiedTests {
    let s = OwnerHomeUnverifiedState.sample

    @Test func 시작_준비_4단계_순서() {
        #expect(s.steps.map(\.id) == ["workplace", "clockin", "shifts", "invite"])
        #expect(s.steps.map(\.status) == [.done, .done, .todo, .locked])
        #expect(s.doneCount == 2)
    }

    @Test func 동작_버튼은_미완료와_잠김에만() {
        #expect(s.steps.map(\.actionTitle) == [nil, nil, "만들기", "인증"])
    }

    @Test func 직원_0명이면_인건비_제목만_있고_금액은_없다() {
        #expect(s.staffCountText == "직원 0명")
        #expect(s.todayStaffCountText == "직원 0명")
        #expect(s.payrollTitle == "10월 예상 인건비")
    }

    @Test func 보이스오버_문구() {
        #expect(s.steps[0].accessibilityText == "사업장 정보, 완료")
        #expect(s.steps[3].accessibilityText == "직원 초대, 사업장 인증 후, 잠김")
        #expect(s.steps[2].accessibilityText == "근무 시간대, 오전 · 오후 · 마감 같은 기본 근무")
    }
}
