// UI-IOS-1av — 직원 홈(근무 중) 지난 시간 · 진행 비율 · 자동 퇴근 없음
import Testing
@testable import Pum

struct EmployeeHomeWorkingTests {
    @Test func 지난_시간은_출근에서_지금까지_분_단위() {
        let s = EmployeeHomeWorkingState.sample
        #expect(s.elapsedMinutes == 102)
        #expect(HomeFormat.hours(s.elapsedMinutes) == "1시간 42분")
        #expect(WorkingFormat.elapsedLabel(s.elapsedMinutes) == "1시간 42분 근무 중")
        #expect(WorkingFormat.elapsedLabel(42) == "42분 근무 중")
    }

    @Test func 진행_비율은_예정_구간_기준이고_0에서_1로_자른다() {
        var s = EmployeeHomeWorkingState.sample
        #expect(abs(s.progress - 100.0 / 300.0) < 0.0001) // 17:00 → 18:40
        s.nowMinute = 16 * 60 + 58
        #expect(s.progress == 0)
        s.nowMinute = 23 * 60
        #expect(s.progress == 1)
    }

    @Test func 예정_퇴근이_지나도_퇴근으로_바뀌지_않는다() {
        let s = EmployeeHomeWorkingState.sample.with(now: 22 * 60 + 40)
        #expect(s.status == .working)
        #expect(s.elapsedMinutes == 5 * 60 + 42) // 계속 늘어난다
    }

    @Test func 오늘_예정_안내() {
        let s = EmployeeHomeWorkingState.sample
        #expect(HomeFormat.hours(s.plan.plannedPaidMinutes) == "4시간 30분")
        #expect(s.plannedPay == 54_000)
    }
}
