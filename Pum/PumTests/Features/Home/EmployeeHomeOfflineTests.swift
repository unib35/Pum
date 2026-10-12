// UI-IOS-6q · REQ-029 · REQ-095 — 근무 중 홈 오프라인 상태 값
import Foundation
import Testing
@testable import Pum

struct EmployeeHomeOfflineTests {
    @Test func 기본은_오프라인_아님_1av_그대로() {
        #expect(EmployeeHomeWorkingState.sample.offline == nil)
        #expect(EmployeeHomeWorkingState.sample.nowMinute == 18 * 60 + 40)
    }

    @Test func 원문_값() {
        let s = EmployeeHomeWorkingState.offline
        let o = s.offline
        #expect(o != nil)
        #expect(o?.bannerTitle == "인터넷에 연결되어 있지 않아요")
        #expect(o?.retryTitle == "다시 시도")
        #expect(o?.badgeText == "전송 대기")
        #expect(o?.savedNote == "출근 16:58 · 이 기기에 저장됨")
        #expect(o?.pendingTitle == "전송 대기 1건")
        #expect(o?.pending == ["출근 16:58 · 매장 QR · 위치 확인됨"])
        #expect(o?.pendingNote == "기록 시각은 누른 순간으로 저장돼요. 나중에 전송돼도 바뀌지 않아요.")
        #expect(o?.clockOutHint == "연결이 없어도 퇴근을 기록할 수 있어요")
        #expect(s.elapsedMinutes == 12)
        #expect(WorkingFormat.elapsedLabel(s.elapsedMinutes) == "12분 근무 중")
    }

    @Test func 건수는_목록_길이() {
        let o = EmployeeHomeOffline(pending: ["a", "b"], savedNote: "x")
        #expect(o.pendingTitle == "전송 대기 2건")
    }

    @Test func 퇴근하기는_오프라인에서도_눌린다() {
        var count = 0
        let view = EmployeeHomeWorkingView(state: .offline, onClockOut: { count += 1 })
        view.onClockOut()
        #expect(count == 1)
    }

    @Test func 오프라인이어도_자동_퇴근은_없다() {
        let s = EmployeeHomeWorkingState.offline.with(now: 23 * 60)
        #expect(s.offline != nil)
        #expect(s.progress == 1)
        #expect(s.elapsedMinutes == 6 * 60 + 2)
    }
}
