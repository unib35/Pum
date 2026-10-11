// UI-IOS-1av — 직원 홈(근무 중) 지난 시간 · 진행 비율 · 자동 퇴근 없음
import Foundation
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

    @Test func 예정_퇴근이_지나도_근무_시간은_계속_늘어난다() {
        // 자동 퇴근 없음(REQ-024): 예정 22:00이 지나도 막대는 끝(1)에 머물고 지난 시간은 계속 센다
        let s = EmployeeHomeWorkingState.sample.with(now: 22 * 60 + 40)
        #expect(s.elapsedMinutes == 5 * 60 + 42)
        #expect(s.progress == 1)
    }

    @Test func 자정을_넘겨도_지난_시간을_이어서_센다() {
        var s = EmployeeHomeWorkingState.sample
        s.clockInMinute = 23 * 60
        s.nowMinute = 30 // 다음 날 00:30
        #expect(s.elapsedMinutes == 90)
        #expect(WorkingFormat.minutesBetween(16 * 60 + 58, 18 * 60 + 40) == 102)
    }

    @Test func 분은_두_자리_F4() {
        #expect(WorkingFormat.elapsedLabel(5 * 60 + 5) == "5시간 05분 근무 중")
        #expect(WorkingFormat.elapsedLabel(2 * 60) == "2시간 00분 근무 중")
        #expect(WorkingFormat.minuteText((0, 7)) == "7")
        #expect(WorkingFormat.minuteText((1, 7)) == "07")
    }

    @Test func 지금_시각은_서울_기준() {
        // 2026-10-03 09:40 UTC = 18:40 KST
        let date = Date(timeIntervalSince1970: 1_791_020_400)
        #expect(WorkingFormat.minuteOfDay(date) == 18 * 60 + 40)
    }

    @Test func 오늘_예정_안내() {
        let s = EmployeeHomeWorkingState.sample
        #expect(HomeFormat.hours(s.plan.plannedPaidMinutes) == "4시간 30분")
        #expect(s.plannedPay == 54_000)
    }
}
