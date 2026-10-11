// UI-IOS-4b · REQ-092 — 알림 설정: 원문 값 · 잠긴 항목 · 문구
import Testing
@testable import Pum

struct NotificationSettingsTests {
    let s = NotificationSettingsState.sample

    @Test func 원문_값() {
        #expect(s.leadTime == .tenMinutes)
        #expect(s.recordChanges && s.notices && s.payslip && s.payday)
        #expect(s.quietHoursOn)
        #expect(s.quietStatusText == "켜짐")
        #expect(s.quietHoursText == "23:00 – 08:00 · 요청·공지는 아침에 모아서")
    }

    @Test func 출근_전_알림_옵션() {
        #expect(NotificationLeadTime.allCases.map(\.title) == ["없음", "10분", "30분"])
    }

    @Test func 퇴근_리마인드는_사업장_정책_문구() {
        #expect(s.offReminderOn)
        #expect(s.offReminderSubtitle == "예정 퇴근 시각 · +30분 · +1시간 · 사업장 정책")
    }

    @Test func 끌_수_없는_요청_문구() {
        #expect(NotificationSettingsState.alwaysSubtitle == "결정이 필요한 요청은 끌 수 없어요")
    }

    @Test func 값이_바뀌면_달라진다() {
        var t = s
        t.leadTime = .none
        t.payday = false
        #expect(t != s)
        #expect(t.leadTime.title == "없음")
    }
}
