// UI-IOS-6w · REQ-029 · REQ-094 — 점검 중: 원문 값 · 근무 중일 때만 근무 카드 · 퇴근 버튼
import Testing
@testable import Pum

struct MaintenanceTests {
    let s = MaintenanceState.sample

    @Test func 원문_값() {
        #expect(MaintenanceState.title == "서비스 점검 중이에요")
        #expect(s.schedule == "02:00 – 04:00 · 끝나면 자동으로 다시 열려요.")
        #expect(s.rows.map(\.title) == ["출퇴근 기록", "급여 · 명세서 · 요청"])
        #expect(s.rows.map(\.message) == ["이 기기에 저장돼요. 점검이 끝나면 자동으로 보내요.", "점검이 끝나면 다시 볼 수 있어요"])
        #expect(s.rows.map(\.paused) == [false, true])
        #expect(s.rows[0].spoken == "출퇴근 기록, 이 기기에 저장돼요. 점검이 끝나면 자동으로 보내요.")
        #expect(s.rows[1].spoken == "급여 · 명세서 · 요청, 점검 중, 점검이 끝나면 다시 볼 수 있어요")
        #expect(s.working?.title == "근무 중 · 22:00 출근")
        #expect(s.working?.message == "이 기기에 저장됨 · 전송 대기 0건")
    }

    @Test func 근무_카드는_근무_중일_때만() {
        let idle = MaintenanceState(schedule: s.schedule, working: nil, action: nil)
        #expect(s.isWorking)
        #expect(!idle.isWorking)
        #expect(idle.working == nil)
        #expect(idle.rows == s.rows)
    }

    @Test func 퇴근_버튼() {
        #expect(s.action?.title == "퇴근하기")
        #expect(s.action?.kind == .clockOut)
        #expect(s.action?.caption == "누른 시각 그대로 저장돼요")
        let idle = MaintenanceState(schedule: s.schedule, working: nil, action: nil)
        #expect(idle.action == nil)
    }
}
