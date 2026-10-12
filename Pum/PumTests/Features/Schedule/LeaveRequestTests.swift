// UI-IOS-10i · REQ-042 — 휴무 신청: 원문 값 · 방식 선택 · 사유 자르기 · 한 번만 보내기 · 음성 안내문
import Testing
@testable import Pum

struct LeaveRequestTests {
    @Test func 캡처_상태는_원문_값() {
        let s = LeaveRequestState.sample
        #expect(s.shiftTitle == "10월 23일 금 · 17:00 – 22:00")
        #expect(s.shiftSubtitle == "종민김밥 본점 · 예정 근무")
        #expect(s.methods.map(\.title) == ["무급 휴무", "연차 사용"])
        #expect(s.methods[1].detail == "지금 0시간 · 11월 6일에 3.6시간 생겨요")
        #expect(s.colleaguesText == "같은 사업장 동료 4명에게")
        #expect(LeaveRequestState.notice == "사장님이 승인하기 전까지는 예정대로 근무예요")
    }

    @Test func 시작값은_무급_휴무_대타_켬() {
        let d = LeaveRequestDraft()
        #expect(d.method == .unpaid && d.withSubstitute && d.reason.isEmpty)
    }

    @Test func 방식_선택_서버가_막은_것은_바꾸지_않는다() {
        var d = LeaveRequestDraft()
        var annual = LeaveRequestState.sample.methods[1]
        annual.isSelectable = false
        d.select(annual)
        #expect(d.method == .unpaid)
        annual.isSelectable = true
        d.select(annual)
        #expect(d.method == .annual)
    }

    @Test func 보내는_값은_근무_방식_대타_사유() {
        var d = LeaveRequestDraft(method: .annual, withSubstitute: false, reason: "  병원 예약이 있어요 ")
        var r = d.request(for: .sample)
        #expect(r == LeaveRequest(shiftId: "shift-1023", method: .annual, withSubstitute: false, reason: "병원 예약이 있어요"))
        d.reason = "   "
        r = d.request(for: .sample)
        #expect(r.reason == nil)
    }

    @Test func 사유는_200자로_자른다() {
        let long = String(repeating: "가", count: 250)
        #expect(LeaveRequestState.clampedReason(long).count == 200)
        #expect(LeaveRequestState.clampedReason("짧아요") == "짧아요")
    }

    @Test func 한_번만_보내고_실패일_때만_푼다() {
        var lock = LeaveRequestLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first && !second && lock.isSending)
        lock.finish(success: true)
        #expect(lock.isSending)
        lock.finish(success: false)
        #expect(!lock.isSending)
    }

    @Test func 음성_안내문() {
        let s = LeaveRequestState.sample
        #expect(LeaveRequestState.optionAccessibility(s.methods[0], isOn: true) == "무급 휴무, 이날 근무시간은 급여에서 빠져요, 선택됨")
        #expect(LeaveRequestState.optionAccessibility(s.methods[1], isOn: false).hasSuffix("선택 안 됨"))
        #expect(LeaveRequestState.substituteAccessibility(isOn: true) == "대타 요청도 같이 보내기, 켬")
        #expect(LeaveRequestState.substituteAccessibility(isOn: false) == "대타 요청도 같이 보내기, 끔")
    }
}
