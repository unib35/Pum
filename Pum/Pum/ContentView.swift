//
//  ContentView.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftUI

/// 개발용 시작 화면 — 구현된 화면과 컴포넌트 갤러리 목록.
/// 실행 인자 `-PumScreen 1at` 이면 그 화면으로 바로 연다(비교 캡처용).
/// 디자인에 다크 모드 값이 없어 라이트로 고정한다(README 「테마」).
struct ContentView: View {
    private let screen = UserDefaults.standard.string(forKey: "PumScreen")

    var body: some View {
        Group {
            switch screen {
            case "1at": EmployeeHomeView()
            case "1au": EmployeeHomeNoShiftView()
            case "1av": EmployeeHomeWorkingView()
            case "1aq": OwnerHomeView()
            case "1h": WorkDetailView()
            case "1ar": OwnerHomeClearView()
            case "gallery": ComponentGalleryView()
            default: DevMenu()
            }
        }
        .preferredColorScheme(.light)
    }
}

private struct DevMenu: View {
    var body: some View {
        NavigationStack {
            List {
                Section("화면") {
                    NavigationLink("1at 직원 홈 · 출근 전") { EmployeeHomeView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1au 직원 홈 · 근무 없는 날") { EmployeeHomeNoShiftView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1av 직원 홈 · 근무 중") { EmployeeHomeWorkingView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1aq 사장님 홈 (1az 색)") { OwnerHomeView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1h 근무 상세") { WorkDetailView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ar 사장님 홈 · 할 일 0건") { OwnerHomeClearView().toolbar(.hidden, for: .navigationBar) }
                }
                Section("디자인 시스템") {
                    NavigationLink("컴포넌트 갤러리") { ComponentGalleryView() }
                }
            }
            .navigationTitle("품 개발 메뉴")
        }
    }
}

#Preview {
    ContentView()
}
