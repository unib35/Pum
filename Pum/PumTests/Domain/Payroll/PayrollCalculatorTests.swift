// DEC-029 · DEC-031 · REQ-071 — MVP 월급 계산 모듈 사례표
// 달력: 2026-10-01 = 목요일, 10-31 = 토요일, 11-01 = 일요일.
// 10월에 걸친 주(월–일): 9/28–10/4, 10/5–11, 10/12–18, 10/19–25, 10/26–11/1(일요일이 11월 → 11월 지급).
import Testing
import Foundation
@testable import Pum

// MARK: - 사례표 도우미

private func d(_ month: Int, _ day: Int, _ year: Int = 2026) -> PayrollDate { PayrollDate(year, month, day) }
private func hm(_ h: Int, _ m: Int = 0) -> Int { h * 60 + m }

private func work(_ date: PayrollDate, _ start: Int, _ end: Int, rest: Int = 0, holiday: Bool = false) -> PayrollWorkRecord {
    PayrollWorkRecord(date: date, startMinute: start, endMinute: end, breakMinutes: rest, isHolidayWork: holiday)
}

/// 9:00–18:00, 휴게 1시간 = 8시간
private func fullDay(_ date: PayrollDate) -> PayrollWorkRecord { work(date, hm(9), hm(18), rest: 60) }

private let weekdays: Set<PayrollWeekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
/// 10월 평일 22일(1·2 · 5–9 · 12–16 · 19–23 · 26–30)
private let octoberWeekdayDates: [PayrollDate] = (1...31).map { d(10, $0) }.filter { $0.weekday <= .friday }

nonisolated struct PayrollCase: Sendable, CustomTestStringConvertible {
    let name: String
    let input: PayrollInput
    let base: Int
    var weekly = 0
    var overtime = 0
    var night = 0
    var holiday = 0
    let gross: Int
    var deduction = 0
    var net: Int? = nil

    var testDescription: String { name }
}

extension PayrollInput {
    static func make(
        five: Bool = true,
        deduction method: PayrollDeductionMethod = .none,
        period: PayrollPeriod = PayrollPeriod(year: 2026, month: 10),
        wage: PayrollWage = .hourly(10_000),
        days: Set<PayrollWeekday> = [],
        daily: Int = 0,
        records: [PayrollWorkRecord]
    ) -> PayrollInput {
        PayrollInput(
            workplace: PayrollWorkplace(isFiveOrMore: five, deduction: method),
            period: period,
            terms: PayrollWorkTerms(wage: wage, scheduledWeekdays: days, dailyScheduledMinutes: daily),
            records: records
        )
    }
}

