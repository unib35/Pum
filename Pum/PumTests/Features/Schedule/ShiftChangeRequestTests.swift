// UI-IOS-10j · REQ-042 — 근무 변경 요청: 원문 값 · 30분 스텝 · 출근 < 퇴근 경계 · basis 일치 · 보내기 조건 · 한 번만
import Testing
@testable import Pum

struct ShiftChangeRequestTests {
    private let s = ShiftChangeRequestState.sample

    @Test func 캡처_상태는_원문_값() {
        #expect(s.dateTitle == "10월 21일 수")
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.currentRangeText == "17:00 \u{2013} 22:00")
        #expect(s.preview?.text == "근무 5시간 그대로 \u{00B7} 22시 이후 1시간")
        #expect(ShiftChangeRequestState.clock(18 * 60) == "18:00")
        #expect(ShiftChangeRequestState.spokenClock(18 * 60) == "18시")
        #expect(ShiftChangeRequestState.spokenClock(18 * 60 + 30) == "18시 30분")
    }

    @Test func 한_칸은_30분() {
        var d = ShiftChangeDraft(start: 17 * 60, end: 22 * 60)
        let movedStart = d.move(.start, by: 1)
        #expect(movedStart)
        #expect(d.start == 17 * 60 + 30)
        let movedEnd = d.move(.end, by: -1)
        #expect(movedEnd)
        #expect(d.end == 21 * 60 + 30)
    }

    @Test func 출근은_퇴근보다_앞일_때만_움직인다() {
        var d = ShiftChangeDraft(start: 21 * 60 + 30, end: 22 * 60)
        #expect(!d.canMove(.start, by: 1))
        let blocked = d.move(.start, by: 1)
        #expect(!blocked)
        #expect(d.start == 21 * 60 + 30)
        #expect(!d.canMove(.end, by: -1))
        #expect(d.canMove(.end, by: 1))
    }

    @Test func 하루_범위는_0시에서_24시() {
        let a = ShiftChangeDraft(start: 0, end: 60)
        #expect(!a.canMove(.start, by: -1))
        let b = ShiftChangeDraft(start: 23 * 60, end: 24 * 60)
        #expect(!b.canMove(.end, by: 1))
        #expect(b.canMove(.end, by: -1))
    }

    @Test func 반영되면은_basis가_같을_때만() {
        let same = ShiftChangeDraft(start: 18 * 60, end: 23 * 60)
        #expect(same.previewText(for: s) == "근무 5시간 그대로 \u{00B7} 22시 이후 1시간")
        let other = ShiftChangeDraft(start: 18 * 60 + 30, end: 23 * 60)
        #expect(other.previewText(for: s) == nil)
        var noPreview = s
        noPreview.preview = nil
        #expect(same.previewText(for: noPreview) == nil)
    }

    @Test func 바뀐_게_없으면_상자_숨김_보내기_비활성() {
        var state = s
        state.preview = ShiftChangePreview(startMinutes: 17 * 60, endMinutes: 22 * 60, text: "그대로")
        let d = ShiftChangeDraft(start: 17 * 60, end: 22 * 60, reason: "사유")
        #expect(!d.isChanged(from: state))
        #expect(d.previewText(for: state) == nil)
        #expect(!d.canSend(for: state))
    }

    @Test func 사유가_비면_보낼_수_없다() {
        var d = ShiftChangeDraft(start: 18 * 60, end: 23 * 60)
        #expect(!d.canSend(for: s))
        d.reason = "   "
        #expect(!d.canSend(for: s))
        d.reason = "수요일 수업이 18시에 끝나요"
        #expect(d.canSend(for: s))
    }

    @Test func 보내는_값은_근무_시간_사유() {
        let d = ShiftChangeDraft(start: 18 * 60, end: 23 * 60, reason: "  수요일 수업이 18시에 끝나요 ")
        #expect(d.request(for: s) == ShiftChangeRequest(shiftId: "shift-1021", startMinutes: 1080, endMinutes: 1380, reason: "수요일 수업이 18시에 끝나요"))
    }

    @Test func 사유는_200자까지() {
        let long = String(repeating: "가", count: 250)
        #expect(ShiftChangeRequestState.clampedReason(long).count == 200)
        #expect(ShiftChangeRequestState.clampedReason("짧아요") == "짧아요")
    }

    @Test func 보내기는_한_번만_실패일_때만_푼다() {
        var lock = ShiftChangeLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish(success: true)
        #expect(lock.isSending)
        lock.finish(success: false)
        #expect(!lock.isSending)
    }
}
