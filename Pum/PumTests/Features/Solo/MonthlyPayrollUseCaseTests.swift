// DEC-029 · DEC-031 — 저장된 근무로 월급 계산 · 근무 마감
import Foundation
import Testing
@testable import Pum

@MainActor
struct MonthlyPayrollUseCaseTests {
    private func useCase(_ store: DataTestStore) -> MonthlyPayrollUseCase {
        MonthlyPayrollUseCase(employees: store.employees, workDays: store.workDays, payroll: store.payroll,
                              now: { Date(timeIntervalSince1970: 0) })
    }

    @Test func 근로조건대로_한_달() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee() // 월–금 8시간, 시급 10,320
        let pays = try useCase(store).calculate(workplace, year: 2026, month: 9)
        let pay = try #require(pays.first)
        // 2026년 9월 평일 22일 × 8시간
        #expect(pay.result.workDays == 22)
        #expect(pay.result.workedMinutes == 22 * 480)
        #expect(pay.result.basePay == 22 * 8 * 10_320)
        #expect(pay.result.weeklyHolidayPay > 0)
        #expect(pay.wageType == .hourly)
    }

    @Test func 결근은_빼고_쉬는_날은_기록_없음() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        let fix = WorkDayFixUseCase(workDays: store.workDays)
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 9)
        try fix.execute(.absent, reason: "", for: employee, on: 20260901)
        try fix.execute(.dayOff, reason: "", for: employee, on: 20260902)

        let pay = try #require(try useCase(store).calculate(workplace, year: 2026, month: 9).first)
        #expect(pay.result.workDays == 20)
        #expect(MonthlyPayrollUseCase.record(try #require(try store.workDays.day(of: employee, on: 20260902))) == nil)
        #expect(MonthlyPayrollUseCase.record(try #require(try store.workDays.day(of: employee, on: 20260901)))?.isAbsent == true)
    }

    @Test func 입사_전_달은_계산하지_않는다() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee(hireDayKey: 20261001)
        #expect(try useCase(store).calculate(workplace, year: 2026, month: 9).isEmpty)
    }

    @Test func 마감하면_명세서를_저장하고_닫는다() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee()
        try store.workplaces.update(workplace) { $0.deduction = .business3_3 }

        try useCase(store).close(workplace, year: 2026, month: 9)

        let month = try #require(try store.payroll.findMonth(of: workplace, year: 2026, month: 9))
        #expect(month.isClosed)
        let slip = try #require(try store.payroll.payslips(in: month).first)
        #expect(slip.payItems.first?.name == "기본급")
        #expect(slip.deductionItems.map(\.name) == ["소득세", "지방소득세"])
        #expect(slip.grossPay - slip.totalDeduction == slip.netPay)
        #expect(slip.workDays == 22)
        #expect(!slip.traceLines.isEmpty)
    }

    @Test func 월급제_근로조건_변환() {
        let terms = WorkTerms(effectiveFromDayKey: 20260101, wageType: .monthly, amount: 2_500_000,
                              workWeekdays: [1, 2, 3, 4, 5], startMinute: 1320, endMinute: 360, breakMinutes: 60)
        let mapped = MonthlyPayrollUseCase.terms(terms)
        #expect(mapped.wage == .monthly(2_500_000))
        #expect(mapped.dailyScheduledMinutes == 420) // 22:00–06:00, 휴게 1시간
        #expect(mapped.scheduledWeekdays.count == 5)
    }
}
