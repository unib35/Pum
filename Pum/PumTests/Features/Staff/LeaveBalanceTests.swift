// UI-IOS-10q · REQ-073 — 직원별 연차 현황: 서버 값 표시 · 읽기 문구 · 대상 아님
import Testing
import Foundation
@testable import Pum

struct LeaveBalanceTests {
    let s = LeaveBalanceState.sample

    @Test func 원문_문구() {
        #expect(s.headingText == "2026년 \u{00B7} 입사일 기준")
        #expect(s.staff.map(\.name) == ["이종민", "박서준", "김하늘", "최유나"])
        #expect(s.staff.map(\.remainingText) == ["36시간", "8시간", "0시간", ""])
        #expect(s.staff[2].usageText == "11월 6일 +3.6시간")
        #expect(s.staff[3].descriptionText == "주 12시간 \u{00B7} 15시간 미만")
    }

    @Test func 대상_아님은_숨기지_않고_이유와_함께() {
        #expect(s.staff[3].isEligible == false)
        #expect(s.staff[3].spoken == "최유나, 주 12시간 \u{00B7} 15시간 미만, 대상 아님")
    }

    @Test func 읽기_문구() {
        #expect(s.staff[0].spoken == "이종민, 주 20시간 \u{00B7} 2년 7개월, 남은 연차 36시간, 60시간 중 24시간 씀")
    }

    @Test func 선택_직원_내역() {
        #expect(s.selectedId == "seojun")
        #expect(s.sectionTitle(for: "박서준") == "박서준 \u{00B7} 연차 내역")
        let e = s.entries(for: "seojun")
        #expect(e.map(\.valueText) == ["+54시간", "\u{2212}46시간", "88,000원"])
        #expect(e[0].detail == "15일 \u{00D7} 18/40 \u{00D7} 8시간")
        #expect(e[1].kind == .usage)
        #expect(e[2].isAmount)
        #expect(e[2].spoken == "10월 31일 퇴사 \u{00B7} 남은 8시간, 미사용 연차 수당 \u{00B7} 퇴사 정산으로, 88,000원")
    }

    @Test func 내역_없는_직원은_빈_목록() {
        #expect(s.entries(for: "jongmin").isEmpty)
        #expect(s.entries(for: nil).isEmpty)
        #expect(s.staffMember(id: "yuna")?.name == "최유나")
    }
}
