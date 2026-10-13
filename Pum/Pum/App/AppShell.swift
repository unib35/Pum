import SwiftUI

/// 직원 · 사장님 앱. 탭 바는 각 탭 화면 안에 있고, 누르면 여기서 탭을 바꾼다.
struct AppShell: View {
    @State private var router: AppRouter
    let onExit: () -> Void

    init(role: AppRole, start: [AppRoute] = [], onExit: @escaping () -> Void) {
        _router = State(initialValue: AppRouter(role: role, start: start))
        self.onExit = onExit
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            router.root.view(router)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    route.view(router).toolbar(.hidden, for: .navigationBar)
                }
        }
        .id(router.tab)
        .environment(\.pumTabSelect) { id in
            if let tab = AppTab(rawValue: id) { router.select(tab) }
        }
        .overlay(alignment: .top) { exitButton }
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