private let cases: [PayrollCase] = [
    // 1. 9–18, 휴게 60 → 480분. 480 × 10,000 ÷ 60 = 80,000
    PayrollCase(name: "단순 시급", input: .make(records: [fullDay(d(10, 5))]), base: 80_000, gross: 80_000),

    // 2. 9:00–15:30, 휴게 30 → 360분 → 60,000
    PayrollCase(name: "휴게 제외", input: .make(records: [work(d(10, 5), hm(9), hm(15, 30), rest: 30)]), base: 60_000, gross: 60_000),

    // 3. 50분 × 10,030 ÷ 60 = 8,358.33 → 8,358(원 미만 반올림)
    PayrollCase(name: "분 단위 반올림(내림쪽)", input: .make(wage: .hourly(10_030), records: [work(d(10, 5), hm(9), hm(9, 50))]), base: 8_358, gross: 8_358),

    // 4. 30분 × 10,001 ÷ 60 = 5,000.5 → 5,001(0.5원은 올림)
    PayrollCase(name: "분 단위 반올림(0.5 올림)", input: .make(wage: .hourly(10_001), records: [work(d(10, 5), hm(9), hm(9, 30))]), base: 5_001, gross: 5_001),

    // 5. 5인 미만, 20:00–다음날 02:00 → 360분 → 60,000. 야간 240분이지만 가산 없음
    PayrollCase(name: "자정 넘김(5인 미만)", input: .make(five: false, records: [work(d(10, 5), hm(20), hm(26))]), base: 60_000, gross: 60_000),

    // 6. 5인 이상, 20:00–02:00 → 기본 60,000 + 야간 22–02 240분 × 10,000 × 50% ÷ 60 = 20,000 → 80,000
    PayrollCase(name: "자정 넘김 + 야간", input: .make(records: [work(d(10, 5), hm(20), hm(26))]), base: 60_000, night: 20_000, gross: 80_000),

    // 7. 18:00–23:00 → 300분 50,000 + 야간 22–23 60분 5,000 = 55,000
    PayrollCase(name: "야간 일부", input: .make(records: [work(d(10, 5), hm(18), hm(23))]), base: 50_000, night: 5_000, gross: 55_000),

    // 8. 04:00–09:00 → 300분 50,000 + 야간 04–06 120분 10,000 = 60,000
    PayrollCase(name: "새벽 야간", input: .make(records: [work(d(10, 5), hm(4), hm(9))]), base: 50_000, night: 10_000, gross: 60_000),

    // 9. 9–20, 휴게 60 → 600분 100,000 + 연장 120분 × 10,000 × 50% ÷ 60 = 10,000 → 110,000
    PayrollCase(name: "1일 8시간 초과", input: .make(records: [work(d(10, 5), hm(9), hm(20), rest: 60)]), base: 100_000, overtime: 10_000, gross: 110_000),

    // 10. 같은 날 9–13 + 14–19 = 240 + 300 = 540분 90,000 + 연장 60분 5,000 = 95,000
    PayrollCase(name: "같은 날 기록 합산", input: .make(records: [work(d(10, 5), hm(9), hm(13)), work(d(10, 5), hm(14), hm(19))]), base: 90_000, overtime: 5_000, gross: 95_000),

    // 11. 월–토(10/5–10) 8시간씩 2,880분 480,000. 토요일 480분이 주 40시간 초과 → 40,000 → 520,000
    PayrollCase(name: "주 40시간 초과", input: .make(records: (5...10).map { fullDay(d(10, $0)) }), base: 480_000, overtime: 40_000, gross: 520_000),

    // 12. 월–금 9–19 휴게 60(540분) + 토 9–13(240분) = 2,940분 490,000.
    //     하루 초과 60 × 5 = 300 + 주 초과(하루 8시간 이내분 2,400 다음) 240 = 540분 → 45,000. 중복 없음 → 535,000
    PayrollCase(name: "하루 · 주 연장 중복 없음", input: .make(records: (5...9).map { work(d(10, $0), hm(9), hm(19), rest: 60) } + [work(d(10, 10), hm(9), hm(13))]), base: 490_000, overtime: 45_000, gross: 535_000),

    // 13. 일요일 휴일 근무 9–18 휴게 60 → 480분 80,000 + 휴일 480 × 50% 40,000 = 120,000
    PayrollCase(name: "휴일 8시간 이내", input: .make(records: [work(d(10, 11), hm(9), hm(18), rest: 60, holiday: true)]), base: 80_000, holiday: 40_000, gross: 120_000),

    // 14. 휴일 9–21 휴게 60 → 660분 110,000 + 휴일 (480 × 50% + 180 × 100%) = 40,000 + 30,000 = 70,000 → 180,000. 연장과 중복 없음
    PayrollCase(name: "휴일 8시간 초과", input: .make(records: [work(d(10, 11), hm(9), hm(21), rest: 60, holiday: true)]), base: 110_000, holiday: 70_000, gross: 180_000),

    // 15. 휴일 18:00–24:00 → 360분 60,000 + 휴일 360 × 50% 30,000 + 야간 22–24 120분 10,000 = 100,000
    PayrollCase(name: "휴일 + 야간 겹침", input: .make(records: [work(d(10, 11), hm(18), hm(24), holiday: true)]), base: 60_000, night: 10_000, holiday: 30_000, gross: 100_000),

    // 16. 5인 미만, 9–23 휴게 60 → 780분 130,000. 연장 300 · 야간 60 있어도 가산 0
    PayrollCase(name: "5인 미만 가산 없음", input: .make(five: false, records: [work(d(10, 5), hm(9), hm(23), rest: 60)]), base: 130_000, gross: 130_000),

    // 17. 주 소정 14시간 59분(월 899분) → 15시간 미만, 주휴 없음
    PayrollCase(name: "주휴 경계 14:59", input: .make(days: [.monday], daily: 899, records: []), base: 0, gross: 0),

    // 18. 주 소정 15시간(월 900분) → 주휴 900 ÷ 40 × 8 = 180분 × 10,000 ÷ 60 = 30,000 × 4주(9/28 · 10/5 · 10/12 · 10/19 주) = 120,000
    PayrollCase(name: "주휴 경계 15:00", input: .make(days: [.monday], daily: 900, records: []), base: 0, weekly: 120_000, gross: 120_000),

    // 19. 주 48시간(월–토 8시간) → 주휴 최대 8시간 80,000 × 4주 = 320,000
    PayrollCase(name: "주휴 최대 8시간", input: .make(days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday], daily: 480, records: []), base: 0, weekly: 320_000, gross: 320_000),

    // 20. 5인 미만, 월–금 8시간 · 10월 평일 22일 개근: 기본 22 × 80,000 = 1,760,000 + 주휴 4주 × 80,000 = 320,000 → 2,080,000
    //     (10/26–11/1 주는 일요일이 11월 → 11월 지급)
    PayrollCase(name: "주휴 개근 한 달", input: .make(five: false, days: weekdays, daily: 480, records: octoberWeekdayDates.map(fullDay)), base: 1_760_000, weekly: 320_000, gross: 2_080_000),

    // 21. 위와 같고 10/7(수) 결근: 기본 21일 1,680,000 + 주휴 3주 240,000 = 1,920,000
    PayrollCase(name: "결근 있는 주 주휴 없음", input: .make(five: false, days: weekdays, daily: 480, records: octoberWeekdayDates.map { $0 == d(10, 7) ? .absent($0) : fullDay($0) }), base: 1_680_000, weekly: 240_000, gross: 1_920_000),

    // 22. 11월 기간: 10/26–11/1 주(일요일 11/1)부터 11/23–29 주까지 5주 → 400,000. 11/30–12/6 주는 12월 지급
    PayrollCase(name: "월 경계 주 — 일요일 속한 달 지급", input: .make(five: false, period: PayrollPeriod(year: 2026, month: 11), days: weekdays, daily: 480, records: []), base: 0, weekly: 400_000, gross: 400_000),

    // 23. 위와 같고 10/28(수, 기간 밖) 결근 기록 → 10/26 주 주휴 없음 → 4주 320,000. 기간 밖 결근은 지급에 영향 없음
    PayrollCase(name: "월 경계 주 — 전 달 결근", input: .make(five: false, period: PayrollPeriod(year: 2026, month: 11), days: weekdays, daily: 480, records: [.absent(d(10, 28))]), base: 0, weekly: 320_000, gross: 320_000),

    // 24. 11월 기간, 10/26–30(기간 밖) 8시간씩 2,400분 + 11/1(일, 휴일 아님) 9–14 300분.
    //     기간 밖 기록은 지급 안 함. 11/1 300분 50,000 + 주 40시간 초과 300분 25,000 = 75,000
    PayrollCase(name: "월 경계 주 40시간", input: .make(period: PayrollPeriod(year: 2026, month: 11), records: (26...30).map { fullDay(d(10, $0)) } + [work(d(11, 1), hm(9), hm(14))]), base: 50_000, overtime: 25_000, gross: 75_000),

    // 25. 기간 밖(9/30) 기록만 → 0
    PayrollCase(name: "기간 밖 기록 지급 안 함", input: .make(records: [fullDay(d(9, 30))]), base: 0, gross: 0),

    // 26. 월급 2,090,000 → 통상시급 2,090,000 ÷ 209 = 10,000. 9–20 휴게 60 → 연장 120분 × 10,000 × 50% ÷ 60 = 10,000. 결근 있어도 공제 없음
    PayrollCase(name: "월급제 + 연장", input: .make(wage: .monthly(2_090_000), days: weekdays, daily: 480, records: [work(d(10, 5), hm(9), hm(20), rest: 60), .absent(d(10, 6))]), base: 2_090_000, overtime: 10_000, gross: 2_100_000),

    // 27. 월급 2,500,000 ÷ 209 = 11,961.72 → 통상시급 11,962. 9–19 휴게 60 → 연장 60분 × 11,962 × 50% ÷ 60 = 5,981
    PayrollCase(name: "월급제 통상시급 반올림", input: .make(wage: .monthly(2_500_000), records: [work(d(10, 5), hm(9), hm(19), rest: 60)]), base: 2_500_000, overtime: 5_981, gross: 2_505_981),

    // 28. 시급 12,345 × 480분 = 98,760. 소득세 98,760 × 3% = 2,962.8 → 2,960(10원 미만 절사).
    //     지방소득세 2,960 × 10% = 296 → 290. 공제 3,250 → 실지급 95,510
    PayrollCase(name: "3.3% 10원 미만 절사", input: .make(deduction: .business3_3, wage: .hourly(12_345), records: [fullDay(d(10, 5))]), base: 98_760, gross: 98_760, deduction: 3_250, net: 95_510),

    // 29. 82시간 30분(10일 × 8시간 + 2시간 30분) × 12,000 = 990,000. 소득세 29,700 · 지방 2,970 → 32,670 → 957,330
    PayrollCase(name: "3.3% 기본", input: .make(five: false, deduction: .business3_3, wage: .hourly(12_000), records: ([5, 6, 7, 8, 9, 12, 13, 14, 15, 16].map { fullDay(d(10, $0)) } + [work(d(10, 19), hm(9), hm(11, 30))])), base: 990_000, gross: 990_000, deduction: 32_670, net: 957_330),

    // 30. 결근만 → 금액 0, 3.3%도 0
    PayrollCase(name: "금액 0", input: .make(deduction: .business3_3, records: [.absent(d(10, 5))]), base: 0, gross: 0, deduction: 0, net: 0),

    // 31. 빈 기록 → 0
    PayrollCase(name: "빈 기록", input: .make(records: []), base: 0, gross: 0),
]

