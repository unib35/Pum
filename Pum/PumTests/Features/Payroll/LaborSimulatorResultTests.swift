// UI-IOS-8e · REQ-052 — 시뮬레이션 결과 문구 · 서버 값 그대로
import Testing
import Foundation
@testable import Pum

struct LaborSimulatorResultTests {
    let s = LaborSimulatorResultState.sample

    @Test func 원문_문구() {
        #expect(s.title == "시뮬레이션 결과")
        #expect(s.compareTitle == "10월 인건비")
        #expect(s.currentText == "4,210,000" && s.afterText == "4,714,000")
        #expect(s.deltaAmountText == "+504,000원")
        #expect(s.deltaPercentSuffix == " \u{00B7} +12.0%")
        #expect(s.weekdayHeader == "요일별 인원 \u{00B7} 월\u{00B7}수\u{00B7}금 저녁")
        #expect(s.recommendTag == "9a")
        #expect(s.addTitle == "새 근무 시간대로 스케줄에 추가")
        #expect(s.saveOnlyTitle + s.saveOnlyNotice == "저장만 하기 \u{00B7} 실제 데이터는 바뀌지 않아요")
    }

    @Test func 요일_일곱_개와_변화() {
        #expect(s.weekdays.map(\.name) == ["월", "화", "수", "목", "금", "토", "일"])
        #expect(s.weekdays.map(\.headcountText) == ["3명", "2명", "3명", "1명", "3명", "2명", "0명"])
        #expect(s.weekdays.map(\.changeText) == ["+1", "\u{2013}", "+1", "\u{2013}", "+1", "\u{2013}", "\u{2013}"])
        #expect(s.weekdays.filter(\.isChanged).map(\.name) == ["월", "수", "금"])
    }

    @Test func 음성_읽기() {
        #expect(s.compareAccessibilityText == "10월 인건비, 현재 4,210,000원, 추가 후 4,714,000원, 504,000원 증가, 12.0퍼센트")
        #expect(s.weekdays[0].accessibilityText == "월요일 3명, 1명 늘어남")
        #expect(s.weekdays[1].accessibilityText == "화요일 2명, 변화 없음")
    }

    @Test func 서버_값_그대로_계산하지_않는다() {
        var t = s
        t.currentAmount = 1_000_000; t.afterAmount = 1_500_000
        t.deltaAmount = 123; t.deltaPercentText = "+99.9%"
        #expect(t.deltaAmountText == "+123원") // 뺄셈 결과가 아니라 서버 값
        #expect(t.deltaPercentSuffix == " \u{00B7} +99.9%")
    }

    @Test func 줄어드는_경우() {
        var t = s
        t.deltaAmount = -300_000; t.deltaPercentText = "\u{2212}7.1%"
        #expect(t.deltaAmountText == "\u{2212}300,000원")
        #expect(t.compareAccessibilityText.hasSuffix("300,000원 감소, 7.1퍼센트"))
        var d = s.weekdays[0]; d.change = -1
        #expect(d.changeText == "\u{2212}1")
        #expect(d.accessibilityText == "월요일 3명, 1명 줄어듦")
    }

    @Test func 변화가_없으면_변화_없음으로_읽는다() {
        var s = LaborSimulatorResultState.sample
        s.afterAmount = s.currentAmount; s.deltaAmount = 0; s.deltaPercentText = "0.0%"
        #expect(s.compareAccessibilityText.hasSuffix("변화 없음"))
    }
}
