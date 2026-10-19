// UI-IOS-4c — MVP 설정 값
import Testing
@testable import Pum

@MainActor
struct SoloSettingsTests {
    @Test func 사업장_값으로_설정_문구() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee()
        try store.workplaces.update(workplace) { $0.isFiveOrMore = true; $0.deduction = .business3_3; $0.payday = 25 }

        let state = SoloSettingsScreen.state(workplace)
        #expect(state.isSolo)
        #expect(state.workplaceName == "품카페")
        #expect(state.infoLine == "직원 1명")
        #expect(state.payday == "매월 25일")
        #expect(state.fiveOrMoreText == "예")
        #expect(state.deductionText == "3.3%")
        #expect(!state.isMeRepresentative) // 폐업 버튼 없음
    }
}
