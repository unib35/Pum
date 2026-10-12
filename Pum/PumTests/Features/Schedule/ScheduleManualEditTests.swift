// UI-IOS-9d · REQ-051 — 직접 조정: 결과 basis 일치 · 되돌리기 · 적용 한 번만 · 막대 비율
import Testing
import Foundation
@testable import Pum

struct ScheduleManualEditTests {
    @Test func 원문_값() {
        let s = ScheduleManualEditState.sample
        #expect(s.title == "금요일 스케줄 편집")
        #expect(s.days.map(\.date) == [12, 13, 14, 15, 16, 17, 18])
        #expect(s.selectedDay == 4)
        #expect(s.cardTitle == "박서준 \u{00B7} 금 +3시간")
        #expect(s.visibleResult?.afterText == "1,287,000원")
        #expect(s.visibleResult?.beforeText == "1,241,000")
        #expect(s.visibleResult?.deltaText == "+46,000")
        #expect(s.visibleResult?.spoken == "1,241,000원에서 1,287,000원, 46,000원 늘어남")
        #expect(s.displayedNeeds == ["오전 1", "오후 2", "저녁 3 \u{2713}"])
        #expect(s.applyTitle == "적용 \u{00B7} 박서준에게 요청")
        #expect(s.shifts[1].spoken == "박서준, 오후 12시부터 오후 10시까지, 오후 7시부터 오후 10시 추가됨")
    }

    @Test func basis가_같을_때만_결과를_보인다() {
        var s = ScheduleManualEditState.sample
        #expect(s.resultIsCurrent)
        #expect(s.canApply)
        let changed = s.setRange(employeeId: 2, start: 12 * 60, end: 21 * 60)
        #expect(changed)
        #expect(!s.resultIsCurrent)
        #expect(s.visibleResult == nil)
        #expect(s.cardTitle == "박서준 \u{00B7} 금") // 이름 줄만
        #expect(!s.canApply)
        #expect(s.canRevert)
        // 엔진이 새 조건으로 다시 계산해 보내면 다시 보인다
        var r = ScheduleManualEditState.sample.result!
        r.basis = s.currentBasis
        s.result = r
        #expect(s.resultIsCurrent)
    }

    @Test func 되돌리기는_원래_근무로() {
        var s = ScheduleManualEditState.sample
        let did = s.revert()
        #expect(did)
        #expect(!s.hasChange)
        #expect(s.shifts[1].endMinutes == 19 * 60)
        #expect(s.cardTitle == nil)
        #expect(!s.canApply)
        #expect(!s.canRevert)
        let again = s.revert()
        #expect(!again)
    }

    @Test func 잘못된_범위는_무시() {
        var s = ScheduleManualEditState.sample
        let same = s.setRange(employeeId: 2, start: 12 * 60, end: 22 * 60)
        let reversed = s.setRange(employeeId: 2, start: 22 * 60, end: 12 * 60)
        let unknown = s.setRange(employeeId: 99, start: 9 * 60, end: 10 * 60)
        #expect(!same && !reversed && !unknown)
    }

    @Test func 적용은_한_번만_실패일_때만_풀린다() {
        var s = ScheduleManualEditState.sample
        let first = s.beginApply()
        let second = s.beginApply()
        #expect(first)
        #expect(!second)
        #expect(s.isApplying)
        #expect(!s.canRevert)
        s.endApply()
        let third = s.beginApply()
        #expect(third)
    }

    @Test func 바뀐_사람이_없으면_버튼_비활성() {
        var s = ScheduleManualEditState.sample
        s.revert()
        let began = s.beginApply()
        #expect(!began)
        #expect(!s.canApply && !s.canRevert)
    }

    @Test func 늘어난_구간() {
        let s = ScheduleManualEditState.sample
        #expect(s.shifts[1].addedRanges == [19 * 60 ..< 22 * 60])
        #expect(s.shifts[0].addedRanges.isEmpty)
    }

    @Test func 막대_비율_9시에서_23시_범위() {
        let f = ScheduleManualEditState.barFraction(start: 12 * 60, end: 19 * 60)
        #expect(f?.lowerBound == 0.2142857142857143 || abs((f?.lowerBound ?? 0) - 3.0 / 14.0) < 1e-9)
        #expect(abs((f?.upperBound ?? 0) - 10.0 / 14.0) < 1e-9)
        // 범위 밖은 잘라낸다
        let clipped = ScheduleManualEditState.barFraction(start: 7 * 60, end: 25 * 60 - 1)
        #expect(clipped == 0.0 ... 1.0)
        // 완전히 밖이면 그리지 않는다
        #expect(ScheduleManualEditState.barFraction(start: 5 * 60, end: 8 * 60) == nil)
        #expect(ScheduleManualEditState.barFraction(start: 23 * 60 + 30, end: 24 * 60 - 1) == nil)
        #expect(ScheduleManualEditState.tickFraction(hour: 9) == 0)
        #expect(ScheduleManualEditState.tickFraction(hour: 23) == 1)
    }

    @Test func 요일을_바꾸면_이전_결과는_버린다() {
        var s = ScheduleManualEditState.sample
        #expect(s.resultIsCurrent)
        s.select(day: 5)
        #expect(!s.resultIsCurrent)
        #expect(s.result == nil)
    }

    @Test func 적용_중에는_편집되지_않는다() {
        var s = ScheduleManualEditState.sample
        let began = s.beginApply()
        let changed = s.setRange(employeeId: 1, start: 10 * 60, end: 15 * 60)
        s.select(day: 5)
        #expect(began && !changed && s.selectedDay == 4)
    }

    @Test func 차이가_0이면_부호_없음() {
        var r = ScheduleManualEditState.sample.result!
        r.deltaWon = 0
        #expect(r.deltaText == "0")
    }
}
