import Foundation

// 화면 · ViewModel · UseCase는 이 프로토콜만 안다(구현은 SwiftData*Repository).
// 날짜는 SeoulDayKey(yyyyMMdd 정수, Asia/Seoul), 금액은 정수 원, 시각은 0시부터의 분.

protocol WorkplaceRepository {
    @discardableResult
    func create(name: String, isFiveOrMore: Bool, deduction: Workplace.Deduction, payday: Int) throws -> Workplace
    /// 만든 순서대로.
    func all() throws -> [Workplace]
    /// `change` 안에서 값을 바꾸고 저장한다.
    func update(_ workplace: Workplace, _ change: (Workplace) -> Void) throws
    /// 직원 · 월 마감 · 명세서까지 함께 지운다.
    func delete(_ workplace: Workplace) throws
}

protocol EmployeeRepository {
    @discardableResult
    func create(in workplace: Workplace, name: String, phone: String?, birthDayKey: Int?,
                hireDayKey: Int, colorIndex: Int, memo: String) throws -> Employee
    /// 등록 순서대로. `includeLeft`가 false면 오늘(서울) 기준 퇴사한 직원을 뺀다.
    func list(in workplace: Workplace, includeLeft: Bool) throws -> [Employee]
    func update(_ employee: Employee, _ change: (Employee) -> Void) throws
    /// 근로조건 · 근무 · 계약서 사진은 함께 지우고, 확정 명세서는 남긴다(직원 연결만 끊김).
    func delete(_ employee: Employee) throws

    /// 근로조건 이력에 한 건 추가(바뀐 조건은 새 적용 시작일로 추가한다).
    @discardableResult
    func addTerms(_ terms: WorkTerms, to employee: Employee) throws -> WorkTerms
    /// 적용 시작일 순서대로.
    func termsHistory(of employee: Employee) throws -> [WorkTerms]

    @discardableResult
    func addContractPhoto(_ imageData: Data, to employee: Employee) throws -> ContractPhoto
    func deleteContractPhoto(_ photo: ContractPhoto) throws
}

/// 하루 고치기 입력.
struct WorkDayEdit: Equatable {
    var status: WorkDay.Status
    var startMinute: Int
    var endMinute: Int
    var breakMinutes: Int
    var isHolidayWork: Bool = false
    var reason: String = ""
}

protocol WorkDayRepository {
    /// 직원의 그 달 근무(날짜 순).
    func days(of employee: Employee, year: Int, month: Int) throws -> [WorkDay]
    /// 사업장 전체 직원의 그 달 근무(날짜 순).
    func days(in workplace: Workplace, year: Int, month: Int) throws -> [WorkDay]
    func day(of employee: Employee, on dayKey: Int) throws -> WorkDay?
    /// 그날 기록이 있으면 고치고, 없으면 만든다. 고친 시각을 남긴다.
    @discardableResult
    func save(_ edit: WorkDayEdit, for employee: Employee, on dayKey: Int, at date: Date) throws -> WorkDay
    /// 결근으로 표시(시간은 0).
    @discardableResult
    func markAbsent(_ employee: Employee, on dayKey: Int, reason: String, at date: Date) throws -> WorkDay
    /// 근로조건대로 예정 근무를 아직 없는 날만 만든다. 만든 건수를 돌려준다.
    @discardableResult
    func fillScheduled(for employee: Employee, year: Int, month: Int) throws -> Int
    func delete(_ day: WorkDay) throws
}

/// 확정 명세서 입력(계산 결과 — 계산은 Domain/Payroll이 한다).
struct PayslipDraft: Equatable {
    var payItems: [Payslip.Line]
    var deductionItems: [Payslip.Line]
    var grossPay: Int
    var totalDeduction: Int
    var netPay: Int
    var traceLines: [String]
    var workDays: Int = 0
    var workedMinutes: Int = 0
}

protocol PayrollRepository {
    /// 그 달 급여(없으면 만든다).
    func month(of workplace: Workplace, year: Int, month: Int) throws -> PayrollMonth
    func findMonth(of workplace: Workplace, year: Int, month: Int) throws -> PayrollMonth?
    /// 근무 마감.
    func close(_ payrollMonth: PayrollMonth, at date: Date) throws
    /// 확정 명세서 스냅숏 저장. 같은 달 같은 직원 것이 있으면 바꾼다.
    @discardableResult
    func savePayslip(_ draft: PayslipDraft, for employee: Employee, in payrollMonth: PayrollMonth,
                     at date: Date) throws -> Payslip
    /// 그 달 명세서(직원 이름 순).
    func payslips(in payrollMonth: PayrollMonth) throws -> [Payslip]
}
