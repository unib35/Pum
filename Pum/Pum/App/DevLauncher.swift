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

struct ScreenListView: View {
    let routes: [AppRoute]
    @State private var router = AppRouter(role: .employee)

    var body: some View {
        List(routes) { route in
            NavigationLink("\(route.screenID) \(route.title)") {
                route.view(router).toolbar(.hidden, for: .navigationBar)
            }
        }
        .navigationTitle("화면 목록")
    }
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
