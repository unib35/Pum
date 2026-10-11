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
            case "1aa": SignaturePadView(drawing: .sample) // 원문 캡처는 예시 서명이 그려진 모습
            case "1ak": EmployeeHomeOvertimeView()
            case "1ao": EarlyLeaveView()
            case "1al": MissingClockOutView(state: .sample)
            case "1ae": RecordReviewView()
            case "1y": WorkplaceSwitcherView()
            case "1ab": ContractListView()
            case "1r": OwnerReviewView()
            case "1s": EditApprovalView()
            case "1t": OwnerScheduleView()
            case "1u": OwnerPayrollView()
            case "1v": PayrollConfirmView()
            case "1w": OwnerWorkplacesView()
            case "1x": StaffInviteView(draft: .sample, showsPhoneFocus: true)
            case "1ac": StaffListView()
            case "1ad": RecordReviewRequestView()
            case "1af": OwnerManualEntryView(draft: .sample)
            case "1ah": OwnerRecordActionsView()
            case "1an": AttendancePolicyView()
            case "3b": NoticeDetailView(state: .sample)
            case "3a": NewsFeedView(state: .sample)
            case "3c": NoticeComposeView(state: .sample)
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
                    NavigationLink("1aa 서명 패드") { SignaturePadView(drawing: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ak 연장 근무 중") { EmployeeHomeOvertimeView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ao 조기 퇴근") { EarlyLeaveView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1al 퇴근 미확정") { MissingClockOutView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ae 근무기록 확인 요청") { RecordReviewView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1y 사업장 전환") { WorkplaceSwitcherView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ab 계약서 보관함") { ContractListView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1r 확인 필요 근무") { OwnerReviewView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1s 수정 요청 승인") { EditApprovalView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1t 사업장 스케줄") { OwnerScheduleView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1u 급여 정산") { OwnerPayrollView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1v 급여 확정 시트") { PayrollConfirmView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1w 전체 사업장") { OwnerWorkplacesView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1x 직원 초대") { StaffInviteView(draft: .sample, showsPhoneFocus: true).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ac 직원 관리") { StaffListView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ad 확인 요청 시트") { RecordReviewRequestView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1af 근무기록 직접 추가") { OwnerManualEntryView(draft: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1ah 근무기록 삭제 시트") { OwnerRecordActionsView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("1an 근태 정책") { AttendancePolicyView().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("3b 공지 상세") { NoticeDetailView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("3a 소식") { NewsFeedView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("3c 공지 작성") { NoticeComposeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
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
