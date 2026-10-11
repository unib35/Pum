// UI-IOS-1ak — 연장 근무 중 경과 · 초과 · 비율 · 자정 넘김 · 연장 아님
import Foundation
import Testing
@testable import Pum

struct EmployeeHomeOvertimeTests {
    @Test func 경과는_출근에서_지금까지_4시간_15분() {
        let s = EmployeeHomeOvertimeState.sample
        #expect(s.elapsedMinutes == 255)
        #expect(OvertimeFormat.clockStyle(s.elapsedMinutes) == "4:15")
    }

    @Test func 초과는_예정_퇴근_이후_1시간_13분() {
        let s = EmployeeHomeOvertimeState.sample
        #expect(s.scheduledSpanMinutes == 182) // 16:58 → 20:00
        #expect(s.overtimeMinutes == 73)
        #expect(s.isOvertime)
        #expect(OvertimeFormat.plusClock(s.overtimeMinutes) == "+1:13")
        #expect(OvertimeFormat.plusDuration(s.overtimeMinutes) == "+1시간 13분")
        #expect(OvertimeFormat.plusDuration(60) == "+1시간")
        #expect(OvertimeFormat.plusDuration(20) == "+20분")
    }

    @Test func 초과_비율은_초과분을_전체_경과로_나눈다() {
        let s = EmployeeHomeOvertimeState.sample
        #expect(abs(s.overtimeRatio - 73.0 / 255.0) < 0.0001)
    }

    @Test func 자정을_넘겨도_이어서_센다() {
        var s = EmployeeHomeOvertimeState.sample
        s.plan = ShiftPlan(startMinute: 22 * 60, endMinute: 0, breakMinutes: 0, breakStartMinute: nil) // 22:00–00:00
        s.clockInMinute = 22 * 60
        s.nowMinute = 1 * 60 + 10
        #expect(s.elapsedMinutes == 190)
        #expect(s.scheduledSpanMinutes == 120)
        #expect(s.overtimeMinutes == 70)
        #expect(OvertimeFormat.plusClock(s.overtimeMinutes) == "+1:10")
    }

    @Test func 초과가_0이면_연장_상태가_아니다() {
        let s = EmployeeHomeOvertimeState.sample.with(now: 19 * 60 + 30)
        #expect(s.overtimeMinutes == 0)
        #expect(!s.isOvertime)
        #expect(s.overtimeRatio == 0)
        #expect(EmployeeHomeOvertimeState.sample.with(now: 20 * 60).isOvertime == false)
    }

    @Test func 인정_예상은_서버_값_그대로() {
        let s = EmployeeHomeOvertimeState.sample
        #expect(s.recognizedPayEstimate == 45_000)
        #expect("\(PumFormat.amount(s.recognizedPayEstimate))원~" == "45,000원~")
    }

    @Test func 접근성_문장() {
        let s = EmployeeHomeOvertimeState.sample
        #expect(OvertimeFormat.cardLabel(elapsed: s.elapsedMinutes, plannedEnd: "20:00", overtime: s.overtimeMinutes)
            == "연장 근무 중, 4시간 15분 근무, 예정 퇴근 20:00보다 1시간 13분 초과")
    }

    @Test func 지금이_출근보다_조금_이르면_경과_0() {
        var x = EmployeeHomeOvertimeState.sample
        x.nowMinute = x.clockInMinute - 3
        #expect(x.elapsedMinutes == 0 && !x.isOvertime)
    }

    @Test func 예정_퇴근_뒤에_출근하면_전부_초과() {
        var x = EmployeeHomeOvertimeState.sample
        x.clockInMinute = 20 * 60 + 30
        x.nowMinute = 21 * 60
        #expect(x.scheduledSpanMinutes == 0)
        #expect(x.overtimeMinutes == 30)
        x.clockInMinute = 20 * 60 // 예정 퇴근과 같은 시각
        #expect(x.overtimeMinutes == 60)
    }
}
