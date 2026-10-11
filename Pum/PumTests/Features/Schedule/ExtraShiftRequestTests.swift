// UI-IOS-2j · REQ-043 — 추가 근무 요청: 선택 수 · 보내기 조건 · 한 번만 보내기 · 문구
import Testing
@testable import Pum

struct ExtraShiftRequestTests {
    @Test func 캡처_상태는_원문_값() {
        let s = ExtraShiftRequestState.sample
        #expect(s.dateText == "10월 9일 (금)" && s.holidayName == "한글날")
        #expect(s.selectedCount == 2)
        #expect(s.sendTitle == "2명에게 요청 보내기")
        #expect(s.recipientsTail == " · 1명 필요 · 먼저 수락한 사람으로 확정")
        #expect(s.candidates[0].detailText == "그 주 13.5h → 18h · 12,000원/h")
        #expect(s.candidates[2].detailText == "그 주 이미 28h · 11,000원/h")
    }

    @Test func 원_표기는_정수_쉼표() {
        #expect(ExtraShiftFormat.won(12_000) == "12,000")
        #expect(ExtraShiftFormat.won(950) == "950")
        #expect(ExtraShiftFormat.won(1_234_567) == "1,234,567")
    }

    @Test func 음성_안내문() {
        let s = ExtraShiftRequestState.sample
        #expect(s.candidates[0].accessibilityText == "이종민, 그 주 13.5시간에서 18시간, 시급 12,000원, 선택됨")
        #expect(s.candidates[2].accessibilityText.hasSuffix("선택 안 됨"))
    }

    @Test func 선택이_0명이면_보낼_수_없다() {
        var s = ExtraShiftRequestState.sample
        s.toggle(candidate: 1); s.toggle(candidate: 2)
        #expect(s.selectedCount == 0 && !s.canSend)
        let began = s.beginSend()
        #expect(!began)
        s.toggle(candidate: 3)
        #expect(s.sendTitle == "1명에게 요청 보내기" && s.canSend)
    }

    @Test func 보내기는_한_번만_실패하면_풀린다() {
        var s = ExtraShiftRequestState.sample
        let first = s.beginSend()
        let second = s.beginSend()
        #expect(first && !second && s.isSending)
        s.endSend()
        let third = s.beginSend()
        #expect(third)
    }

    @Test func 사유는_하나만_다시_누르면_해제() {
        var s = ExtraShiftRequestState.sample
        s.toggle(reason: .festival)
        #expect(s.reason == .festival)
        s.toggle(reason: .festival)
        #expect(s.reason == nil)
    }

    @Test func 공휴일_이름_없으면_nil이고_사유_칩_문구() {
        var s = ExtraShiftRequestState.sample
        s.holidayName = nil
        #expect(s.holidayName == nil)
        #expect(ExtraShiftReason.allCases.map(\.title) == ["공휴일 영업", "단체 예약", "명절", "결원 대체", "기타"])
    }
}
