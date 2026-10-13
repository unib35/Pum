//
//  ContentView.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftUI

/// 실행 인자
/// - `-PumScreen 1at`: 그 화면을 예시로 바로 연다(비교 캡처용)
/// - `-PumApp employee|owner` (+ `-PumPath 1e,10v`): 연결된 앱을 그 화면들이 쌓인 상태로 연다(연결 확인용)
/// 그 밖에는 개발용 시작 화면.
/// 디자인에 다크 모드 값이 없어 라이트로 고정한다(README 「테마」).
struct ContentView: View {
    private let screenID = UserDefaults.standard.string(forKey: "PumScreen")
    private let appRole = UserDefaults.standard.string(forKey: "PumApp")
    private let appPath = (UserDefaults.standard.string(forKey: "PumPath") ?? "")
        .split(separator: ",").compactMap { AppRoute(screenID: String($0)) }

    var body: some View {
        Group {
            if screenID == "gallery" {
                ComponentGalleryView()
            } else if let id = screenID, let route = AppRoute(screenID: id) {
                route.view(AppRouter(role: .employee))
            } else if let appRole {
                AppShell(role: appRole == "owner" ? .owner : .employee, start: appPath) {}
            } else {
                DevLauncher()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
