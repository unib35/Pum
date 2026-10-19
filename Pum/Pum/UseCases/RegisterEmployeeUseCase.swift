import Foundation

/// 직접 등록(20b–20d) 입력. 시각은 0시부터의 분, 날짜는 SeoulDayKey.
struct EmployeeRegistration: Equatable {
    var name: String
    var phone: String?
    var hireDayKey: Int
    var wageType: WorkTerms.WageType
    var amount: Int
    var weekdays: Set<Int>
    var startMinute: Int
    var endMinute: Int
    var breakMinutes: Int
    var contractPhotos: [Data] = []
}

/// 직원 · 근로조건 · 계약서 사진을 저장하고, 입사한 달이 지났거나 이번 달이면 이번 달 근무를 근로조건대로 채운다.
struct RegisterEmployeeUseCase {
    let employees: EmployeeRepository
    let workDays: WorkDayRepository
    var today: () -> Int = { SeoulDayKey.from(.now) }

    @discardableResult
    func execute(_ input: EmployeeRegistration, in workplace: Workplace) throws -> Employee {
        let colorIndex = workplace.employees?.count ?? 0 // 아바타가 팔레트 수로 나눠 쓴다
        let employee = try employees.create(
            in: workplace, name: input.name, phone: input.phone, birthDayKey: nil,
            hireDayKey: input.hireDayKey, colorIndex: colorIndex, memo: "")
        try employees.addTerms(WorkTerms(
            effectiveFromDayKey: input.hireDayKey, wageType: input.wageType, amount: input.amount,
            workWeekdays: input.weekdays, startMinute: input.startMinute, endMinute: input.endMinute,
            breakMinutes: input.breakMinutes), to: employee)
        for photo in input.contractPhotos {
            try employees.addContractPhoto(photo, to: employee)
        }
        let now = today()
        if input.hireDayKey <= now {
            try workDays.fillScheduled(for: employee, year: SeoulDayKey.year(now), month: SeoulDayKey.month(now))
        }
        return employee
    }
}
