// UI-IOS-19g · REQ-073 — 내 연차: 원문 값 · 읽기 문구
import Testing
@testable import Pum

struct MyLeaveTests {
    @Test func 원문_값() {
        let s = MyLeaveState.sample
        #expect(s.subtitle == "종민김밥 본점 · 주 18시간 · 시간 단위")
        #expect(s.remainingText == "14.4시간")
        #expect(s.perDayText == "하루 3.6시간 기준")
        #expect(s.usedText == "쓴 7.2시간")
        #expect(s.earnedText == "생긴 21.6시간 · 6개월 개근")
        #expect(s.accrualRows.map(\.title) == ["다음에 생기는 날", "1년 미만 연차 사용 기한", "1년이 되는 날"])
        #expect(s.accrualRows.map(\.value) == ["10월 9일 · 3.6시간", "2027.3.8", "2027.3.9 · 54시간"])
        #expect(s.accrualRows[2].detail == "15일 × 3.6시간")
        #expect(s.usedRows.map(\.title) == ["9월 15일 화", "7월 21일 화"])
        #expect(s.usedRows.map(\.value) == ["3.6시간", "3.6시간"])
        #expect(MyLeaveState.requestTitle == "연차로 쉬기")
        #expect(MyLeaveState.footerNotice == "승인 전까지는 예정대로 근무예요")
    }

    @Test func 읽기_문구() {
        let s = MyLeaveState.sample
        #expect(s.summarySpoken == "남은 연차, 14.4시간, 하루 3.6시간 기준, 쓴 7.2시간, 생긴 21.6시간 · 6개월 개근")
        #expect(s.accrualRows[0].spoken == "다음에 생기는 날, 10월 9일 · 3.6시간")
        #expect(s.accrualRows[2].spoken == "1년이 되는 날, 15일 × 3.6시간, 2027.3.9 · 54시간")
    }
}
