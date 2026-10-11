// UI-IOS-2f — 개인 모드 홈 표시 값
import Testing
@testable import Pum

struct PersonalHomeTests {
    @Test func 원문_값은_상태_그대로_형식만_맞춘다() {
        let s = PersonalHomeState.sample
        #expect(HomeFormat.clock(s.nowMinute) == "16:53")
        #expect(HomeFormat.untilStart(s.minutesUntilStart) == "7분 후")
        #expect(HomeFormat.hours(s.monthPlannedMinutes) == "68시간 20분")
        #expect(PumFormat.amount(s.monthExpectedPay) == "824,300")
        #expect(PumFormat.amount(s.hourlyWage) == "12,000")
        #expect(PumFormat.amount(s.plannedPay) == "54,000")
        #expect(s.monthDaysSummary == "14일 · 급여일 11월 10일")
    }

    @Test func 최근_기록_형식() {
        let r = PersonalHomeState.sample.recent[0]
        #expect(r.id == "금 2일")
        #expect(PumFormat.timeRange(r.start, r.end) == "17:02 \u{2013} 22:31")
        #expect(HomeFormat.hours(r.paidMinutes) == "4시간 59분")
    }

    @Test func 주간_스트립은_오늘_하루만_표시() {
        let week = PersonalHomeState.sample.week
        #expect(week.count == 7)
        #expect(week.filter(\.isToday).count == 1)
        #expect(week.first(where: \.isToday)?.day == 3)
    }

    @Test func 기록이_없으면_최근_기록이_비어_카드를_숨긴다() {
        var s = PersonalHomeState.sample
        s.recent = []
        #expect(s.recent.isEmpty)
    }
}
