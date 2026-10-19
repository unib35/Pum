import Foundation
import SwiftData
@testable import Pum

/// 테스트마다 새 메모리 저장소를 만든다(컨테이너를 붙잡아 둬야 context가 살아 있다).
@MainActor
struct DataTestStore {
    let container: ModelContainer
    let context: ModelContext
    let workplaces: SwiftDataWorkplaceRepository
    let employees: SwiftDataEmployeeRepository
    let workDays: SwiftDataWorkDayRepository
    let payroll: SwiftDataPayrollRepository

    init(today: Int = 20261019) throws {
        container = try PumModelContainer.makeInMemory()
        context = container.mainContext
        workplaces = SwiftDataWorkplaceRepository(context: context)
        employees = SwiftDataEmployeeRepository(context: context, today: { today })
        workDays = SwiftDataWorkDayRepository(context: context)
        payroll = SwiftDataPayrollRepository(context: context)
    }

    func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    /// 사업장 + 직원 + 근로조건(월–금 09:00–18:00, 휴게 60분, 시급 10,320원).
    func makeEmployee(name: String = "김민지", hireDayKey: Int = 20260101,
                      weekdays: Set<Int> = [1, 2, 3, 4, 5]) throws -> (Workplace, Employee) {
        let workplace = try workplaces.create(name: "품카페", isFiveOrMore: false, deduction: .none, payday: 10)
        let employee = try employees.create(in: workplace, name: name, phone: nil, birthDayKey: nil,
                                            hireDayKey: hireDayKey, colorIndex: 0, memo: "")
        try employees.addTerms(WorkTerms(effectiveFromDayKey: hireDayKey, wageType: .hourly, amount: 10_320,
                                         workWeekdays: weekdays, startMinute: 540, endMinute: 1080,
                                         breakMinutes: 60), to: employee)
        return (workplace, employee)
    }
}
