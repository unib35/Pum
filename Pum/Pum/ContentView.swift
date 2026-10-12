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
            case "3d": NoticeReadStatusView(state: .sample)
            case "3c": NoticeComposeView(state: .sample)
            case "2b": PhoneVerifyView(state: .sample)
            case "2a": WelcomeView(state: .sample)
            case "2c": StartChoiceView(state: .sample)
            case "2d": InviteCodeView(state: .sample)
            case "2e": PersonalTermsView(state: .sample)
            case "2f": PersonalHomeView(state: .sample)
            case "15e": InviteCodeRetryView(state: .sample)
            case "15f": InviteExpiredView(state: .sample)
            case "2h": InviteSwitchView(state: .sample)
            case "2g": PersonalRecordDetailView(state: .sample)
            case "2i": WorkplaceCreateView(state: .sample)
            case "2j": ExtraShiftRequestView(state: .sample)
            case "2k": ExtraShiftOfferView(state: .sample)
            case "2l": StaffDetailView(state: .sample)
            case "4b": NotificationSettingsView(state: .sample)
            case "4a": MyInfoView(state: .sample)
            case "5a": OwnerHomeUnverifiedView(state: .sample)
            case "4c": WorkplaceSettingsView(state: .sample)
            case "5b": VerifyIntroView(state: .sample)
            case "5c": BusinessVerifyView(state: .sample)
            case "5e": AuthorityVerifyView(state: .sample)
            case "5d": DuplicateBusinessView(state: .sample)
            case "C13": PumTimePickerDemo()
            case "5f": InviteOfferView(state: .sample)
            case "21g": InviteOfferView(state: .unverifiedSample)
            case "7a": PaymentChecklistView(state: .sample)
            case "8a": WorkClosingView(state: .sample)
            case "8b": WorkClosingProblemsView(state: .sample)
            case "8c": WorkClosingConfirmView(state: .sample)
            case "7c": PaymentDoneConfirmScreen(state: .sample)
            case "7b": PaymentSendScreen(state: .sample)
            case "21e": PaymentSendScreen(state: .masked)
            case "8e": LaborSimulatorResultView(state: .sample)
            case "8d": LaborSimulatorView(state: .sample)
            case "9a": StaffingNeedsView(state: .sample)
            case "9b": ScheduleOptionsView(state: .sample)
            case "9c": ScheduleOptionDetailView(state: .sample)
            case "9d": ScheduleManualEditView(state: .sample)
            case "21c": PaymentNotReceivedScreen(state: .sample, memo: "국민은행 앱에서 확인했어요")
            case "21d": PaymentCheckRequestScreen(state: .sample)
            case "10a": WorkTermsInputView(state: .sample)
            case "10i": LeaveRequestView(state: .sample, reason: "병원 예약이 있어요")
            case "10k": RequestInboxView(state: .sample)
            case "10j": ShiftChangeRequestView(state: .sample, start: 18 * 60, end: 23 * 60, reason: "수요일 수업이 18시에 끝나요")
            case "10l": CheckInMethodView(state: .sample)
            case "10m": CheckInQRView(state: .sample)
            case "10u": CheckInTooFarView(state: .sample)
            case "10t": CheckInPassedView(state: .sample)
            case "10w": CheckInLowAccuracyView(state: .sample)
            case "10v": LocationCheckInView(state: .sample)
            case "10c": ContractChangeView(state: .sample)
            case "10b": ContractPreviewView(state: .sample)
            case "10d": PayslipIssueView(state: .sample)
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
                    NavigationLink("3d 공지 확인 현황") { NoticeReadStatusView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("3c 공지 작성") { NoticeComposeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2b 휴대폰 인증") { PhoneVerifyView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2a 시작") { WelcomeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2c 시작 방식") { StartChoiceView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2d 초대 코드 입력") { InviteCodeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2e 개인 근로조건") { PersonalTermsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2f 개인 모드 홈") { PersonalHomeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("15e 초대 코드 틀림") { InviteCodeRetryView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("15f 초대 만료") { InviteExpiredView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2h 초대 수락 전환") { InviteSwitchView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2g 개인 기록 상세") { PersonalRecordDetailView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2i 사업장 만들기") { WorkplaceCreateView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2j 추가 근무 요청") { ExtraShiftRequestView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2k 추가 근무 요청 받음") { ExtraShiftOfferView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("2l 직원 상세") { StaffDetailView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("4b 알림 설정") { NotificationSettingsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("4a 내 정보") { MyInfoView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5a 미인증 사업장 홈") { OwnerHomeUnverifiedView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("4c 사업장 설정") { WorkplaceSettingsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5b 사업장 인증 시트") { VerifyIntroView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5c 사업자 확인") { BusinessVerifyView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5e 관리 권한 확인") { AuthorityVerifyView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5d 사업자번호 중복") { DuplicateBusinessView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("C13 시간 선택 휠") { PumTimePickerDemo().toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("5f 직원이 보는 초대") { InviteOfferView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("21g 미인증 사업장 초대") { InviteOfferView(state: .unverifiedSample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("7a 월급날 지급 체크리스트") { PaymentChecklistView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("8a 근무 마감") { WorkClosingView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("8b 문제 기록 처리") { WorkClosingProblemsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("8c 근무 마감 확인") { WorkClosingConfirmView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("7c 지급 완료 확인") { PaymentDoneConfirmScreen(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("7b 직원별 지급 시트") { PaymentSendScreen(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("21e 지급 시트 · 계좌 가림") { PaymentSendScreen(state: .masked).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("8e 시뮬레이션 결과") { LaborSimulatorResultView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("8d 인건비 시뮬레이터") { LaborSimulatorView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("9a 필요 인력 입력") { StaffingNeedsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("9b 추천 3안") { ScheduleOptionsView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("9c 절감안 상세") { ScheduleOptionDetailView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("9d 직접 조정") { ScheduleManualEditView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("21c 아직 입금 안 됐어요") { PaymentNotReceivedScreen(state: .sample, memo: "국민은행 앱에서 확인했어요").toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("21d 입금 확인 요청") { PaymentCheckRequestScreen(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10a 근로조건 입력") { WorkTermsInputView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10i 휴무 신청") { LeaveRequestView(state: .sample, reason: "병원 예약이 있어요").toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10k 휴무 · 변경 요청 처리") { RequestInboxView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10j 근무 변경 요청") { ShiftChangeRequestView(state: .sample, start: 18 * 60, end: 23 * 60, reason: "수요일 수업이 18시에 끝나요").toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10l 출근 확인 방식") { CheckInMethodView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10m 출근 QR") { CheckInQRView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10u 출근 판정 거리 초과") { CheckInTooFarView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10t 출근 판정 통과") { CheckInPassedView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10w 위치 오차가 클 때") { CheckInLowAccuracyView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10v 위치만 간편 출근") { LocationCheckInView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10c 조건 변경") { ContractChangeView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10b 계약서 미리보기") { ContractPreviewView(state: .sample).toolbar(.hidden, for: .navigationBar) }
                    NavigationLink("10d 급여명세서 발행") { PayslipIssueView(state: .sample).toolbar(.hidden, for: .navigationBar) }
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
