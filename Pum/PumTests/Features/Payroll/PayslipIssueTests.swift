// UI-IOS-10d · REQ-074 — 급여명세서 발행 데이터: 서버 값 그대로 표시
import Foundation
import Testing
@testable import Pum

struct PayslipIssueTests {
    let s = PayslipIssueState.sample

    @Test func 원문_값() {
        #expect(s.title == "10월 급여명세서")
        #expect(s.waitingText == "발행 대기 4명")
        #expect(s.people.count == 4)
        #expect(s.people.map(\.amountText) == ["1,062,000", "1,218,000", "624,000", "880,000"])
        #expect(s.issueButtonTitle == "3명 발행하기")
        #expect(s.canIssue)
        #expect(s.selectedTiming?.title == "지급 완료 처리할 때")
        #expect(s.requiredItems.count == 6)
    }

    @Test func 부족_정보_행() {
        let p = s.people[3]
        #expect(p.missingText == "생년월일 없음")
        #expect(p.canRequestInfo)
        #expect(p.accessibilityText == "박서준, 880,000원, 생년월일 없음")
        #expect(s.people[0].accessibilityText == "김하늘, 1,062,000원")
    }

    @Test func 필수_항목_읽기() {
        #expect(s.requiredItems[0].displayText == "성명 · 생년월일 3/4")
        #expect(s.requiredItems[0].accessibilityText == "성명 · 생년월일, 4명 중 3명, 확인 필요")
        #expect(s.requiredItems[1].accessibilityText == "지급일, 확인됨")
    }

    @Test func 발행_인원_0이면_비활성() {
        var e = s
        e.issueCount = 0
        #expect(!e.canIssue)
    }
}
