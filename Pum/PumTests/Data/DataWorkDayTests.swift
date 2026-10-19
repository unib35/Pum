import Foundation
import SwiftData
import Testing
@testable import Pum

/// 자동 채움 순수 계산.
@MainActor
struct DataScheduleFillerTests {
    private func terms(_ weekdays: Set<Int>, from: Int = 20200101, start: Int = 540, end: Int = 1080)
        -> WorkScheduleFiller.Terms {
        WorkScheduleFiller.Terms(effectiveFromDayKey: from, workWeekdays: weekdays,
                                 startMinute: start, endMinute: end, breakMinutes: 60)
    }

    @Test func 근무_요일만_채운다() {
        let days = WorkScheduleFiller.plannedDays(year: 2026, month: 10, terms: [terms([1, 3, 5])],
                                                  hireDayKey: 20200101, leaveDayKey: nil, existingDayKeys: [])
        #expect(days.count == 13)
        #expect(days.allSatisfy { [1, 3, 5].contains(SeoulDayKey.weekday($0.dayKey)) })
        #expect(days.first?.dayKey == 20261002) // 10/1은 목요일 → 첫 금요일
        #expect(days.first == .init(dayKey: 20261002, startMinute: 540, endMinute: 1080, breakMinutes: 60))
    }

    @Test func 이미_있는_날은_건너뛴다() {
        let days = WorkScheduleFiller.plannedDays(year: 2026, month: 10, terms: [terms([1, 3, 5])],
                                                  hireDayKey: 20200101, leaveDayKey: nil,
                                                  existingDayKeys: [20261002, 20261005])
        #expect(days.count == 11)
        #expect(!days.contains { $0.dayKey == 20261002 || $0.dayKey == 20261005 })
    }

    @Test func 이월과_윤년() {
        let feb2026 = WorkScheduleFiller.plannedDays(year: 2026, month: 2, terms: [terms([1, 2, 3, 4, 5])],
                                                     hireDayKey: 20200101, leaveDayKey: nil, existingDayKeys: [])
        #expect(feb2026.count == 20)
        #expect(feb2026.last?.dayKey == 20260227)
        let feb2028 = WorkScheduleFiller.plannedDays(year: 2028, month: 2, terms: [terms(Set(1...7))],
                                                     hireDayKey: 20200101, leaveDayKey: nil, existingDayKeys: [])
        #expect(feb2028.count == 29)
        #expect(feb2028.last?.dayKey == 20280229)
    }

    @Test func 말일_31일과_월_경계() {
        // 2026-01-31은 토요일. 토요일 근무면 31일이 들어가고 2/1(일)은 넘어가지 않는다.
        let jan = WorkScheduleFiller.plannedDays(year: 2026, month: 1, terms: [terms([6])],
                                                 hireDayKey: 20200101, leaveDayKey: nil, existingDayKeys: [])
        #expect(jan.count == 5)
        #expect(jan.last?.dayKey == 20260131)
        #expect(jan.allSatisfy { SeoulDayKey.month($0.dayKey) == 1 })
    }

    @Test func 입사_퇴사_근로조건_변경_반영() {
        let history = [terms([1, 2, 3, 4, 5], from: 20261001), terms([6], from: 20261016, start: 600, end: 960)]
        let days = WorkScheduleFiller.plannedDays(year: 2026, month: 10, terms: history,
                                                  hireDayKey: 20261005, leaveDayKey: 20261024, existingDayKeys: [])
        // 10/5–10/15 평일 9일 + 10/17 · 10/24 토요일 2일
        #expect(days.map(\.dayKey) == [20261005, 20261006, 20261007, 20261008, 20261009,
                                      20261012, 20261013, 20261014, 20261015, 20261017, 20261024])
        #expect(days.last?.startMinute == 600)
    }

    @Test func 자정_넘김은_끝에_1440을_더한다() {
        let days = WorkScheduleFiller.plannedDays(year: 2026, month: 10, terms: [terms([5], start: 1320, end: 120)],
                                                  hireDayKey: 20200101, leaveDayKey: nil, existingDayKeys: [])
        #expect(days.first?.endMinute == 1560)
    }
}

