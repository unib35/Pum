import Foundation
import SwiftData

// SwiftData 구현. 바꿀 때마다 바로 저장한다(앱이 꺼져도 기록이 남게).
// 관계 조건은 #Predicate 대신 날짜 범위로 가져온 뒤 메모리에서 거른다(MVP 규모 · Optional 관계 조건의 불안정 회피).

final class SwiftDataWorkplaceRepository: WorkplaceRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    @discardableResult
    func create(name: String, isFiveOrMore: Bool, deduction: Workplace.Deduction, payday: Int) throws -> Workplace {
        let workplace = Workplace(name: name, isFiveOrMore: isFiveOrMore, deduction: deduction, payday: payday)
        context.insert(workplace)
        try context.save()
        return workplace
    }

    func all() throws -> [Workplace] {
        try context.fetch(FetchDescriptor<Workplace>(sortBy: [SortDescriptor(\.createdAt)]))
    }

    func update(_ workplace: Workplace, _ change: (Workplace) -> Void) throws {
        change(workplace)
        workplace.payday = Workplace.clampedPayday(workplace.payday)
        try context.save()
    }

    func delete(_ workplace: Workplace) throws {
        context.delete(workplace)
        try context.save()
    }
}

final class SwiftDataEmployeeRepository: EmployeeRepository {
    private let context: ModelContext
    private let today: () -> Int

    init(context: ModelContext, today: @escaping () -> Int = { SeoulDayKey.from(.now) }) {
        self.context = context
        self.today = today
    }

    @discardableResult
    func create(in workplace: Workplace, name: String, phone: String?, birthDayKey: Int?,
                hireDayKey: Int, colorIndex: Int, memo: String) throws -> Employee {
        let employee = Employee(name: name, phone: phone, birthDayKey: birthDayKey, hireDayKey: hireDayKey,
                                colorIndex: colorIndex, memo: memo)
        context.insert(employee)
        employee.workplace = workplace
        try context.save()
        return employee
    }

    func list(in workplace: Workplace, includeLeft: Bool) throws -> [Employee] {
        let id = workplace.persistentModelID
        let todayKey = today()
        return try context.fetch(FetchDescriptor<Employee>(sortBy: [SortDescriptor(\.createdAt)]))
            .filter { $0.workplace?.persistentModelID == id }
            .filter { includeLeft || ($0.leaveDayKey.map { $0 >= todayKey } ?? true) }
    }

    func update(_ employee: Employee, _ change: (Employee) -> Void) throws {
        change(employee)
        try context.save()
    }

    func delete(_ employee: Employee) throws {
        context.delete(employee)
        try context.save()
    }

    @discardableResult
    func addTerms(_ terms: WorkTerms, to employee: Employee) throws -> WorkTerms {
        context.insert(terms)
        terms.employee = employee
        try context.save()
        return terms
    }

    func termsHistory(of employee: Employee) throws -> [WorkTerms] {
        (employee.terms ?? []).sorted {
            ($0.effectiveFromDayKey, $0.createdAt) < ($1.effectiveFromDayKey, $1.createdAt)
        }
    }

    @discardableResult
    func addContractPhoto(_ imageData: Data, to employee: Employee) throws -> ContractPhoto {
        let photo = ContractPhoto(imageData: imageData)
        context.insert(photo)
        photo.employee = employee
        try context.save()
        return photo
    }

    func deleteContractPhoto(_ photo: ContractPhoto) throws {
        context.delete(photo)
        try context.save()
    }
}

