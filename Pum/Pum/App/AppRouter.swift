import SwiftUI
import Observation

enum AppRole: Hashable {
    case employee, owner
}

enum AppTab: String, Hashable {
    case home, work, pay, me, store
}

/// 화면 이동을 맡는다. 화면은 목적지만 요청하고(navigate) 쌓는 방법은 여기서 정한다.
@MainActor @Observable
final class AppRouter {
    let role: AppRole
    var tab: AppTab = .home
    private var stacks: [AppTab: [AppRoute]] = [:]

    init(role: AppRole, start: [AppRoute] = []) {
        self.role = role
        stacks[.home] = start
    }

    var path: [AppRoute] {
        get { stacks[tab] ?? [] }
        set { stacks[tab] = newValue }
    }

    var root: AppRoute {
        switch (role, tab) {
        case (.employee, .work): .attendance(.workCalendar)
        case (.employee, .pay): .payroll(.expectedPay)
        case (.employee, .me): .account(.myInfo)
        case (.owner, .work): .attendance(.ownerReview)
        case (.owner, .pay): .payroll(.ownerPayroll)
        case (.owner, .store): .staff(.staffList)
        case (.employee, _): .home(.employeeHome)
        case (.owner, _): .home(.ownerHome)
        }
    }

    func navigate(_ route: AppRoute) { path.append(route) }
    func back() { if !path.isEmpty { path.removeLast() } }
    func backToRoot() { path.removeAll() }
    /// 뒤로 돌아오지 않는 이동(완료 화면 등)
    func replace(with route: AppRoute) {
        if path.isEmpty { path.append(route) } else { path[path.count - 1] = route }
    }
    func select(_ tab: AppTab) { self.tab = tab }
}
