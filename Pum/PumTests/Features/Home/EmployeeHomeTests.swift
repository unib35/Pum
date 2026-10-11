// UI-IOS-1at — 직원 홈(출근 전) 계산 · 표시 형식
import Testing
@testable import Pum

struct EmployeeHomeTests {
    let plan = ShiftPlan(startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, breakStartMinute: 19 * 60 + 30)

    @Test func 인정_근무는_예정에서_휴게를_뺀다() {
        #expect(plan.plannedPaidMinutes == 270)
        #expect(HomeFormat.hours(plan.plannedPaidMinutes) == "4시간 30분")
    }

    @Test func 예정_금액은_정수_원() {
        #expect(plan.plannedPay(hourlyWage: 12_000) == 54_000)
        // 1분 단가가 나누어떨어지지 않으면 원 단위 버림
        #expect(ShiftPlan(startMinute: 0, endMinute: 7, breakMinutes: 0, breakStartMinute: nil).plannedPay(hourlyWage: 10_320) == 1_204)
    }

    @Test func 남은_시간() {
        var s = EmployeeHomeState.sample
        #expect(s.minutesUntilStart == 7)
        #expect(HomeFormat.untilStart(s.minutesUntilStart) == "7분 후")
        s.nowMinute = 17 * 60 + 5
        #expect(s.minutesUntilStart == 0)
        #expect(HomeFormat.untilStart(0) == "지금")
        #expect(HomeFormat.untilStart(75) == "1시간 15분 후")
    }

    @Test func 시각_형식() {
        #expect(HomeFormat.clock(16 * 60 + 53) == "16:53")
        #expect(HomeFormat.clock(9 * 60 + 5) == "09:05")
        #expect(HomeFormat.hours(300) == "5시간")
        #expect(HomeFormat.hours(305) == "5시간 05분")
    }

    @Test func 주간_스트립_디자인_값() {
        let week = EmployeeHomeState.sample.week
        #expect(week.count == 7)
        #expect(week.filter(\.isToday).map(\.day) == [3])
        #expect(week.last?.isSunday == true)
        #expect(week.filter(\.hasShift).count == 4)
    }

    @Test func 휴게_없는_근무() {
        let p = ShiftPlan(startMinute: 9 * 60, endMinute: 13 * 60, breakMinutes: 0, breakStartMinute: nil)
        #expect(p.plannedPaidMinutes == 240)
    }
}
