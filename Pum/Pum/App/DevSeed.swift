#if DEBUG
import Foundation
import SwiftData

/// 개발 빌드 `-PumSeed demo`: 저장소가 비어 있으면 MVP 흐름 확인용 사업장 · 직원 2명을 넣는다(#487).
enum DevSeed {
    static func run(_ context: ModelContext) {
        let workplaces = SwiftDataWorkplaceRepository(context: context)
        guard (try? workplaces.all().isEmpty) == true,
              let workplace = try? workplaces.create(name: "품 카페", isFiveOrMore: false, deduction: .none, payday: 10)
        else { return }

        let register = RegisterEmployeeUseCase(
            employees: SwiftDataEmployeeRepository(context: context),
            workDays: SwiftDataWorkDayRepository(context: context))
        let today = SeoulDayKey.from(.now)
        let monthIndex = SeoulDayKey.year(today) * 12 + SeoulDayKey.month(today) - 1 - 2
        let hire = SeoulDayKey.make(year: monthIndex / 12, month: monthIndex % 12 + 1, day: 1)
        _ = try? register.execute(EmployeeRegistration(
            name: "김하나", phone: nil, hireDayKey: hire, wageType: .hourly, amount: 10_320,
            weekdays: [1, 2, 3, 4, 5], startMinute: 540, endMinute: 1080, breakMinutes: 60), in: workplace)
        _ = try? register.execute(EmployeeRegistration(
            name: "이두리", phone: nil, hireDayKey: hire, wageType: .hourly, amount: 11_000,
            weekdays: [6, 7], startMinute: 600, endMinute: 1200, breakMinutes: 60), in: workplace)
    }
}
#endif
