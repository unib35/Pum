// UI-IOS-6h · REQ-014 — 역할 바꾸기 · 잠긴 행 · 바뀐 것 판정
import Testing
@testable import Pum

struct ManagerPermissionsTests {
    let s = ManagerPermissionsState.sample

    @Test func 원문_값() {
        #expect(s.saveTitle == "저장 · 김민지에게 알림")
        #expect(s.items(in: .operations).count == 4 && s.items(in: .sensitive).count == 5)
        let d = s.initialDraft
        #expect(d.role == .manager)
        #expect(s.items(in: .operations).allSatisfy { s.isOn($0, in: d) })
        #expect(s.items(in: .sensitive).allSatisfy { !s.isOn($0, in: d) })
        #expect(s.items.filter { s.isLocked($0, in: d) }.map(\.id) == ["payroll-confirm"])
        #expect(!s.hasChanges(d))
    }

    @Test func 역할을_바꾸면_서버_기본값() {
        let d = s.changingRole(s.initialDraft, to: .admin)
        #expect(d.role == .admin && d.enabled == Set(s.items.map(\.id)))
        #expect(s.items.allSatisfy { !s.isLocked($0, in: d) })
        #expect(s.hasChanges(d))
        let back = s.changingRole(d, to: .manager)
        #expect(!s.hasChanges(back))
    }

    @Test func 대표_칸은_초안을_바꾸지_않는다() {
        let d = s.initialDraft
        #expect(s.changingRole(d, to: .owner) == d)
    }

    @Test func 잠긴_행은_바뀌지_않는다() {
        let d = s.initialDraft
        #expect(s.setting(d, id: "payroll-confirm", isOn: true) == d)
        let admin = s.changingRole(d, to: .admin)
        #expect(!s.setting(admin, id: "payroll-confirm", isOn: false).enabled.contains("payroll-confirm"))
    }

    @Test func 바뀐_것_판정과_저장_목록() {
        let d = s.setting(s.initialDraft, id: "payroll-view", isOn: true)
        #expect(s.hasChanges(d))
        #expect(s.enabledIDs(d) == ["staff-list", "schedule", "attendance", "notice", "payroll-view"])
        let undone = s.setting(d, id: "payroll-view", isOn: false)
        #expect(!s.hasChanges(undone))
    }

    @Test func 음성_문구() {
        #expect(s.spoken(s.items[5], in: s.initialDraft) == "급여 확정 · 명세서 발행, 대표 · 관리자만 켤 수 있어요")
        #expect(s.spoken(s.items[0], in: s.initialDraft) == "직원 목록 보기")
    }
}