struct PayrollCalculatorTests {
    @Test(arguments: cases)
    func 사례표(_ c: PayrollCase) {
        let r = PayrollCalculator.calculate(c.input)
        #expect(r.basePay == c.base)
        #expect(r.weeklyHolidayPay == c.weekly)
        #expect(r.overtimePay == c.overtime)
        #expect(r.nightPay == c.night)
        #expect(r.holidayPay == c.holiday)
        #expect(r.grossPay == c.gross)
        #expect(r.grossPay == r.basePay + r.weeklyHolidayPay + r.overtimePay + r.nightPay + r.holidayPay)
        #expect(r.totalDeduction == c.deduction)
        #expect(r.totalDeduction == r.incomeTax + r.localIncomeTax)
        #expect(r.netPay == (c.net ?? c.gross - c.deduction))
    }

    @Test func 사례표는_20건_이상() {
        #expect(cases.count >= 20)
    }

    @Test func 계산_근거_문장() {
        let input = PayrollInput.make(five: false, deduction: .business3_3, wage: .hourly(12_000),
                                     records: [5, 6, 7, 8, 9, 12, 13, 14, 15, 16].map { fullDay(d(10, $0)) } + [work(d(10, 19), hm(9), hm(11, 30))])
        let r = PayrollCalculator.calculate(input)
        #expect(r.workedMinutes == 4_950)
        #expect(r.workDays == 11)
        #expect(r.traceText.contains("기본급 82시간 30분 × 12,000원 = 990,000원"))
        #expect(r.traceText.contains("소득세 990,000원 × 3% = 29,700원(10원 미만 절사)"))
        #expect(r.traceText.contains("지방소득세 소득세 29,700원 × 10% = 2,970원(10원 미만 절사)"))
        #expect(r.traceText.contains("실지급액 990,000원 − 32,670원 = 957,330원"))
        #expect(r.trace.first?.item == .basePay)
        #expect(r.trace.last?.item == .netPay)
    }

