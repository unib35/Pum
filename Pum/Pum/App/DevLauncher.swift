import SwiftUI

/// 개발용 시작 화면(디자인 화면 아님)
struct DevLauncher: View {
    private enum Mode {
        case employee, owner, fromStart
    }
    @State private var mode: Mode?

    var body: some View {
        switch mode {
        case .employee: AppShell(role: .employee) { mode = nil }
        case .owner: AppShell(role: .owner) { mode = nil }
        case .fromStart: AppShell(role: .owner, start: [.auth(.welcome)]) { mode = nil }
        case nil: menu
        }
    }

    private var menu: some View {
        NavigationStack {
            List {
                Section {
                    Button("직원 앱으로 보기") { mode = .employee }
                    Button("사장님 앱으로 보기") { mode = .owner }
                    Button("앱 처음부터 (2a)") { mode = .fromStart }
                } header: {
                    Text("앱처럼 연결된 화면")
                } footer: {
                    Text("탭 바와 버튼이 흐름 지도(J1–J15)대로 이어져요. 화면 맨 위 가운데 작은 ×를 누르면 여기로 돌아와요. 값은 모두 예시예요.")
                }
                Section("확인용") {
                    NavigationLink("연결 현황") { ConnectionStatusView() }
                    NavigationLink("화면 목록") { ScreenListView(routes: AppRoute.all) }
                    NavigationLink("컴포넌트 갤러리") { ComponentGalleryView() }
                }
            }
            .navigationTitle("품 · 개발용")
        }
    }
}

/// 화면 목록 — 누르면 그 화면이 쌓인 실제 앱(AppShell)이 열려 버튼이 다음 화면으로 이어진다. 위 × 로 목록에 돌아온다.
struct ScreenListView: View {
    let routes: [AppRoute]
    @State private var opened: AppRoute?

    var body: some View {
        List(routes) { route in
            Button("\(route.screenID) \(route.title)") { opened = route }
        }
        .navigationTitle("화면 목록")
        .fullScreenCover(item: $opened) { route in
            AppShell(role: Self.role(for: route), start: [route]) { opened = nil }
        }
    }

    /// 흐름 지도에서 사장님이 쓰는 화면(개발용 대략 구분 — 탭 바 모양만 달라진다)
    static let ownerScreens: Set<String> = [
        "1aq", "1ar", "5a", "1r", "1s", "1t", "1u", "1v", "1w", "1x", "1ac", "1ad", "1af", "1ah", "1an",
        "2i", "2l", "3c", "3d", "4c", "5b", "5c", "5d", "5e", "6g", "6h", "6j", "6l",
        "7a", "7b", "7c", "8a", "8b", "8c", "8d", "8e", "9a", "9b", "9c", "9d",
        "10a", "10b", "10c", "10d", "10e", "10f", "10g", "10h", "10k", "10l", "10m", "10n", "10p", "10q", "10r", "10s",
        "17a", "17b", "17c", "17d", "17h", "17j", "19a", "19b", "19e", "19i",
        "20a", "20b", "20c", "20d", "20e", "20f", "20g", "20h", "20l", "21a", "21b", "21d", "21e", "21j", "21l", "21n",
    ]

    static func role(for route: AppRoute) -> AppRole { ownerScreens.contains(route.screenID) ? .owner : .employee }
}

struct ConnectionStatusView: View {
    var body: some View {
        let connected = AppRoute.all.filter(\.isConnected)
        let rest = AppRoute.all.filter { !$0.isConnected }
        List {
            Section("연결됨 \(connected.count)") {
                ForEach(connected) { Text("\($0.screenID) \($0.title)") }
            }
            Section("아직 연결 안 됨 \(rest.count)") {
                NavigationLink("목록으로 보기") { ScreenListView(routes: rest) }
            }
        }
        .navigationTitle("연결 현황")
    }
}
