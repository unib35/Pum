import Foundation

/// 직원 한 명의 그 달 계산.
struct EmployeePayroll {
    let employee: Employee
    let result: PayrollResult
    let wageType: WorkTerms.WageType
}

/// 저장된 근로조건 · 근무 → 계산 모듈(Domain/Payroll) → 미리 보기 · 근무 마감(확정 명세서 저장).
/// 그 달과 앞 달을 근로조건대로 채운 뒤 계산한다(앞 달은 걸친 주의 주 40시간 · 주휴 판단용).
struct MonthlyPayrollUseCase {
    let employees: EmployeeRepository
    let workDays: WorkDayRepository
    let payroll: PayrollRepository
    var now: () -> Date = { .now }

    /// 그 달 계산 전에 그 달과 앞 달을 근로조건대로 채운다(화면을 그리기 전에 한 번).
    func prepare(_ workplace: Workplace, year: Int, month: Int) throws {
        let period = PayrollPeriod(year: year, month: month)
        for employee in try employees.list(in: workplace, includeLeft: true) {
            try fill(employee, period: period)
        }
    }

    /// `fill`이 false면 저장소를 바꾸지 않는다(화면 그리기 중 계산용).
    func calculate(_ workplace: Workplace, year: Int, month: Int, fill shouldFill: Bool = true) throws -> [EmployeePayroll] {
        let period = PayrollPeriod(year: year, month: month)
        let first = Self.key(period.firstDay), last = Self.key(period.lastDay)
        return try employees.list(in: workplace, includeLeft: true)
            .filter { $0.hireDayKey <= last && ($0.leaveDayKey ?? .max) >= first }
            .compactMap { employee in
                guard let terms = employee.terms(on: min(last, employee.leaveDayKey ?? last)) ?? employee.terms(on: .max)
                else { return nil }
                if shouldFill { try fill(employee, period: period) }
                let input = PayrollInput(
                    workplace: PayrollWorkplace(isFiveOrMore: workplace.isFiveOrMore,
                                                deduction: workplace.deduction == .business3_3 ? .business3_3 : .none),
                    period: period, terms: Self.terms(terms), records: try records(employee, period: period))
                return EmployeePayroll(employee: employee, result: PayrollCalculator.calculate(input), wageType: terms.wageType)
            }
    }

    /// 근무 마감: 계산 결과를 명세서로 저장하고 그 달을 닫는다.
    func close(_ workplace: Workplace, year: Int, month: Int) throws {
        let payrollMonth = try payroll.month(of: workplace, year: year, month: month)
        for pay in try calculate(workplace, year: year, month: month) {
            try payroll.savePayslip(Self.draft(pay), for: pay.employee, in: payrollMonth, at: now())
        }
        try payroll.close(payrollMonth, at: now())
    }

    static func draft(_ pay: EmployeePayroll) -> PayslipDraft {
        let r = pay.result
        let items: [(String, Int)] = [
            ("기본급", r.basePay), ("주휴수당", r.weeklyHolidayPay), ("연장근로수당", r.overtimePay),
            ("야간근로수당", r.nightPay), ("휴일근로수당", r.holidayPay),
        ]
        let deductions: [(String, Int)] = [("소득세", r.incomeTax), ("지방소득세", r.localIncomeTax)]
        return PayslipDraft(
            payItems: items.filter { $0.1 != 0 || $0.0 == "기본급" }.map { Payslip.Line(name: $0.0, amount: $0.1) },
            deductionItems: deductions.filter { $0.1 != 0 }.map { Payslip.Line(name: $0.0, amount: $0.1) },
            grossPay: r.grossPay, totalDeduction: r.totalDeduction, netPay: r.netPay, traceLines: r.traceText,
            workDays: r.workDays, workedMinutes: r.workedMinutes)
    }

    // MARK: 입력 만들기

    private func fill(_ employee: Employee, period: PayrollPeriod) throws {
        let previous = period.month == 1 ? (period.year - 1, 12) : (period.year, period.month - 1)
        try workDays.fillScheduled(for: employee, year: previous.0, month: previous.1)
        try workDays.fillScheduled(for: employee, year: period.year, month: period.month)
    }

    /// 기간과 걸친 주 전체(앞 달 월요일 ~ 마지막 주 일요일)의 기록. 쉬는 날(0–0)은 기록 없음으로 넘긴다.
    private func records(_ employee: Employee, period: PayrollPeriod) throws -> [PayrollWorkRecord] {
        let from = Self.key(period.firstDay.weekMonday), to = Self.key(period.lastDay.weekMonday.adding(days: 6))
        var months: [(Int, Int)] = [(SeoulDayKey.year(from), SeoulDayKey.month(from))]
        if months.last! != (period.year, period.month) { months.append((period.year, period.month)) }
        if months.last! != (SeoulDayKey.year(to), SeoulDayKey.month(to)) { months.append((SeoulDayKey.year(to), SeoulDayKey.month(to))) }
        return try months.flatMap { try workDays.days(of: employee, year: $0.0, month: $0.1) }
            .filter { (from...to).contains($0.dayKey) }
            .compactMap(Self.record)
    }

    static func record(_ day: WorkDay) -> PayrollWorkRecord? {
        let date = PayrollDate(SeoulDayKey.year(day.dayKey), SeoulDayKey.month(day.dayKey), SeoulDayKey.day(day.dayKey))
        if day.status == .absent { return .absent(date) }
        if day.startMinute == 0 && day.endMinute == 0 { return nil }
        return PayrollWorkRecord(date: date, startMinute: day.startMinute, endMinute: day.endMinute,
                                 breakMinutes: day.breakMinutes, isHolidayWork: day.isHolidayWork)
    }

    static func terms(_ terms: WorkTerms) -> PayrollWorkTerms {
        let end = WorkDay.normalizedEnd(start: terms.startMinute, end: terms.endMinute)
        return PayrollWorkTerms(
            wage: terms.wageType == .monthly ? .monthly(terms.amount) : .hourly(terms.amount),
            scheduledWeekdays: Set(terms.workWeekdays.compactMap(PayrollWeekday.init(rawValue:))),
            dailyScheduledMinutes: max(end - terms.startMinute - terms.breakMinutes, 0))
    }

    static func key(_ date: PayrollDate) -> Int { SeoulDayKey.make(year: date.year, month: date.month, day: date.day) }
}
