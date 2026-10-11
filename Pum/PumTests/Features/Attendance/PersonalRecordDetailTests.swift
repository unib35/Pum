// UI-IOS-2g · REQ-005 · REQ-006 — 개인 기록 상세: 엔진 값은 조건이 같을 때만 보인다
import Testing
@testable import Pum

struct PersonalRecordDetailTests {
    let s = PersonalRecordDetailState.sample

    @Test func 원문_값() {
        #expect(s.startText == "17:02")
        #expect(s.endText == "22:31")
        #expect(s.wageText == "12,000원")
        #expect(s.recognizedText == "4시간 59분")
        #expect(s.payText == "59,800원")
        #expect(s.subtitle == "종민김밥 · 본인이 입력한 기록이에요")
    }

    @Test func 휴게를_바꾸면_옛_계산값을_숨긴다() {
        var x = s
        x.setBreak(.sixty)
        #expect(x.recognizedText == nil)
        #expect(x.payText == nil)
    }

    @Test func 시간을_바꾸면_숨기고_되돌리면_다시_보인다() {
        var x = s
        x.step(.end, by: 10)
        #expect(x.visibleCalc == nil)
        x.step(.end, by: -10)
        #expect(x.payText == "59,800원")
    }

    @Test func 메모는_계산에_영향이_없다() {
        var x = s
        x.memo = "바뀐 메모"
        #expect(x.payText == "59,800원")
    }

    @Test func 시각은_하루_안에서_돌아간다() {
        var x = s
        x.startMinute = 23 * 60 + 55
        x.step(.start, by: 10)
        #expect(x.startText == "00:05")
        x.step(.start, by: -10)
        #expect(x.startText == "23:55")
    }

    @Test func 저장은_한_번만() {
        var x = s
        let first = x.beginSave()
        let second = x.beginSave()
        #expect(first)
        #expect(!second)
        x.endSave()
        let third = x.beginSave()
        #expect(third)
    }
}
