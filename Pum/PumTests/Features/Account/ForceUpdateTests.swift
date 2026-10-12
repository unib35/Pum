// UI-IOS-6t · REQ-029 · REQ-094 — 업데이트 필수: 원문 값 · 근무 중일 때만 퇴근 버튼 · 퇴근 버튼은 늘 활성
import Testing
@testable import Pum

struct ForceUpdateTests {
    let s = ForceUpdateState.sample

    @Test func 원문_값() {
        #expect(ForceUpdateState.title == "업데이트가 필요해요")
        #expect(s.message == "2027년 1월 1일부터 바뀌는 최저임금과 계산 기준은 새 버전에서만 계산돼요.")
        #expect(s.rows.map(\.label) == ["지금 버전", "필요한 버전", "크기"])
        #expect(s.rows.map(\.value) == ["1.4.2", "1.5.0", "18MB"])
        #expect(s.rows[0].spoken == "지금 버전, 1.4.2")
        #expect(s.working?.title == "근무 중 · 16:58 출근")
        #expect(s.working?.message == "업데이트하지 않아도 퇴근은 기록할 수 있어요. 기록은 그대로 이어져요.")
        #expect(ForceUpdateState.updateTitle == "App Store에서 업데이트")
        #expect(ForceUpdateState.clockOutTitle == "퇴근만 기록")
    }

    @Test func 퇴근_버튼은_근무_중일_때만() {
        #expect(s.showsClockOut)
        #expect(!ForceUpdateState.notWorking.showsClockOut)
        #expect(ForceUpdateState.notWorking.working == nil)
    }

    @Test func 근무_아님은_같은_틀() {
        #expect(ForceUpdateState.notWorking.rows == s.rows)
        #expect(ForceUpdateState.notWorking.message == s.message)
    }
}
