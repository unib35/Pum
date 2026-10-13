// UI-IOS-17g · REQ-042 — 대타 요청 받음: 원문 값 · 읽기 문구 · 처리 중 표시는 누른 버튼만
import Testing
@testable import Pum

struct CoverRequestReceivedTests {
    @Test func 캡처_상태는_원문_값() {
        let s = CoverRequestReceivedState.sample
        #expect(s.sentAtText == "어제 21:40 · 먼저 수락한 1명")
        #expect(s.senderInitial == "종" && s.senderText == "이종민 · 학교 시험 기간")
        #expect(s.weekdayText == "월" && s.dayText == "12" && s.timeText == "17:00 – 22:00")
        #expect(s.placeText == "종민김밥 본점 · 휴게 30분")
        #expect(s.weekHoursText == "23h → 27h 30m")
        #expect(s.payNote == "소정근로 초과 2.5h 50% 가산 포함" && s.payDeltaText == "+63,250원")
        #expect(s.steps.map(\.title) == ["내가 수락", "사장님 승인", "내 스케줄에 추가"])
        #expect(s.steps[1].note == "승인 전까지는 이종민 근무예요")
        #expect(s.steps.allSatisfy { !$0.isDone })
        #expect(s.canAccept && !s.isResponding)
        #expect(CoverRequestReceivedState.title == "대타 요청")
    }

    @Test func 읽기_문구() {
        let s = CoverRequestReceivedState.sample
        #expect(s.shiftAccessibilityText == "10월 12일 월, 17:00부터 22:00, 종민김밥 본점 · 휴게 30분")
        #expect(s.steps[0].spoken == "1단계, 내가 수락, 아직")
        #expect(s.steps[1].spoken == "2단계, 사장님 승인, 아직, 승인 전까지는 이종민 근무예요")
        #expect(s.payAccessibilityText == "예상 급여, 63,250원 늘어요, 소정근로 초과 2.5h 50% 가산 포함")
        #expect(s.weekHoursAccessibilityText == "그 주 내 근무, 23시간에서 27시간 30분")
    }

    @Test func 처리_중_표시는_누른_버튼만() {
        let s = CoverRequestReceivedState.sample
        let busy = s.beginning(.accept)
        #expect(busy?.isLoading(.accept) == true)
        #expect(busy?.isLoading(.decline) == false)
        #expect(busy?.isResponding == true)
        let declined = s.beginning(.decline)
        #expect(declined?.isLoading(.decline) == true && declined?.isLoading(.accept) == false)
    }

    @Test func 처리_중에는_다시_시작하지_않고_실패하면_풀린다() {
        let busy = CoverRequestReceivedState.sample.beginning(.accept)
        #expect(busy?.beginning(.decline) == nil)
        #expect(busy?.beginning(.accept) == nil)
        #expect(busy?.ended().isResponding == false)
    }

    @Test func 수락할_수_없으면_수락만_막힌다() {
        let full = CoverRequestReceivedState(
            sentAtText: "", senderInitial: "종", senderName: "이종민", reason: "", monthText: "10월",
            weekdayText: "월", dayText: "12", timeText: "", placeText: "", weekHoursText: "",
            payNote: "", payDeltaText: "", steps: [], canAccept: false)
        #expect(full.beginning(.accept) == nil)
        #expect(full.beginning(.decline)?.isLoading(.decline) == true)
    }
}
