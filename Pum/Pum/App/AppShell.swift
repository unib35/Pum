import SwiftUI

/// 직원 · 사장님 앱. 탭 바는 여기서 탭 첫 화면 아래에 한 번만 그린다(화면 안 탭 바는 숨김). 하위 화면에는 탭 바가 없다.
struct AppShell: View {
    @State private var router: AppRouter
    let onExit: () -> Void

    init(role: AppRole, tab: AppTab = .home, start: [AppRoute] = [], onExit: @escaping () -> Void) {
        let router = AppRouter(role: role, start: start)
        router.tab = tab
        _router = State(initialValue: router)
        self.onExit = onExit
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            router.root.view(router)
                .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    route.view(router).toolbar(.hidden, for: .navigationBar)
                }
        }
        .id(router.tab)
        .environment(\.pumTabSelect) { id in
            if let tab = AppTab(rawValue: id) { router.select(tab) }
        }
        .environment(\.pumHidesScreenTabBar, true)
        .overlay(alignment: .top) { exitButton }
    }

    private var tabBar: some View {
        let items = router.role == .owner ? PumTabItem.ownerTabs(workBadge: 4) : PumTabItem.employeeTabs(newsBadge: 3)
        return PumTabBar(items: items, selection: .constant(router.tab.rawValue))
            .environment(\.pumHidesScreenTabBar, false)
    }

    /// 개발용 — 다이내믹 아일랜드 바로 아래 작은 점
    private var exitButton: some View {
        Button(action: onExit) {
            Image(systemName: "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(PumColor.textTertiary.opacity(0.6))
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Space.s16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("개발용 시작 화면으로"))
        .padding(.top, -PumTokens.Space.s16)
    }
}
