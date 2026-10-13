// UI-IOS-21a · 21b · REQ-076 · DEC-003 — 원문 값 · 되돌리기 잠금 규칙 · 읽기 문구
import Testing
@testable import Pum

struct PaymentUndoTests {
    @Test func 원문_값_21a() {
        let s = PaymentUndoState.sample
        #expect(s.monthText == "10월분 \u{00B7} 지급일 11월 10일")
        #expect(s.countText == "직원 3명")
        #expect(s.rows.map(\.amountText) == ["1,062,000원", "880,000원", "1,118,610원"])
        #expect(s.rows.map(\.statusText) == ["지급 완료", "지급 대기", "지급 완료"])
        #expect(s.rows.map(\.colorIndex) == [1, 3, 0])
        #expect(s.undoTarget?.summaryText == "김하늘 \u{00B7} 1,062,000원 \u{00B7} 11월 10일 14:20에 지급 완료로 처리했어요")
        #expect(PaymentUndoState.undoNotes == ["직원에게 알림이 가지 않아요", "활동 기록에 남아요"])
        #expect(s.activities.isEmpty)
        #expect(s.toastText == nil)
    }

    @Test func 원문_값_21b() {
        let s = PaymentUndoState.reverted
        #expect(s.row("haneul")?.isPaid == false)
        #expect(s.row("jongmin")?.isPaid == true)
        #expect(s.undoTarget == nil)
        #expect(s.activities.count == 2)
        #expect(s.activities[0].title == "14:32 \u{00B7} 김하늘 지급 완료 취소")
        #expect(s.activities[1].detail == "박민수")
        #expect(s.toastText == "지급 대기로 되돌렸어요")
    }

    @Test func 읽기_문구() {
        let s = PaymentUndoState.sample
        #expect(s.rows[0].spokenText == "김하늘, 국민은행 \u{2022}\u{2022}1234, 1,062,000원, 지급 완료")
        #expect(s.rows[1].spokenText == "박서준, 신한은행 \u{2022}\u{2022}5521, 880,000원, 지급 대기")
        #expect(PaymentUndoState.reverted.activities[0].spokenText == "14:32 \u{00B7} 김하늘 지급 완료 취소, 박민수 \u{00B7} 지급 대기로")
    }

    @Test func 되돌리기_한_번만() {
        var lock = PaymentUndoLock()
        let first = lock.begin()
        #expect(first)
        #expect(lock.isSending)
        let second = lock.begin()
        #expect(!second) // 보내는 중엔 다시 못 한다
    }

    @Test func 실패하면_풀리고_성공하면_잠근_채() {
        var failed = PaymentUndoLock()
        _ = failed.begin()
        failed.finish(success: false)
        #expect(!failed.isLocked)
        var ok = PaymentUndoLock()
        _ = ok.begin()
        ok.finish(success: true)
        #expect(ok.isDone && ok.isLocked && !ok.isSending)
        let again = ok.begin()
        #expect(!again)
        ok.reset()
        #expect(!ok.isLocked)
    }
}