    @Test func 근거_주휴_월경계_결근() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "결근 있는 주 주휴 없음" }!.input)
        #expect(r.weeklyHolidayWeeks == 3)
        #expect(r.traceText.contains("10월 5일(월)–10월 11일(일) 주: 결근(10월 7일(수)) — 주휴수당 없음"))
        #expect(r.traceText.contains("10월 26일(월)–11월 1일(일) 주: 주의 마지막 날이 다음 달이라 주휴수당은 다음 달에 지급"))
        #expect(r.traceText.contains("주휴수당 3주 × 주 소정근로 40시간 ÷ 40 × 8 × 10,000원 = 240,000원"))
    }

    @Test func 근거_연장_내역() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "하루 · 주 연장 중복 없음" }!.input)
        #expect(r.overtimeMinutes == 540)
        #expect(r.traceText.contains("연장 가산 9시간(하루 8시간 초과 5시간 + 주 40시간 초과 4시간) × 10,000원 × 50% = 45,000원"))
    }

    @Test func 근거_월급제() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "월급제 통상시급 반올림" }!.input)
        #expect(r.traceText.contains("월급제 결근 공제 없음(MVP)"))
        #expect(r.traceText.contains("통상시급 2,500,000원 ÷ 209시간 = 11,962원(원 미만 반올림) — 월급제는 가산분만 계산"))
        #expect(r.weeklyHolidayPay == 0)
    }

    @Test func 근거_5인_미만() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "5인 미만 가산 없음" }!.input)
        #expect(r.overtimeMinutes == 300)
        #expect(r.nightMinutes == 60)
        #expect(r.traceText.contains("상시 5인 미만 — 연장 · 야간 · 휴일 가산 없음"))
    }

    @Test func 근거_주휴_15시간_미만() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "주휴 경계 14:59" }!.input)
        #expect(r.traceText.contains("주 소정근로 14시간 59분 — 15시간 미만이라 주휴수당 없음"))
    }

    @Test func 휴일_시간은_연장에_넣지_않음() {
        let r = PayrollCalculator.calculate(cases.first { $0.name == "휴일 8시간 초과" }!.input)
        #expect(r.holidayMinutes == 660)
        #expect(r.overtimeMinutes == 0)
    }
}