final class SwiftDataWorkDayRepository: WorkDayRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    private func fetch(in range: ClosedRange<Int>) throws -> [WorkDay] {
        let lower = range.lowerBound
        let upper = range.upperBound
        let descriptor = FetchDescriptor<WorkDay>(
            predicate: #Predicate { $0.dayKey >= lower && $0.dayKey <= upper },
            sortBy: [SortDescriptor(\.dayKey)]
        )
        return try context.fetch(descriptor)
    }

    func days(of employee: Employee, year: Int, month: Int) throws -> [WorkDay] {
        let id = employee.persistentModelID
        return try fetch(in: SeoulDayKey.monthRange(year: year, month: month))
            .filter { $0.employee?.persistentModelID == id }
    }

    func days(in workplace: Workplace, year: Int, month: Int) throws -> [WorkDay] {
        let id = workplace.persistentModelID
        return try fetch(in: SeoulDayKey.monthRange(year: year, month: month))
            .filter { $0.employee?.workplace?.persistentModelID == id }
    }

    func day(of employee: Employee, on dayKey: Int) throws -> WorkDay? {
        let id = employee.persistentModelID
        return try fetch(in: dayKey...dayKey).first { $0.employee?.persistentModelID == id }
    }

    @discardableResult
    func save(_ edit: WorkDayEdit, for employee: Employee, on dayKey: Int, at date: Date) throws -> WorkDay {
        let target: WorkDay
        if let existing = try day(of: employee, on: dayKey) {
            target = existing
        } else {
            target = WorkDay(dayKey: dayKey, status: edit.status, startMinute: 0, endMinute: 0, breakMinutes: 0)
            context.insert(target)
            target.employee = employee
        }
        target.status = edit.status
        target.startMinute = edit.startMinute
        target.endMinute = WorkDay.normalizedEnd(start: edit.startMinute, end: edit.endMinute)
        target.breakMinutes = edit.breakMinutes
        target.isHolidayWork = edit.isHolidayWork
        target.reason = edit.reason
        target.editedAt = date
        try context.save()
        return target
    }

    @discardableResult
    func markAbsent(_ employee: Employee, on dayKey: Int, reason: String, at date: Date) throws -> WorkDay {
        try save(WorkDayEdit(status: .absent, startMinute: 0, endMinute: 0, breakMinutes: 0, reason: reason),
                 for: employee, on: dayKey, at: date)
    }

    @discardableResult
    func fillScheduled(for employee: Employee, year: Int, month: Int) throws -> Int {
        let existing = Set(try days(of: employee, year: year, month: month).map(\.dayKey))
        let terms = (employee.terms ?? []).map {
            WorkScheduleFiller.Terms(effectiveFromDayKey: $0.effectiveFromDayKey, workWeekdays: $0.workWeekdays,
                                     startMinute: $0.startMinute, endMinute: $0.endMinute,
                                     breakMinutes: $0.breakMinutes)
        }
        let planned = WorkScheduleFiller.plannedDays(year: year, month: month, terms: terms,
                                                     hireDayKey: employee.hireDayKey,
                                                     leaveDayKey: employee.leaveDayKey,
                                                     existingDayKeys: existing)
        for plan in planned {
            let day = WorkDay(dayKey: plan.dayKey, status: .scheduled, startMinute: plan.startMinute,
                              endMinute: plan.endMinute, breakMinutes: plan.breakMinutes)
            context.insert(day)
            day.employee = employee
        }
        if !planned.isEmpty { try context.save() }
        return planned.count
    }

    func delete(_ day: WorkDay) throws {
        context.delete(day)
        try context.save()
    }
}

final class SwiftDataPayrollRepository: PayrollRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func findMonth(of workplace: Workplace, year: Int, month: Int) throws -> PayrollMonth? {
        let id = workplace.persistentModelID
        let descriptor = FetchDescriptor<PayrollMonth>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [SortDescriptor(\.year)]
        )
        return try context.fetch(descriptor).first { $0.workplace?.persistentModelID == id }
    }

    func month(of workplace: Workplace, year: Int, month: Int) throws -> PayrollMonth {
        if let found = try findMonth(of: workplace, year: year, month: month) { return found }
        let created = PayrollMonth(year: year, month: month)
        context.insert(created)
        created.workplace = workplace
        try context.save()
        return created
    }

    func close(_ payrollMonth: PayrollMonth, at date: Date) throws {
        payrollMonth.isClosed = true
        payrollMonth.closedAt = date
        try context.save()
    }

    @discardableResult
    func savePayslip(_ draft: PayslipDraft, for employee: Employee, in payrollMonth: PayrollMonth,
                     at date: Date) throws -> Payslip {
        let employeeID = employee.persistentModelID
        for old in (payrollMonth.payslips ?? []) where old.employee?.persistentModelID == employeeID {
            context.delete(old)
        }
        let payslip = Payslip(year: payrollMonth.year, month: payrollMonth.month, employeeName: employee.name,
                              payItems: draft.payItems, deductionItems: draft.deductionItems,
                              grossPay: draft.grossPay, totalDeduction: draft.totalDeduction,
                              netPay: draft.netPay, traceLines: draft.traceLines, createdAt: date)
        payslip.workDays = draft.workDays
        payslip.workedMinutes = draft.workedMinutes
        context.insert(payslip)
        payslip.employee = employee
        payslip.payrollMonth = payrollMonth
        try context.save()
        return payslip
    }

    func payslips(in payrollMonth: PayrollMonth) throws -> [Payslip] {
        (payrollMonth.payslips ?? []).sorted { $0.employeeName < $1.employeeName }
    }
}
