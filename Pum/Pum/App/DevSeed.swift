#if DEBUG
import Foundation
import SwiftData
import SwiftUI

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
        let hire = firstDayOfMonth(monthsAgo: 2)
        _ = try? register.execute(EmployeeRegistration(
            name: "김하나", phone: nil, hireDayKey: hire, wageType: .hourly, amount: 10_320,
            weekdays: [1, 2, 3, 4, 5], startMinute: 540, endMinute: 1080, breakMinutes: 60), in: workplace)
        _ = try? register.execute(EmployeeRegistration(
            name: "이두리", phone: nil, hireDayKey: hire, wageType: .hourly, amount: 11_000,
            weekdays: [6, 7], startMinute: 600, endMinute: 1200, breakMinutes: 60), in: workplace)
    }

    /// `-PumPath solo-20e,solo-20f,solo-1m`: 직원이 필요한 화면은 먼저 등록한 직원으로 연다(#489)
    static func soloPath(_ ids: [String], _ context: ModelContext) -> [AppRoute] {
        let employees = (try? context.fetch(FetchDescriptor<Employee>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        guard let employee = employees.first?.persistentModelID else { return [] }
        return ids.compactMap { id -> SoloRoute? in
            switch id {
            case "solo-20e": .staffDetail(employee)
            case "solo-20f": .staffDay(employee, firstDayOfMonth(monthsAgo: 0))
            case "solo-20b": .registerBasic
            case "solo-20c": .registerTerms
            case "solo-20d": .registerContract
            case "solo-20g": .workClosing
            case "solo-1m": .payslip("\(employee)")
            case "solo-20h": .payslipSend
            default: nil
            }
        }
        .map(AppRoute.solo)
    }

    private static func firstDayOfMonth(monthsAgo: Int) -> Int {
        let today = SeoulDayKey.from(.now)
        let index = SeoulDayKey.year(today) * 12 + SeoulDayKey.month(today) - 1 - monthsAgo
        return SeoulDayKey.make(year: index / 12, month: index % 12 + 1, day: 1)
    }
}

/// 예시 데이터를 넣고 시작 화면을 정한 뒤 MVP 앱을 연다
struct DevSoloRoot: View {
    let tab: AppTab?
    let seed: String?
    let pathIDs: [String]
    @Environment(\.modelContext) private var context
    @State private var start: [AppRoute]?

    var body: some View {
        if let start {
            SoloAppRoot(tab: tab, start: start)
        } else {
            Color.clear.onAppear {
                if seed == "demo" { DevSeed.run(context) }
                start = DevSeed.soloPath(pathIDs, context)
            }
        }
    }
}
#endif
