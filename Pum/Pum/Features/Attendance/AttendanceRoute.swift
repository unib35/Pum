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
            WorkDetailView(
                onBack: router.back,
                onRequestEdit: { router.navigate(.attendance(.editRequest)) }
            )
        case .workCalendar:
            WorkCalendarView(
                onWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onOpenDetail: { router.navigate(.attendance(.workDetail)) },
                onOpenSchedule: { router.navigate(.schedule(.mySchedule)) }
            )
        case .clockOutDone:
            ClockOutDoneView(onClose: router.backToRoot)
        case .clockIn:
            ClockInView(
                onBack: router.back,
                onLocation: { router.navigate(.attendance(.locationCheckIn)) },
                onClockInByLocation: { router.navigate(.attendance(.locationCheckIn)) },
                onRequestManual: { router.navigate(.attendance(.adminConfirmCheckIn)) }
            )
        case .editRequest:
            EditRequestView(
                onClose: router.back,
                onSubmit: { _ in router.back() }
            )
        case .earlyLeave:
            EarlyLeaveView(onContinue: router.back, onRecord: { _ in router.replace(with: .attendance(.clockOutDone)) })
        case .missingClockOut:
            MissingClockOutView(state: .sample, onRequest: { _, _ in router.backToRoot() })
        case .recordReview:
            RecordReviewView(
                onBack: router.back,
                onRequestEdit: { router.navigate(.attendance(.editRequest)) },
                onConfirm: { router.navigate(.payroll(.workClosing)) }
            )
        case .ownerReview:
            OwnerReviewView(onAction: { action, _ in
                switch action {
                case .edit: router.navigate(.attendance(.editApproval))
                case .manualInput: router.navigate(.attendance(.ownerManualEntry))
                case .approve, .confirm, .recordPlannedEnd, .reject: break
                }
            })
        case .editApproval:
            EditApprovalView(
                onBack: router.back,
                onReject: router.back,
                onApprove: router.back,
                onEditDirectly: { router.navigate(.attendance(.ownerManualEntry)) }
            )
        case .ownerManualEntry:
            OwnerManualEntryView(
                draft: .sample,
                onClose: router.back,
                onSubmit: { _ in router.back() }
            )
        case .ownerRecordActions:
            OwnerRecordActionsView(
                onBack: router.back,
                onAction: { action in
                    switch action {
                    case .editTime: router.navigate(.attendance(.ownerManualEntry))
                    case .markAbsent, .delete: router.back()
                    }
                },
                onCancel: router.back
            )
        case .personalRecordDetail:
            PersonalRecordDetailView(
                state: .sample,
                onBack: router.back,
                onDelete: router.back,
                onSave: { _, done in
                    done(true)
                    router.back()
                }
            )
        case .timePickerSheet:
            PumTimePickerDemo()
        case .checkInTooFar:
            CheckInTooFarView(
                onClose: router.back,
                onRetry: { _ in router.replace(with: .attendance(.checkInJudging)) }, // 다시 확인 → 21m(사용자 확인)
                onRequestOwner: { router.navigate(.attendance(.adminConfirmCheckIn)) }
            )
        case .checkInPassed:
            CheckInPassedView(state: .sample, onDone: { router.path = [.home(.employeeHomeWorking)] })
        case .checkInLowAccuracy:
            CheckInLowAccuracyView(
                onClose: router.back,
                onRetry: { _ in router.replace(with: .attendance(.checkInJudging)) }, // 다시 시도 → 21m(사용자 확인)
                onScanQR: router.back,
                onRequestOwner: { router.navigate(.attendance(.adminConfirmCheckIn)) }
            )
        case .locationCheckIn:
            LocationCheckInView(onCheckIn: { done in
                done(true)
                router.replace(with: .attendance(.checkInPassed))
            })
        case .recordCorrection:
            RecordCorrectionView(
                state: .sample,
                reason: RecordCorrectionState.sampleReason,
                onBack: router.back,
                onRecalculate: { _, done in
                    done(true)
                    router.navigate(.payroll(.correctionRecalc))
                }
            )
        case .adminConfirmCheckIn:
            AdminConfirmCheckInView(onCancelRequest: router.back)
        case .checkInJudging:
            CheckInJudgingView(state: .sample, onBack: router.back)
        case .locationPermissionIntro:
            LocationPermissionIntroView(
                state: .sample,
                isPresented: true,
                onContinue: { router.replace(with: .attendance(.locationCheckIn)) },
                onUseQROnly: router.back
            )
        case .workCalendarEmpty:
            WorkCalendarView(
                state: .empty,
                onOpenSchedule: { router.navigate(.schedule(.mySchedule)) }
            )
        case .locationDenied:
            LocationDeniedView(
                state: .sample,
                onBack: router.back,
                onOpenSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                },
                onUseQR: router.back,
                onRequestManual: { router.navigate(.attendance(.adminConfirmCheckIn)) }
            )
        case .myLeave:
            MyLeaveView(
                state: .sample,
                onBack: router.back,
                onRequestLeave: { router.navigate(.schedule(.leaveRequest)) }
            )
        case .breakReview:
            BreakReviewView(
                state: .sample,
                onBack: router.back,
                onOtherTime: { router.navigate(.attendance(.ownerManualEntry)) },
                onApprove: { done in
                    done(true)
                    router.back()
                }
            )
        case .breakReport:
            BreakReportView(
                state: .sample,
                sheet: .sample,
                startsWithSheetOpen: true,
                onBack: router.back,
                onSend: { _, _, done in
                    done(true)
                    router.back()
                }
            )
        case .inheritedRecords:
            InheritedRecordsView(
                state: .sample,
                onBack: router.back,
                onOpenAppRecords: { router.navigate(.attendance(.workCalendar)) }
            )
        }
    }

    static let connected: Set<Self> = [
        .clockIn, .locationCheckIn, .checkInPassed, .clockOutDone, .checkInTooFar, .checkInLowAccuracy, .earlyLeave, .missingClockOut,
        .workDetail, .workCalendar, .editRequest, .recordReview, .ownerReview, .editApproval, .ownerManualEntry, .ownerRecordActions,
        .personalRecordDetail, .recordCorrection, .adminConfirmCheckIn, .checkInJudging, .locationPermissionIntro,
        .workCalendarEmpty, .locationDenied, .myLeave, .breakReview, .breakReport, .inheritedRecords
    ]
}
