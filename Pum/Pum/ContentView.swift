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
            case "1g": WorkCalendarView()
            case "1f": ClockOutDoneView()
            case "1m": PayslipView()
            case "1e": ClockInView()
            case "1l": ExpectedPayView()
            case "1i": EditRequestView()
            case "1n": MultiWorkplacePayView()
            case "1o": InviteAcceptView()
            case "1j": MyScheduleView()
            case "1z": ContractReviewView(startsAgreed: true) // 원문 캡처는 체크한 뒤 모습
            case "1aa": SignaturePadView()
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
                    NavigationLink("1g 근무 캘린더") { WorkCalendarView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1f 퇴근 완료") { ClockOutDoneView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1m 급여명세서") { PayslipView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1e 출근 기록") { ClockInView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1l 예상 급여") { ExpectedPayView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1i 근무기록 수정 요청") { EditRequestView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1n 여러 사업장") { MultiWorkplacePayView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1o 초대 수락") { InviteAcceptView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1j 내 스케줄 · 대타 요청") { MyScheduleView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1z 근로계약서 확인") { ContractReviewView(startsAgreed: true).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1aa 서명 패드") { SignaturePadView().toolbar(.hidden, for: .navigationBar) }
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
