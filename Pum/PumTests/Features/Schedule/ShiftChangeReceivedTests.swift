// UI-IOS-17f · REQ-050 — 근무 변경 요청 받음: 원문 값 · 읽기 문구 · 처리 중 표시는 누른 버튼만
import Testing
@testable import Pum

struct ShiftChangeReceivedTests {
    @Test func 캡처_상태는_원문_값() {
        let s = ShiftChangeReceivedState.sample
        #expect(s.sentAtText == "10월 4일 14:20")
        #expect(s.senderText == "박민수 사장님 · 종민김밥 본점")
        #expect(s.dateText == "10월 7일 수")
        #expect(s.beforeTimeText == "17:00 – 22:00" && s.afterTimeText == "18:00 – 22:00")
        #expect(s.reason == "저녁 단체 예약 취소")
        #expect(s.creditedText == "4h 30m → 3h 30m" && s.payDeltaText == "−12,000원")
        #expect(ShiftChangeReceivedState.footerNotice == "응답하기 전까지는 기존 근무예요")
        #expect(!s.isResponding)
    }

    @Test func 읽기_문구() {
        let s = ShiftChangeReceivedState.sample
        #expect(s.timesAccessibilityText == "기존 17:00부터 22:00, 변경 18:00부터 22:00")
        #expect(s.payAccessibilityText == "예상 급여, 12,000원 줄어요")
        #expect(s.creditedAccessibilityText == "인정 근무, 4시간 30분에서 3시간 30분")
    }

    @Test func 늘어나는_급여는_늘어요로_읽는다() {
        let s = ShiftChangeReceivedState(sentAtText: "", senderInitial: "박", senderText: "", dateText: "",
                                         beforeTimeText: "", afterTimeText: "", reason: "",
                                         creditedText: "", payDeltaText: "+6,000원")
        #expect(s.payAccessibilityText == "예상 급여, 6,000원 늘어요")
    }

    @Test func 처리_중_표시는_누른_버튼만() {
        let s = ShiftChangeReceivedState.sample
        let busy = s.beginning(.accept)
        #expect(busy?.isLoading(.accept) == true)
        #expect(busy?.isLoading(.decline) == false)
        #expect(busy?.isResponding == true)
        let declined = s.beginning(.decline)
        #expect(declined?.isLoading(.decline) == true && declined?.isLoading(.accept) == false)
    }

    @Test func 처리_중에는_다시_시작할_수_없고_실패하면_풀린다() {
        let busy = ShiftChangeReceivedState.sample.beginning(.accept)
        #expect(busy?.beginning(.decline) == nil)
        #expect(busy?.beginning(.accept) == nil)
        #expect(busy?.ended().isResponding == false)
    }
}
