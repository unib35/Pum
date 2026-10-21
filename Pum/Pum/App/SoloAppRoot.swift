import SwiftData
import SwiftUI

/// MVP 앱(DEC-028 · DEC-033): 사업장이 없으면 사업장 만들기(2i), 있으면 직원 · 급여 · 설정 탭.
struct SoloAppRoot: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    var tab: AppTab?

    var body: some View {
        if workplaces.isEmpty {
            WorkplaceCreateView(state: .soloEntry, onNext: { state, done in
                done(createWorkplace(state))
            })
        } else {
            AppShell(role: .soloOwner, tab: tab)
        }
    }

    private func createWorkplace(_ state: WorkplaceCreateState) -> Bool {
        let repository = SwiftDataWorkplaceRepository(context: context)
        do {
            let workplace = try repository.create(
                name: state.trimmedName, isFiveOrMore: state.isFiveOrMore,
                deduction: state.withholds3_3 ? .business3_3 : .none, payday: state.payday)
            try repository.update(workplace) { $0.colorIndex = state.markColorIndex }
            return true
        } catch {
            return false
        }
    }
}