@MainActor
struct DataWorkDayRepositoryTests {
    @Test func 자동_채움은_고친_날을_보존하고_다시_해도_중복이_없다() throws {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee(weekdays: [1, 3, 5])
        let editedAt = Date(timeIntervalSince1970: 1_792_337_400)
        try store.workDays.save(WorkDayEdit(status: .edited, startMinute: 600, endMinute: 1020, breakMinutes: 30,
                                            reason: "늦게 출근"), for: employee, on: 20261002, at: editedAt)
        try store.workDays.markAbsent(employee, on: 20261005, reason: "병가", at: editedAt)

        #expect(try store.workDays.fillScheduled(for: employee, year: 2026, month: 10) == 11)
        #expect(try store.workDays.fillScheduled(for: employee, year: 2026, month: 10) == 0)

        let days = try store.workDays.days(of: employee, year: 2026, month: 10)
        #expect(days.count == 13)
        #expect(days.map(\.dayKey) == days.map(\.dayKey).sorted())
        let edited = try #require(try store.workDays.day(of: employee, on: 20261002))
        #expect(edited.status == .edited)
        #expect(edited.startMinute == 600)
        #expect(edited.editedAt == editedAt)
        #expect(try store.workDays.day(of: employee, on: 20261005)?.status == .absent)
        #expect(days.filter { $0.status == .scheduled }.allSatisfy { $0.startMinute == 540 && $0.editedAt == nil })
    }

    @Test func 하루_고치기와_결근() throws {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 10)
        let at = Date(timeIntervalSince1970: 1_792_337_400)

        let day = try store.workDays.save(WorkDayEdit(status: .edited, startMinute: 1320, endMinute: 120,
                                                      breakMinutes: 30, isHolidayWork: false, reason: "마감"),
                                          for: employee, on: 20261006, at: at)
        #expect(day.endMinute == 1560) // 자정 넘김
        #expect(day.reason == "마감")
        let absent = try store.workDays.markAbsent(employee, on: 20261007, reason: "개인 사정", at: at)
        #expect(absent.status == .absent)
        #expect(absent.startMinute == 0 && absent.endMinute == 0 && absent.breakMinutes == 0)

        // 같은 날은 한 건만 — 새로 만들지 않고 고친다.
        #expect(try store.workDays.days(of: employee, year: 2026, month: 10).filter { $0.dayKey == 20261006 }.count == 1)

        // 근로조건에 없는 토요일 추가 근무 + 휴일 근무
        let extra = try store.workDays.save(WorkDayEdit(status: .extra, startMinute: 600, endMinute: 900,
                                                        breakMinutes: 0, isHolidayWork: true),
                                            for: employee, on: 20261010, at: at)
        #expect(extra.status == .extra && extra.isHolidayWork)
        #expect(try store.workDays.days(of: employee, year: 2026, month: 10).count == 22 + 1)

        try store.workDays.delete(extra)
        #expect(try store.workDays.day(of: employee, on: 20261010) == nil)
    }

    @Test func 월별_조회는_그_달_그_사업장만() throws {
        let store = try DataTestStore()
        let (workplace, kim) = try store.makeEmployee(name: "김민지")
        let lee = try store.employees.create(in: workplace, name: "이서준", phone: nil, birthDayKey: nil,
                                             hireDayKey: 20260101, colorIndex: 1, memo: "")
        try store.employees.addTerms(WorkTerms(effectiveFromDayKey: 20260101, wageType: .hourly, amount: 10_320,
                                               workWeekdays: [6], startMinute: 540, endMinute: 1080,
                                               breakMinutes: 60), to: lee)
        let (_, outsider) = try store.makeEmployee(name: "박다른")

        try store.workDays.fillScheduled(for: kim, year: 2026, month: 10)   // 22
        try store.workDays.fillScheduled(for: kim, year: 2026, month: 11)   // 다음 달
        try store.workDays.fillScheduled(for: lee, year: 2026, month: 10)   // 토 5
        try store.workDays.fillScheduled(for: outsider, year: 2026, month: 10)

        #expect(try store.workDays.days(of: kim, year: 2026, month: 10).count == 22)
        #expect(try store.workDays.days(of: lee, year: 2026, month: 10).count == 5)
        let all = try store.workDays.days(in: workplace, year: 2026, month: 10)
        #expect(all.count == 27)
        #expect(all.allSatisfy { SeoulDayKey.month($0.dayKey) == 10 && $0.employee?.name != "박다른" })
    }
}

