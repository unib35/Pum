// UI-IOS-10g · REQ-075 — 정정 재계산: 서버 값 표시 · 선택 · 한 번만 확정
import Testing
import Foundation
@testable import Pum

struct CorrectionRecalcTests {
    let s = CorrectionRecalcState.sample

    @Test func 원문_문구() {
        #expect(s.summaryTitle == "김하늘 \u{00B7} 8월 실지급액")
        #expect(s.beforeText == "1,062,000")
        #expect(s.afterText == "1,084,800원")
        #expect(s.deltaText == "+22,800원")
        #expect(s.footnote == "김하늘님에게 정정 명세서와 알림이 가요")
        #expect(s.lines.map(\.amountText) == ["+11,500", "+5,750", "+5,750", "\u{2212}200"])
        #expect(s.lines[3].detail == nil)
    }

    @Test func 읽기_문구() {
        #expect(s.summaryAccessibility == "김하늘 8월 실지급액, 1,062,000원에서 1,084,800원, 22,800원 늘어남")
        #expect(s.lines[3].accessibilityText == "고용보험, 200원 공제")
        #expect(s.choiceAccessibility(s.choices[1]) == "따로 지급, 지급 대기 목록에 추가, 2개 중 2번째")
    }

    @Test func 기본_선택은_서버_값() {
        #expect(s.selectedChoiceID == "withNext")
    }

    @Test func 선택_바꾸기() {
        var x = s
        x.select("separate")
        #expect(x.selectedChoiceID == "separate")
        x.select("없는-id")
        #expect(x.selectedChoiceID == "separate")
    }

    @Test func 확정은_한_번만() {
        var x = s
        let first = x.beginConfirm()
        let second = x.beginConfirm()
        #expect(first)
        #expect(!second)
        x.select("separate") // 처리 중에는 안 바뀐다
        #expect(x.selectedChoiceID == "withNext")
        x.endConfirm()
        #expect(x.canConfirm)
    }
}
