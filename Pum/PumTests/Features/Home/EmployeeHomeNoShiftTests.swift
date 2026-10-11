// UI-IOS-1au — 직원 홈(근무 없는 날) 계산 · 표시 문구
import Testing
@testable import Pum

struct EmployeeHomeNoShiftTests {
    let s = NoShiftHomeState.sample

    @Test func 인정_근무는_예정에서_휴게를_뺀다() {
        #expect(s.nextShift.plannedPaidMinutes == 270)
    }

    @Test func 예정_금액은_정수_원() {
        #expect(s.nextShift.plannedPay(hourlyWage: s.hourlyWage) == 54_000)
        #expect(s.plannedSummary == "인정 근무 4시간 30분 · 54,000원 예정")
    }

    @Test func 주간_요약_문구() {
        #expect(s.weekSummary == "이번 주 4일 · 19시간")
    }

    @Test func 다음_근무_문구() {
        #expect(s.nextShiftCaption == "다음 근무 · 내일 월요일")
        #expect(s.nextShiftRange == "17:00 \u{2013} 22:00")
    }

    @Test func 오늘은_일요일이고_근무일은_네_개() {
        #expect(s.week.filter(\.isToday).map(\.label) == ["일"])
        #expect(s.week.filter(\.hasShift).map(\.label) == ["월", "수", "금", "토"])
        #expect(s.upcoming.count == 3)
    }

    @Test func 그다음_근무_3건과_이번_달_값() {
        let s = NoShiftHomeState.sample
        #expect(s.upcoming.map(\.id) == ["수 7일", "금 9일", "토 10일"])
        #expect(s.upcoming.allSatisfy { $0.start == "17:00" && $0.end == "22:00" })
        let m = s.monthCardState
        #expect(m.monthTitle == "10월")
        #expect(m.monthPlannedMinutes == 82 * 60 + 30)
        #expect(m.monthExpectedPay == 1_188_000)
        #expect(m.monthDaysSummary == "17일 · 확정 2일")
    }
}
