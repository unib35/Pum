import SwiftUI

enum HomeRoute: String, CaseIterable, Hashable {
    case employeeHome = "1at"
    case employeeHomeNoShift = "1au"
    case employeeHomeWorking = "1av"
    case ownerHome = "1aq"
    case ownerHomeClear = "1ar"
    case employeeHomeOvertime = "1ak"
    case workplaceSwitcher = "1y"
    case personalHome = "2f"
    case ownerHomeUnverified = "5a"
    case ownerHomeLoading = "21j"
    case employeeHomeLoading = "21k"
    case ownerHomeLoadFailed = "21n"
    case offline = "6q"
    case updateRecommended = "6u"
    case maintenanceNotice = "6v"

    var title: String {
        switch self {
        case .employeeHome: "직원 홈 · 출근 전"
        case .employeeHomeNoShift: "직원 홈 · 근무 없는 날"
        case .employeeHomeWorking: "직원 홈 · 근무 중"
        case .ownerHome: "사장님 홈 (1az 색)"
        case .ownerHomeClear: "사장님 홈 · 할 일 0건"
        case .employeeHomeOvertime: "연장 근무 중"
        case .workplaceSwitcher: "사업장 전환"
        case .personalHome: "개인 모드 홈"
        case .ownerHomeUnverified: "미인증 사업장 홈"
        case .ownerHomeLoading: "사장님 홈 로딩"
        case .employeeHomeLoading: "직원 홈 로딩"
        case .ownerHomeLoadFailed: "사장님 홈 불러오기 실패"
        case .offline: "오프라인"
        case .updateRecommended: "업데이트 권장"
        case .maintenanceNotice: "점검 예고"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .employeeHome:
            EmployeeHomeView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onClockIn: { router.navigate(.attendance(.clockIn)) }
            )
        case .employeeHomeNoShift:
            EmployeeHomeNoShiftView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onUnplannedClockIn: { router.navigate(.attendance(.clockIn)) }
            )
        case .employeeHomeWorking:
            EmployeeHomeWorkingView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onClockOut: { router.navigate(.attendance(.clockOutDone)) }
            )
        case .ownerHome:
            OwnerHomeView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onDecide: { _ in router.navigate(.attendance(.ownerReview)) },
                onClockOutCheck: { _ in router.navigate(.attendance(.ownerReview)) },
                onOpenOthers: { router.navigate(.attendance(.ownerReview)) }
            )
        case .ownerHomeClear:
            OwnerHomeClearView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) }
            )
        case .employeeHomeOvertime:
            EmployeeHomeOvertimeView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onClockOut: { router.navigate(.attendance(.clockOutDone)) }
            )
        case .workplaceSwitcher:
            WorkplaceSwitcherView(
                onClose: router.back,
                onSelect: { _ in router.back() },
                onShowAll: { router.navigate(.workplace(.ownerWorkplaces)) },
                onAddByCode: { router.navigate(.employee(.inviteCode)) }
            )
        case .personalHome:
            PersonalHomeView(
                state: .sample,
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onClockIn: { router.navigate(.attendance(.clockIn)) },
                onOpenCalendar: { router.navigate(.attendance(.workCalendar)) },
                onOpenPayBasis: { router.navigate(.payroll(.expectedPay)) }
            )
        case .ownerHomeUnverified:
            OwnerHomeUnverifiedView(
                state: .sample,
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                onOpenStep: { id in if id == "clockin" { router.navigate(.workplace(.checkInQR)) } },
                onVerify: { router.navigate(.workplace(.verifyIntro)) },
                onSaveQR: { router.navigate(.workplace(.checkInQR)) }
            )
        case .ownerHomeLoading:
            OwnerHomeView(isLoading: true)
        case .employeeHomeLoading:
            EmployeeHomeView(isLoading: true)
        case .ownerHomeLoadFailed:
            OwnerHomeView(
                onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) },
                onBell: { router.navigate(.notice(.newsFeed)) },
                staleSince: OwnerHomeLoadFailed.sampleSince
            )
        case .offline:
            EmployeeHomeWorkingView(state: .offline, onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) }, onBell: { router.navigate(.notice(.newsFeed)) }, onClockOut: { router.navigate(.attendance(.clockOutDone)) })
        case .updateRecommended:
            EmployeeHomeNoShiftView(state: .updateAvailable, onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) }, onBell: { router.navigate(.notice(.newsFeed)) }, onUnplannedClockIn: { router.navigate(.attendance(.clockIn)) })
        case .maintenanceNotice:
            EmployeeHomeNoShiftView(state: .maintenanceNotice, onSwitchWorkplace: { router.navigate(.home(.workplaceSwitcher)) }, onBell: { router.navigate(.notice(.newsFeed)) }, onUnplannedClockIn: { router.navigate(.attendance(.clockIn)) })
        }
    }

    static let connected: Set<Self> = [
        .employeeHome, .employeeHomeNoShift, .employeeHomeWorking, .ownerHome, .ownerHomeClear, .employeeHomeOvertime,
        .ownerHomeLoadFailed,
        .workplaceSwitcher, .personalHome, .ownerHomeUnverified, .offline, .updateRecommended, .maintenanceNotice,
    ]
}
