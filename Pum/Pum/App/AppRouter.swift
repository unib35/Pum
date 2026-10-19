import SwiftUI
import Observation

enum AppRole: Hashable {
    case employee, owner
    /// MVP: 사장님 혼자 쓰는 월급 계산(DEC-028)
    case soloOwner
}

enum AppTab: String, Hashable {
    case home, work, news, pay, me, store
    case staff, settings // MVP(DEC-032)
}

/// 화면 이동을 맡는다. 화면은 목적지만 요청하고(navigate) 쌓는 방법은 여기서 정한다.
@MainActor @Observable
final class AppRouter {
    let role: AppRole
    var tab: AppTab = .home
    private var stacks: [AppTab: [AppRoute]] = [:]

    init(role: AppRole, tab: AppTab? = nil, start: [AppRoute] = []) {
        self.role = role
        self.tab = tab ?? Self.firstTab(of: role)
        stacks[self.tab] = start
    }

    static func firstTab(of role: AppRole) -> AppTab { role == .soloOwner ? .staff : .home }

    var path: [AppRoute] {
        get { stacks[tab] ?? [] }
        set { stacks[tab] = newValue }
    }

    var root: AppRoute {
        switch (role, tab) {
        case (.employee, .work): .attendance(.workCalendar)
        case (.employee, .news): .notice(.newsFeed) // DEC-020
        case (.employee, .pay): .payroll(.expectedPay)
        case (.employee, .me): .settings(.myInfo)
        case (.owner, .work): .schedule(.ownerSchedule) // DEC-019: 평소 1t, 확인할 기록은 1t 위쪽 줄에서 1r로
        case (.owner, .pay): .payroll(.ownerPayroll)
        case (.owner, .store): .employee(.staffList)
        case (.soloOwner, .pay): .solo(.payroll)
        case (.soloOwner, .settings): .solo(.settings)
        case (.soloOwner, _): .solo(.staffList)
        case (.employee, _): .home(.employeeHome)
        case (.owner, _): .home(.ownerHome)
        }
    }

    func navigate(_ route: AppRoute) { path.append(route) }
    func back() { if !path.isEmpty { path.removeLast() } }
    /// 탭 첫 화면이면 nil(뒤로 버튼을 숨긴다)
    var backIfPushed: (() -> Void)? { path.isEmpty ? nil : { [weak self] in self?.back() } }
    func backToRoot() { path.removeAll() }
    /// 뒤로 돌아오지 않는 이동(완료 화면 등)
    func replace(with route: AppRoute) {
        if path.isEmpty { path.append(route) } else { path[path.count - 1] = route }
    }
    func select(_ tab: AppTab) { self.tab = tab }
}
