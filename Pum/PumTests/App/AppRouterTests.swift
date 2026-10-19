import Testing
@testable import Pum

// DEC-032 — MVP 탭: 직원 · 급여 · 설정
@MainActor
struct AppRouterTests {
    @Test func MVP는_직원_탭에서_시작() {
        let router = AppRouter(role: .soloOwner)
        #expect(router.tab == .staff)
        #expect(router.root == .solo(.staffList))
    }

    @Test func MVP_탭별_첫_화면() {
        let router = AppRouter(role: .soloOwner)
        router.select(.pay)
        #expect(router.root == .solo(.payroll))
        router.select(.settings)
        #expect(router.root == .solo(.settings))
    }

    @Test func MVP_탭_바_항목은_라우터_탭과_같다() {
        let ids = PumTabItem.soloOwnerTabs.map(\.id)
        #expect(ids == ["staff", "pay", "settings"])
        #expect(ids.allSatisfy { AppTab(rawValue: $0) != nil })
    }

    @Test func 시작_화면은_고른_탭에_쌓인다() {
        let router = AppRouter(role: .owner, tab: .pay, start: [.payroll(.workClosing)])
        #expect(router.path == [.payroll(.workClosing)])
        router.select(.home)
        #expect(router.path.isEmpty)
    }
}
