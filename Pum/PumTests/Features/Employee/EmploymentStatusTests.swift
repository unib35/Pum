// UI-IOS-6j · REQ-063 — 재직 상태(퇴사) 원문 값 · 사유 선택 · 처리 중 잠금 · 읽기 문구
import Testing
@testable import Pum

struct EmploymentStatusTests {
    let s = EmploymentStatusState.sample

    @Test func 원문_값() {
        #expect(s.targetName == "박서준")
        #expect(s.subtitle == "2026.03.02 입사 · 토·일 09–15 · 시급 11,000원")
        #expect(s.confirmTitle == "퇴사 처리 · 박서준에게 알림")
        #expect(s.rows.map(\.label) == ["퇴사일", "마지막 근무", "남은 근무 일정", "마지막 급여", "근로계약"])
        #expect(s.rows.map(\.value) == ["2027.03.31 (수)", "2027.03.28 (일)", "4건 · 퇴사일 후 자동 취소", "4월 10일 · 3월분 정산", "2027.03.31 종료"])
        #expect(EmploymentStatus.allCases.map(\.title) == ["재직", "휴직", "퇴사"])
        #expect(LeaveReason.allCases.map(\.title) == ["계약 만료", "자진 퇴사", "기타"])
        #expect(s.initialDraft == EmploymentStatusDraft(status: .left, reason: .contractEnd))
    }

    @Test func 사유_선택은_초안만_바꾼다() {
        let d = s.choosing(s.initialDraft, reason: .voluntary)
        #expect(d.reason == .voluntary && d.status == .left)
        #expect(s.hasChanges(d))
        let back = s.choosing(d, reason: .contractEnd)
        #expect(!s.hasChanges(back))
        #expect(s.reason == .contractEnd)
    }

    @Test func 상태_선택() {
        let d = s.choosing(s.initialDraft, status: .leave)
        #expect(d.status == .leave && d.reason == .contractEnd)
    }

    @MainActor @Test func 처리_중_잠금() {
        let processing = EmploymentStatusView(state: s, isProcessing: true)
        #expect(processing.isProcessing && !processing.isDone)
        let done = EmploymentStatusView(state: s, isDone: true)
        #expect(done.isDone)
    }

    @Test func 읽기_문구() {
        #expect(s.headerSpoken == "박서준, 2026.03.02 입사 · 토·일 09–15 · 시급 11,000원")
        #expect(s.rows[0].spoken == "퇴사일, 2027.03.31 (수)")
        #expect(s.noticeSpoken == "퇴사 후에도 근무기록 · 명세서 · 계약서는 법정 보존 기간(3년) 동안 보관되고, 직원도 자기 문서함에서 계속 볼 수 있어요. 다시 함께하려면 재초대하면 돼요.")
    }
}
