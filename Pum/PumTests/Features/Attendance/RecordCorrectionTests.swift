// UI-IOS-10f · REQ-075 — 마감 후 정정: 바뀐 행 · 보내기 조건 · 문구
import Testing
import Foundation
@testable import Pum

struct RecordCorrectionTests {
    let s = RecordCorrectionState.sample
    let reason = RecordCorrectionState.sampleReason

    @Test func 원문_문구() {
        #expect(s.headline == "8월 28일 금 \u{00B7} 김하늘")
        #expect(s.originalStartText == "16:58")
        #expect(s.originalEndText == "22:00")
        #expect(s.endText == "23:00")
        #expect(RecordCorrectionState.reasonSection == "정정 사유 \u{00B7} 필수")
    }

    @Test func 바뀐_행만_표시() {
        #expect(!s.startChanged)
        #expect(s.endChanged)
    }

    @Test func 퇴근_행_읽기() {
        #expect(s.rowAccessibility(.end) == "퇴근, 오후 10시에서 오후 11시로")
        #expect(s.rowAccessibility(.start) == "출근, 오후 4시 58분")
        #expect(s.lockAccessibility == "8월 마감됨, 잠김")
    }

    @Test func 보내기_조건() {
        #expect(s.canRecalculate(reason: reason))
        #expect(!s.canRecalculate(reason: "  \n "))
        let same = RecordCorrectionState(dateText: "a", employeeName: "b", statusText: "c", lockText: "d",
                                         sourceTitle: "e", sourceSubtitle: "f",
                                         originalStartMinute: 600, originalEndMinute: 700)
        #expect(!same.canRecalculate(reason: reason)) // 바뀐 시각 없음
    }

    @Test func 출근이_퇴근보다_늦으면_막는다() {
        var x = s
        x.startMinute = 23 * 60 + 30
        #expect(!x.isOrderValid)
        #expect(!x.canRecalculate(reason: reason))
        x.startMinute = 23 * 60
        #expect(!x.canRecalculate(reason: reason)) // 같은 시각
    }

    @Test func 한_번만_보내고_실패하면_풀린다() {
        var x = s
        let first = x.beginSend(reason: reason)
        #expect(first)
        #expect(x.isSending)
        let second = x.beginSend(reason: reason)
        #expect(!second)
        x.endSend()
        #expect(!x.isSending)
        let third = x.beginSend(reason: reason)
        #expect(third)
    }

    @Test func 정정_값은_사유를_다듬는다() {
        let c = s.correction(reason: "  이유 \n")
        #expect(c == RecordCorrection(startMinute: 16 * 60 + 58, endMinute: 23 * 60, reason: "이유"))
    }

    @Test func 사유_200자() {
        #expect(RecordCorrectionState.clampedReason(String(repeating: "가", count: 250)).count == 200)
        #expect(RecordCorrectionState.clampedReason("짧음") == "짧음")
    }

    @Test func 시트_결과_반영() {
        var v = PumTimeRangeValue()
        v.startMinutes = 17 * 60
        let x = s.applying(picked: v, field: .start)
        #expect(x.startMinute == 17 * 60)
        #expect(x.endMinute == 23 * 60)
        #expect(x.startChanged)
    }
}
