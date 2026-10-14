import SwiftUI

enum ScheduleRoute: String, CaseIterable, Hashable {
    case mySchedule = "1j"
    case ownerSchedule = "1t"
    case extraShiftRequest = "2j"
    case extraShiftOffer = "2k"
    case staffingNeeds = "9a"
    case scheduleOptions = "9b"
    case scheduleOptionDetail = "9c"
    case scheduleManualEdit = "9d"
    case leaveRequest = "10i"
    case requestInbox = "10k"
    case shiftChangeRequest = "10j"
    case publishedSchedule = "17e"
    case scheduleDraft = "17a"
    case scheduleAddShift = "17b"
    case schedulePublishConfirm = "17c"
    case scheduleChangeAfterPublish = "17d"
    case shiftChangeReceived = "17f"
    case coverRequestReceived = "17g"

    var title: String {
        switch self {
        case .mySchedule: "내 스케줄 · 대타 요청"
        case .ownerSchedule: "사업장 스케줄"
        case .extraShiftRequest: "추가 근무 요청"
        case .extraShiftOffer: "추가 근무 요청 받음"
        case .staffingNeeds: "필요 인력 입력"
        case .scheduleOptions: "추천 3안"
        case .scheduleOptionDetail: "절감안 상세"
        case .scheduleManualEdit: "직접 조정"
        case .leaveRequest: "휴무 신청"
        case .requestInbox: "휴무 · 변경 요청 처리"
        case .shiftChangeRequest: "근무 변경 요청"
        case .publishedSchedule: "게시 후 내 스케줄"
        case .scheduleDraft: "다음 주 초안"
        case .scheduleAddShift: "근무 추가 시트"
        case .schedulePublishConfirm: "게시 확인"
        case .scheduleChangeAfterPublish: "게시 후 변경"
        case .shiftChangeReceived: "근무 변경 요청 받음"
        case .coverRequestReceived: "대타 요청 받음"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .mySchedule:
            MyScheduleView()
        case .ownerSchedule:
            OwnerScheduleView(
                state: { var s = OwnerScheduleState.sample; s.pendingReviewCount = 4; return s }(),
                onChangeWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onOpenReview: { router.navigate(.attendance(.ownerReview)) }
            )
        case .extraShiftRequest:
            ExtraShiftRequestView(
                state: .sample,
                onClose: router.back,
                onSend: { _, done in
                    done(true)
                    router.replace(with: .schedule(.extraShiftOffer))
                }
            )
        case .extraShiftOffer:
            ExtraShiftOfferView(
                state: .sample,
                onBack: router.back,
                onAccept: { done in done(true); router.back() },
                onDecline: { done in done(true); router.back() }
            )
        case .staffingNeeds:
            StaffingNeedsView(
                state: .sample,
                onClose: router.back,
                onRecommend: { _, done in
                    done(true)
                    router.navigate(.schedule(.scheduleOptions))
                }
            )
        case .scheduleOptions:
            ScheduleOptionsView(
                state: .sample,
                onBack: router.back,
                onShowDetail: { _ in router.navigate(.schedule(.scheduleOptionDetail)) }
            )
        case .scheduleOptionDetail:
            ScheduleOptionDetailView(
                state: .sample,
                onBack: router.back,
                onSendRequests: { done in
                    done(true)
                    router.navigate(.schedule(.scheduleDraft))
                }
            )
        case .scheduleManualEdit:
            ScheduleManualEditView(
                state: .sample,
                onBack: router.back,
                onApply: { done in
                    done(true)
                    router.navigate(.schedule(.scheduleChangeAfterPublish))
                }
            )
        case .leaveRequest:
            LeaveRequestView(
                state: .sample,
                reason: "병원 예약이 있어요",
                onClose: router.back,
                onChangeShift: { router.replace(with: .schedule(.shiftChangeRequest)) },
                onSend: { _, done in
                    done(true)
                    router.back()
                }
            )
        case .requestInbox:
            RequestInboxView(state: .sample, onBack: router.back)
        case .shiftChangeRequest:
            ShiftChangeRequestView(
                state: .sample,
                start: 18 * 60,
                end: 23 * 60,
                reason: "수요일 수업이 18시에 끝나요",
                onClose: router.back,
                onSend: { _, done in
                    done(true)
                    router.back()
                }
            )
        case .publishedSchedule:
            PublishedScheduleView(
                state: .sample,
                onOpenThisWeek: { router.navigate(.schedule(.mySchedule)) },
                onRequestCover: { router.navigate(.schedule(.mySchedule)) }
            )
        case .scheduleDraft:
            ScheduleDraftView(
                state: .sample,
                onChangeWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onAddShift: { _ in router.navigate(.schedule(.scheduleAddShift)) },
                onPublish: { router.navigate(.schedule(.schedulePublishConfirm)) }
            )
        case .scheduleAddShift:
            ScheduleDraftView(state: .addingShift)
        case .schedulePublishConfirm:
            ScheduleDraftView(
                state: .confirmingPublish,
                onConfirmPublish: { router.replace(with: .schedule(.publishedSchedule)) }
            )
        case .scheduleChangeAfterPublish:
            ScheduleDraftView(
                state: .changingPublished,
                onSendChangeRequest: { _ in router.navigate(.schedule(.shiftChangeReceived)) }
            )
        case .shiftChangeReceived:
            ShiftChangeReceivedView(
                state: .sample,
                onBack: router.back,
                onAccept: { done in done(true); router.back() },
                onDecline: { done in done(true); router.back() }
            )
        case .coverRequestReceived:
            CoverRequestReceivedView(
                state: .sample,
                onBack: router.back,
                onAccept: { done in
                    done(true)
                    router.navigate(.schedule(.requestInbox))
                },
                onDecline: { done in done(true); router.back() }
            )
        }
    }

    static let connected: Set<Self> = [
        .ownerSchedule, .extraShiftRequest, .extraShiftOffer, .staffingNeeds,
        .scheduleOptions, .scheduleOptionDetail, .scheduleManualEdit, .leaveRequest,
        .requestInbox, .shiftChangeRequest, .publishedSchedule, .scheduleDraft,
        .schedulePublishConfirm, .scheduleChangeAfterPublish, .shiftChangeReceived,
        .coverRequestReceived,
    ]
}
