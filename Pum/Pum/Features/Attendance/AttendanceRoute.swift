import SwiftUI

enum AttendanceRoute: String, CaseIterable, Hashable {
    case workDetail = "1h"
    case workCalendar = "1g"
    case clockOutDone = "1f"
    case clockIn = "1e"
    case editRequest = "1i"
    case earlyLeave = "1ao"
    case missingClockOut = "1al"
    case recordReview = "1ae"
    case ownerReview = "1r"
    case editApproval = "1s"
    case ownerManualEntry = "1af"
    case ownerRecordActions = "1ah"
    case personalRecordDetail = "2g"
    case timePickerSheet = "C13"
    case checkInTooFar = "10u"
    case checkInPassed = "10t"
    case checkInLowAccuracy = "10w"
    case locationCheckIn = "10v"
    case recordCorrection = "10f"
    case adminConfirmCheckIn = "10x"
    case checkInJudging = "21m"
    case locationPermissionIntro = "6e"
    case workCalendarEmpty = "6p"
    case locationDenied = "6r"
    case myLeave = "19g"
    case breakReview = "19i"
    case breakReport = "19h"
    case inheritedRecords = "20l"

    var title: String {
        switch self {
        case .workDetail: "근무 상세"
        case .workCalendar: "근무 캘린더"
        case .clockOutDone: "퇴근 완료"
        case .clockIn: "출근 기록"
        case .editRequest: "근무기록 수정 요청"
        case .earlyLeave: "조기 퇴근"
        case .missingClockOut: "퇴근 미확정"
        case .recordReview: "근무기록 확인 요청"
        case .ownerReview: "확인 필요 근무"
        case .editApproval: "수정 요청 승인"
        case .ownerManualEntry: "근무기록 직접 추가"
        case .ownerRecordActions: "근무기록 삭제 시트"
        case .personalRecordDetail: "개인 기록 상세"
        case .timePickerSheet: "시간 고르기 시트"
        case .checkInTooFar: "출근 판정 거리 초과"
        case .checkInPassed: "출근 판정 통과"
        case .checkInLowAccuracy: "위치 오차가 클 때"
        case .locationCheckIn: "위치만 간편 출근"
        case .recordCorrection: "마감 후 정정"
        case .adminConfirmCheckIn: "관리자 확인 출근 대기"
        case .checkInJudging: "출근 판정 중"
        case .locationPermissionIntro: "위치 권한 안내"
        case .workCalendarEmpty: "근무기록 없음"
        case .locationDenied: "위치 권한 꺼짐"
        case .myLeave: "내 연차"
        case .breakReview: "휴게 못 씀 확인"
        case .breakReport: "휴게를 못 썼을 때"
        case .inheritedRecords: "지난 근무기록"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .workDetail:
            WorkDetailView()
        case .workCalendar:
            WorkCalendarView()
        case .clockOutDone:
            ClockOutDoneView(onClose: router.backToRoot)
        case .clockIn:
            ClockInView(
                onBack: router.back,
                onLocation: { router.navigate(.attendance(.locationCheckIn)) },
                onClockInByLocation: { router.navigate(.attendance(.locationCheckIn)) }
            )
        case .editRequest:
            EditRequestView()
        case .earlyLeave:
            EarlyLeaveView(onContinue: router.back, onRecord: { _ in router.replace(with: .attendance(.clockOutDone)) })
        case .missingClockOut:
            MissingClockOutView(state: .sample, onRequest: { _, _ in router.backToRoot() })
        case .recordReview:
            RecordReviewView()
        case .ownerReview:
            OwnerReviewView()
        case .editApproval:
            EditApprovalView()
        case .ownerManualEntry:
            OwnerManualEntryView(draft: .sample)
        case .ownerRecordActions:
            OwnerRecordActionsView()
        case .personalRecordDetail:
            PersonalRecordDetailView(state: .sample)
        case .timePickerSheet:
            PumTimePickerDemo()
        case .checkInTooFar:
            CheckInTooFarView(onClose: router.back)
        case .checkInPassed:
            CheckInPassedView(state: .sample, onDone: { router.path = [.home(.employeeHomeWorking)] })
        case .checkInLowAccuracy:
            CheckInLowAccuracyView(onClose: router.back, onScanQR: router.back)
        case .locationCheckIn:
            LocationCheckInView(onCheckIn: { done in
                done(true)
                router.replace(with: .attendance(.checkInPassed))
            })
        case .recordCorrection:
            RecordCorrectionView(state: .sample, reason: RecordCorrectionState.sampleReason)
        case .adminConfirmCheckIn:
            AdminConfirmCheckInView()
        case .checkInJudging:
            CheckInJudgingView(state: .sample)
        case .locationPermissionIntro:
            LocationPermissionIntroView(state: .sample, isPresented: true)
        case .workCalendarEmpty:
            WorkCalendarView(state: .empty)
        case .locationDenied:
            LocationDeniedView(state: .sample)
        case .myLeave:
            MyLeaveView(state: .sample)
        case .breakReview:
            BreakReviewView(state: .sample)
        case .breakReport:
            BreakReportView(state: .sample, sheet: .sample, startsWithSheetOpen: true)
        case .inheritedRecords:
            InheritedRecordsView(state: .sample)
        }
    }

    static let connected: Set<Self> = [.clockIn, .locationCheckIn, .checkInPassed, .clockOutDone, .checkInTooFar, .checkInLowAccuracy, .earlyLeave, .missingClockOut]
}
