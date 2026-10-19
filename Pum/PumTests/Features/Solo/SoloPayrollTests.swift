// UI-IOS-1u · 20g · 1m — MVP 급여 탭 값
import Foundation
import SwiftData
import Testing
@testable import Pum

@MainActor
struct SoloPayrollTests {
    @Test func 기본은_지난달() {
        let month = SoloPayrollMonth(today: 20260115)
        #expect(month.year == 2025 && month.month == 12)
        #expect(SoloPayrollMonth.recentMonths(today: 20261019).first! == (2026, 10))
        #expect(SoloPayrollMonth.recentMonths(today: 20261019).count == 12)
    }

    @Test func 마감_전_목록과_마감_뒤_목록() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try SoloPayroll.useCase(store.context).prepare(workplace, year: 2026, month: 9)

        let open = SoloPayroll.record(workplace, year: 2026, month: 9, context: store.context)
        #expect(open.isSolo)
        #expect(open.stage == .needsReview)
        #expect(open.canConfirm)
        #expect(open.employees.first?.statusText == "마감 전")
        #expect(open.employees.first?.wageKindText == "시급")
        #expect(open.payDayText == "10월 10일")
        let openSlip = try #require(SoloPayroll.payslip(workplace, employeeID: "\(employee.persistentModelID)",
                                                        year: 2026, month: 9, context: store.context))
        #expect(openSlip.statusText == "마감 전")
        #expect(openSlip.isConsistent)

        try SoloPayroll.useCase(store.context).close(workplace, year: 2026, month: 9)
        let closed = SoloPayroll.record(workplace, year: 2026, month: 9, context: store.context)
        #expect(closed.stage == .confirmed)
        #expect(!closed.showsConfirmButton)
        #expect(closed.employees.first?.statusText == "확정")
        #expect(closed.totalAmount == open.totalAmount)
        let slip = try #require(SoloPayroll.payslip(workplace, employeeID: "\(employee.persistentModelID)",
                                                    year: 2026, month: 9, context: store.context))
        #expect(slip.statusText == "확정")
        #expect(slip.payDateText == "2026.10.10")
        #expect(slip.workSummary == "22일 · 176h")
        #expect(slip.netPay == closed.totalAmount)
    }

    @Test func 고친_날이_있는_직원만_확인() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 9)
        let none = SoloPayroll.closingState(workplace, year: 2026, month: 9, confirmed: [])
        #expect(none.canClose)
        #expect(none.people.isEmpty)
        #expect(none.periodText == "9월 1일 – 30일")

        try WorkDayFixUseCase(workDays: store.workDays).execute(.absent, reason: "", for: employee, on: 20260915)
        let one = SoloPayroll.closingState(workplace, year: 2026, month: 9, confirmed: [])
        #expect(!one.canClose)
        let person = try #require(one.people.first)
        #expect(person.editedDayCount == 1)
        #expect(person.scheduledDayCount == 21)
        #expect(person.confirmSubtitle == "예정대로 21일 · 고친 날 1일")
        #expect(person.editedDays.first?.detailText == "결근")

        let done = SoloPayroll.closingState(workplace, year: 2026, month: 9, confirmed: [person.id])
        #expect(done.canClose)
    }
}
