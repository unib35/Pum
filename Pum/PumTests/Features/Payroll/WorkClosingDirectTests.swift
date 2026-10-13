// UI-IOS-20g · REQ-007 — 근무 마감(앱 없는 직원 확인) 문구 · 마감 가능 · 잠금
import Testing
@testable import Pum

struct WorkClosingDirectTests {
    let s = WorkClosingDirectState.sample

    @Test func 원문_문구() {
        #expect(s.title == "9월 근무 마감")
        #expect(s.periodText == "9월 1일 \u{2013} 30일")
        #expect(s.appRecordSubtitle == "직원 3명 \u{00B7} 확인할 것 0건")
        let p = s.people[0]
        #expect(p.confirmTitle(month: s.month) == "김민지 \u{00B7} 9월 기록 확인")
        #expect(p.confirmSubtitle == "앱 없음 \u{00B7} 예정대로 11일 \u{00B7} 고친 날 2일")
        #expect(p.editedTitle == "김민지 \u{00B7} 고친 날 2일")
        #expect(p.scheduledTitle == "예정대로 11일")
        #expect(p.scheduledPattern == "월 \u{00B7} 수 \u{00B7} 금 17\u{2013}22")
        #expect(p.editedDays.map(\.dateText) == ["9월 25일 금", "9월 16일 수"])
        #expect(p.editedDays[1].detailText == "15:50 \u{2013} 22:00 \u{00B7} +1시간 10분")
    }

    @Test func 남은_건이_있으면_마감_못_함() {
        #expect(!s.canClose)
        #expect(s.closeTitle == "근무 마감 \u{00B7} 1건 남음")
    }

    @Test func 확인할_직원이_없으면_마감_가능() {
        let a = WorkClosingDirectState.allConfirmed
        #expect(a.canClose && a.people.isEmpty)
        #expect(a.closeTitle == "9월 근무 마감")
        #expect(a.closeHint == nil)
    }

    @Test func 읽기_문구() {
        #expect(s.closeHint == "확인할 것이 1건 남았어요")
        #expect(s.closeAccessibilityLabel == "9월 근무 마감, 1건 남아 마감할 수 없음")
        #expect(s.people[0].editedDays[0].spokenText == "9월 25일 금, 결근 \u{00B7} 사유 없음, 고침")
    }

    @Test func 마감은_한_번만_실패일_때만_풀림() {
        var l = WorkClosingDirectLock()
        let blocked = l.beginClose(canClose: false)
        #expect(!blocked)
        let first = l.beginClose(canClose: true)
        let second = l.beginClose(canClose: true)
        #expect(first && !second)
        l.finishClose(success: true)
        #expect(l.isClosing)
        l.finishClose(success: false)
        #expect(!l.isClosing)
    }

    @Test func 확인_처리_중에는_다른_확인과_마감이_막힘() {
        var l = WorkClosingDirectLock()
        let a = l.beginConfirm(id: "a")
        let b = l.beginConfirm(id: "b")
        let c = l.beginClose(canClose: true)
        #expect(a && !b && !c)
        #expect(l.confirmingID == "a")
        l.finishConfirm()
        #expect(l.confirmingID == nil)
    }
}
