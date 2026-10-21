//
//  ContentView.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftUI

/// 출시 앱은 MVP(사장님 혼자 쓰는 월급 계산, DEC-028 · DEC-032)로 바로 연다.
/// 개발 빌드 실행 인자
/// - `-PumScreen 1at`: 그 화면을 예시로 바로 연다(비교 캡처용)
/// - `-PumApp employee|owner|solo` (+ `-PumPath 1e,10v`, `-PumTab pay`): 연결된 앱을 그 탭 · 그 화면들이 쌓인 상태로 연다(연결 확인용)
/// - `-PumApp solo -PumSeed demo`: 저장소가 비어 있으면 예시 사업장 · 직원을 넣고 연다(흐름 캡처용)
/// 그 밖에는 개발용 시작 화면.
/// 디자인에 다크 모드 값이 없어 라이트로 고정한다(README 「테마」).
struct ContentView: View {
    var body: some View {
        #if DEBUG
        DevEntry().preferredColorScheme(.light)
        #else
        SoloAppRoot().preferredColorScheme(.light)
        #endif
    }
}

#if DEBUG
private struct DevEntry: View {
    private let screenID = UserDefaults.standard.string(forKey: "PumScreen")
    private let appRole = UserDefaults.standard.string(forKey: "PumApp")
    private let appPath = (UserDefaults.standard.string(forKey: "PumPath") ?? "")
        .split(separator: ",").compactMap { AppRoute(screenID: String($0)) }
    private let appTab = UserDefaults.standard.string(forKey: "PumTab").flatMap(AppTab.init(rawValue:))
    private let seed = UserDefaults.standard.string(forKey: "PumSeed")
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if screenID == "gallery" {
                ComponentGalleryView()
            } else if let id = screenID, let route = AppRoute(screenID: id) {
                route.view(AppRouter(role: .employee))
            } else if appRole == "solo" && appPath.isEmpty {
                SoloAppRoot(tab: appTab)
                    .onAppear { if seed == "demo" { DevSeed.run(context) } }
            } else if let appRole {
                AppShell(role: Self.role(appRole), tab: appTab, start: appPath) {}
            } else {
                DevLauncher()
            }
        }
    }

    private static func role(_ name: String) -> AppRole {
        switch name {
        case "owner": .owner
        case "solo": .soloOwner
        default: .employee
        }
    }
}
#endif

#Preview {
    ContentView()
}
