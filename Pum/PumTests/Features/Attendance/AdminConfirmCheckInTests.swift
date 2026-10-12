// UI-IOS-10x · REQ-021 — 관리자 확인 방식: 원문 값 · 읽기 문구
import Testing
@testable import Pum

struct AdminConfirmCheckInTests {
    let s = AdminConfirmCheckInState.sample

    @Test func 원문_글자() {
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.dateText == "10월 6일 화")
        #expect(s.shiftText == "17:00 \u{2013} 22:00")
        #expect(s.statusText == "확인 대기")
        #expect(s.steps.map(\.title) == ["출근 요청", "사장님 확인", "출근 기록"])
        #expect(s.steps.map(\.detail) == ["16:58 \u{00B7} 매장에서 12m", "박민수 \u{00B7} 알림 보냄", "확인되면 16:58로 기록돼요"])
        #expect(s.noticeTitle == "확인 전에도")
        #expect(s.noticeDetail == "근무시간은 요청 시각부터")
        #expect(s.noticeValue == "그대로 근무하면 돼요")
        #expect(AdminConfirmCheckInState.cancelTitle == "요청 취소")
    }

    @Test func 단계_상태는_서버_값() {
        #expect(s.steps.map(\.status) == [.done, .inProgress, .pending])
    }

    @Test func 읽기_문구() {
        #expect(s.stepSpoken(s.steps[1]) == "사장님 확인, 박민수 \u{00B7} 알림 보냄, 진행 중, 3단계 중 2번째")
        #expect(s.stepSpoken(s.steps[0]) == "출근 요청, 16:58 \u{00B7} 매장에서 12m, 완료, 3단계 중 1번째")
        #expect(s.noticeAccessibilityLabel == "확인 전에도, 근무시간은 요청 시각부터, 그대로 근무하면 돼요")
    }
}
