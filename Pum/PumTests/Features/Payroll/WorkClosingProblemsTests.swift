// UI-IOS-8b · REQ-028 · REQ-070 — 문제 기록 처리 문구 · 행 잠금
import Testing
@testable import Pum

struct WorkClosingProblemsTests {
    let s = WorkClosingProblemsState.sample

    @Test func 원문_문구() {
        #expect(s.title == "처리 필요 5건")
        #expect(s.progressText == "2 / 5")
        #expect(s.remainingHeader == "남은 3건" && s.resolvedHeader == "처리됨 2건")
        #expect(s.footnote == "정상 기록 71건은 정책에 따라 이미 확정돼 있어요.")
        #expect(s.remaining.map(\.badgeText) == ["퇴근 미기록", "연장 1:02", "예정 외 근무"])
        #expect(s.remaining[1].detailText == "예정 22:00 \u{2192} 23:02 \u{00B7} +12,400원")
        #expect(s.resolved.map(\.nameDateText) == ["최유나 \u{00B7} 10/15 수", "김하늘 \u{00B7} 9/30 화"])
    }

    @Test func 막대는_처리_나누기_전체() {
        #expect(s.progress == 0.4)
        var empty = s
        empty.totalCount = 0
        #expect(empty.progress == 0)
    }

    @Test func 종류별_버튼() {
        let r = s.remaining
        #expect(r[0].leadingTitle == "직접 입력" && r[0].leadingAction == nil && r[0].trailingTitle == "확인 요청" && r[0].trailingAction == .confirmRequest)
        #expect(r[1].leadingTitle == "수정" && r[1].leadingAction == nil && r[1].trailingTitle == "인정" && r[1].trailingAction == .approve)
        #expect(r[2].leadingTitle == "거절" && r[2].leadingAction == .reject && r[2].trailingAction == .approve)
    }

    @Test func 음성_안내() {
        #expect(s.remaining[0].accessibilityText == "박서준, 10월 28일 화요일, 퇴근 미기록, 09:03 출근, 예정 퇴근 15:00")
    }

    @Test func 행_잠금은_한_번만() {
        var lock = WorkClosingRowLock()
        let first = lock.begin("p1")
        let second = lock.begin("p1")
        #expect(first)
        #expect(!second)
        #expect(lock.isLocked("p1"))
    }

    @Test func 실패일_때만_풀린다() {
        var lock = WorkClosingRowLock()
        _ = lock.begin("p1")
        lock.finish("p1", success: true)
        #expect(lock.isLocked("p1"))
        lock.finish("p1", success: false)
        #expect(!lock.isLocked("p1"))
        let again = lock.begin("p1")
        #expect(again)
    }

    @Test func 다른_행은_영향_없음() {
        var lock = WorkClosingRowLock()
        _ = lock.begin("p1")
        #expect(!lock.isLocked("p2"))
        let other = lock.begin("p2")
        #expect(other)
        lock.finish("p2", success: false)
        #expect(lock.isLocked("p1"))
    }
}
