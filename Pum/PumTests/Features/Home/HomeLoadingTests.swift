// UI-IOS-21j · 21k · REQ-095 — 홈 로딩 상태 기본값
import Testing
@testable import Pum

struct HomeLoadingTests {
    @Test func 기본값은_로딩_아님() {
        #expect(OwnerHomeView().isLoading == false)
        #expect(EmployeeHomeView().isLoading == false)
    }

    @Test func 로딩_상태_예시() {
        #expect(OwnerHomeView(isLoading: true).isLoading)
        #expect(EmployeeHomeView(isLoading: true).isLoading)
    }
}