@MainActor
struct DataPayrollRepositoryTests {
    private let draft = PayslipDraft(
        payItems: [.init(name: "기본급", amount: 1_816_320), .init(name: "주휴수당", amount: 371_520)],
        deductionItems: [.init(name: "사업소득세(3.3%)", amount: 72_220)],
        grossPay: 2_187_840, totalDeduction: 72_220, netPay: 2_115_620,
        traceLines: ["기본급 = 10,320원 × 176시간", "주휴수당 = 10,320원 × 36시간"]
    )

    @Test func 월은_한_건만_만들고_마감한다() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee()
        let october = try store.payroll.month(of: workplace, year: 2026, month: 10)
        let again = try store.payroll.month(of: workplace, year: 2026, month: 10)
        #expect(october.persistentModelID == again.persistentModelID)
        #expect(try store.count(PayrollMonth.self) == 1)
        #expect(try store.payroll.findMonth(of: workplace, year: 2026, month: 11) == nil)

        let closedAt = Date(timeIntervalSince1970: 1_792_337_400)
        try store.payroll.close(october, at: closedAt)
        let found = try #require(try store.payroll.findMonth(of: workplace, year: 2026, month: 10))
        #expect(found.isClosed)
        #expect(found.closedAt == closedAt)
    }

    @Test func 명세서_스냅숏은_근무를_고쳐도_그대로() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 10)
        let october = try store.payroll.month(of: workplace, year: 2026, month: 10)
        try store.payroll.close(october, at: .now)
        try store.payroll.savePayslip(draft, for: employee, in: october, at: .now)

        // 확정 뒤 근무를 고치고 이름도 바꾼다.
        try store.workDays.markAbsent(employee, on: 20261006, reason: "정정", at: .now)
        try store.employees.update(employee) { $0.name = "김민지(바뀜)" }

        let slip = try #require(try store.payroll.payslips(in: october).first)
        #expect(slip.grossPay == 2_187_840)
        #expect(slip.netPay == 2_115_620)
        #expect(slip.employeeName == "김민지")
        #expect(slip.payItems == draft.payItems)
        #expect(slip.deductionItems == draft.deductionItems)
        #expect(slip.traceLines == draft.traceLines)
        #expect(slip.year == 2026 && slip.month == 10)
    }

    @Test func 같은_직원_명세서를_다시_저장하면_바꾼다() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        let october = try store.payroll.month(of: workplace, year: 2026, month: 10)
        try store.payroll.savePayslip(draft, for: employee, in: october, at: .now)
        var revised = draft
        revised.netPay = 2_000_000
        try store.payroll.savePayslip(revised, for: employee, in: october, at: .now)
        #expect(try store.count(Payslip.self) == 1)
        #expect(try store.payroll.payslips(in: october).first?.netPay == 2_000_000)
    }
}

@MainActor
struct DataDeletionTests {
    @Test func 직원을_지우면_근무_근로조건_사진은_지우고_명세서는_남긴다() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 10)
        try store.employees.addContractPhoto(Data([9]), to: employee)
        let october = try store.payroll.month(of: workplace, year: 2026, month: 10)
        try store.payroll.savePayslip(PayslipDraft(payItems: [.init(name: "기본급", amount: 100)], deductionItems: [],
                                                   grossPay: 100, totalDeduction: 0, netPay: 100, traceLines: []),
                                      for: employee, in: october, at: .now)

        try store.employees.delete(employee)

        #expect(try store.count(Employee.self) == 0)
        #expect(try store.count(WorkDay.self) == 0)
        #expect(try store.count(WorkTerms.self) == 0)
        #expect(try store.count(ContractPhoto.self) == 0)
        let slip = try #require(try store.payroll.payslips(in: october).first)
        #expect(slip.employee == nil)
        #expect(slip.employeeName == "김민지")
        #expect(try store.employees.list(in: workplace, includeLeft: true).isEmpty)
    }

    @Test func 사업장을_지우면_모두_지운다() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 10)
        let october = try store.payroll.month(of: workplace, year: 2026, month: 10)
        try store.payroll.savePayslip(PayslipDraft(payItems: [], deductionItems: [], grossPay: 0,
                                                   totalDeduction: 0, netPay: 0, traceLines: []),
                                      for: employee, in: october, at: .now)

        try store.workplaces.delete(workplace)

        #expect(try store.count(Workplace.self) == 0)
        #expect(try store.count(Employee.self) == 0)
        #expect(try store.count(WorkDay.self) == 0)
        #expect(try store.count(PayrollMonth.self) == 0)
        #expect(try store.count(Payslip.self) == 0)
    }
}
