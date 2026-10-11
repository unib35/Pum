// UI-IOS-2k · REQ-043 — 추가 근무 요청 받음: 서버 값 표시 · 안내 문구 · 한 번만 처리 · 음성 안내
import Testing
@testable import Pum

struct ExtraShiftOfferTests {
    @Test func 캡처_상태는_원문_값() {
        let s = ExtraShiftOfferState.sample
        #expect(s.expectedPayText == "81,000원")
        #expect(s.payBasisText + (s.premiumText ?? "") == "4.5h × 12,000 × 1.5배")
        #expect(s.week.count == 7 && s.week[4].kind == .thisRequest)
        #expect(s.weekSummary == "이 주 13.5h → 18h · 금요일 저녁 근무(17–22)는 그대로예요")
        #expect(s.week.map(\.valueText) == ["5h", "–", "5h", "–", "+5h", "–", "–"])
        #expect(s.week[0].labelText == "월 5")
        #expect(s.week[1].labelText == "화") // 근무 없는 날은 요일만(원문)
    }

    @Test func 안내문은_함께_요청된_사람이_있을_때만_앞_문장이_붙는다() {
        var s = ExtraShiftOfferState.sample
        #expect(s.noticeText == "김하늘님에게도 함께 요청됐어요. 먼저 수락한 사람으로 확정되고, 수락하면 스케줄에 바로 추가돼요.")
        s.coRequestedNames = []
        #expect(s.coRequestedText == nil)
        #expect(s.noticeText == ExtraShiftOfferState.confirmNotice)
    }

    @Test func 주간_칸_음성_안내() {
        let w = ExtraShiftOfferState.sample.week
        #expect(w[4].accessibilityText == "금요일 9일, 추가 5시간, 이번 요청")
        #expect(w[0].accessibilityText == "월요일 5일, 5시간")
        #expect(w[1].accessibilityText == "화요일 6일, 근무 없음")
    }

    @Test func 수락_거절은_한_번만_실패하면_풀린다() {
        var s = ExtraShiftOfferState.sample
        let first = s.beginRespond()
        let second = s.beginRespond()
        #expect(first && !second && s.isResponding)
        s.endRespond()
        let third = s.beginRespond()
        #expect(third)
    }
}
