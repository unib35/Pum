// UI-IOS-1an — 근태 정책: 정책 3개 문구 · 기준 알약 · 기준 분 표기 · 자동 종료 +6시간(DEC-004) · 리마인드 문구
import Testing
@testable import Pum

struct AttendancePolicyTests {
    let r = AttendancePolicyRecord.sample

    @Test func 정책_3개_문구() {
        #expect(OvertimePolicy.allCases.map(\.title) == ["A · 자동 인정", "B · 기준 초과분만 사장님 확인", "C · 사전 승인 필요"])
        #expect(OvertimePolicy.allCases.map(\.detail) == [
            "실제 기록 그대로 급여 반영. 확인 절차 없음",
            "예정과의 차이가 기준 이내면 자동 인정, 넘으면 확인 필요로",
            "미리 승인한 연장 시간만 자동 인정, 나머지는 확인 필요로"])
    }

    @Test func 샘플은_B_45분() {
        #expect(r.policy == .confirmOverThreshold)
        #expect(r.threshold == .m45)
    }

    @Test func 기준_알약은_B일_때만() {
        #expect(OvertimePolicy.allCases.filter(\.usesThreshold) == [.confirmOverThreshold])
    }

    @Test func 기준_분_값과_표기() {
        #expect(AutoApproveThreshold.allCases.map(\.minutes) == [15, 30, 45, 60])
        #expect(AutoApproveThreshold.allCases.map(\.label) == ["15분", "30분", "45분", "1시간"])
    }

    @Test func 자동_종료는_6시간_고정() {
        #expect(AttendancePolicyRecord.autoCloseHours == 6)
        let row = r.reminders[2]
        #expect(row.value == "예정 퇴근 +6시간")
        #expect(row.suffix == " · 미확정 처리")
        #expect(row.accessibilityText == "근무 상태 자동 종료, 예정 퇴근 +6시간, 미확정 처리")
    }

    @Test func 리마인드_문구() {
        #expect(r.reminders.map(\.label) == ["알림 시점", "무응답 시", "근무 상태 자동 종료", "사장님에게 초과 알림"])
        #expect(r.reminders.map(\.value) == ["예정 시각 · +30분 · +1시간", "근무 중 유지", "예정 퇴근 +6시간", "예정 퇴근 +30분"])
        #expect(r.noteLead + r.noteStrong + r.noteTail == "자동 종료는 세션만 닫아요. 퇴근시간은 미확정으로 남고, 직원 입력과 사장님 확인을 거쳐야 급여에 반영돼요.")
    }
}
