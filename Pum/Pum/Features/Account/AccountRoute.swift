import SwiftUI

enum AccountRoute: String, CaseIterable, Hashable {
    case notificationSettings = "4b"
    case myInfo = "4a"
    case afterLeaving = "10o"
    case accountSecurity = "6a"
    case withdraw = "6b"
    case consents = "6d"
    case policies = "6c"
    case appPermissions = "6f"
    case ownerNotificationSettings = "6g"
    case documentBox = "6k"
    case helpCenter = "6m"
    case privacyAppInfo = "6o"
    case forceUpdate = "6t"
    case maintenance = "6w"
    case employmentCertRequest = "19d"
    case employmentCertIssued = "19f"

    var title: String {
        switch self {
        case .notificationSettings: "알림 설정"
        case .myInfo: "내 정보"
        case .afterLeaving: "퇴사 후"
        case .accountSecurity: "계정 · 로그인 및 보안"
        case .withdraw: "회원 탈퇴"
        case .consents: "내 동의 내역"
        case .policies: "약관 및 정책"
        case .appPermissions: "앱 권한"
        case .ownerNotificationSettings: "사장님 알림 설정"
        case .documentBox: "문서함"
        case .helpCenter: "고객센터"
        case .privacyAppInfo: "개인정보 · 앱 정보"
        case .forceUpdate: "업데이트 필수"
        case .maintenance: "점검 중"
        case .employmentCertRequest: "재직증명서 요청"
        case .employmentCertIssued: "발급된 재직증명서"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .notificationSettings:
            NotificationSettingsView(state: .sample, onBack: router.back)
        case .myInfo:
            MyInfoView(
                state: .sample,
                onOpenAccount: { router.navigate(.account(.accountSecurity)) },
                onAddInviteCode: { router.navigate(.onboarding(.inviteCode)) },
                onOpenPersonalTerms: { router.navigate(.onboarding(.personalTerms)) },
                onOpenContracts: { router.navigate(.contract(.contractList)) },
                onOpenDocuments: { router.navigate(.account(.documentBox)) },
                onOpenNotifications: { router.navigate(.account(.notificationSettings)) },
                onStartOwnerMode: { router.navigate(.workplace(.workplaceCreate)) },
                onOpenSupport: { router.navigate(.account(.helpCenter)) }
            )
        case .afterLeaving:
            AfterLeavingView(
                state: .sample,
                onBack: router.back,
                onRequestCertificate: { router.navigate(.account(.employmentCertRequest)) }
            )
        case .accountSecurity:
            AccountSecurityView(
                state: .sample,
                onBack: router.back,
                onWithdraw: { router.navigate(.account(.withdraw)) }
            )
        case .withdraw:
            WithdrawView(
                state: .sample,
                onBack: router.back,
                onTransferOwnership: { _ in router.navigate(.staff(.ownerTransfer)) }
            )
        case .consents:
            ConsentsView(state: .sample, onBack: router.back)
        case .policies:
            PoliciesView(
                state: .sample,
                onBack: router.back,
                onOpenConsents: { router.navigate(.account(.consents)) }
            )
        case .appPermissions:
            AppPermissionsView(state: .sample, onBack: router.back)
        case .ownerNotificationSettings:
            OwnerNotificationSettingsView(state: .sample, onBack: router.back)
        case .documentBox:
            DocumentBoxView(
                state: .sample,
                onIssue: { _ in router.navigate(.account(.employmentCertRequest)) }
            )
        case .helpCenter:
            HelpCenterView(state: .sample, onBack: router.back)
        case .privacyAppInfo:
            PrivacyAppInfoView(state: .sample, onBack: router.back)
        case .forceUpdate:
            ForceUpdateView(
                state: .sample,
                onClockOutOnly: { router.navigate(.attendance(.clockOutDone)) }
            )
        case .maintenance:
            MaintenanceView(
                state: .sample,
                onClockOut: { router.navigate(.attendance(.clockOutDone)) },
                onClockIn: { router.navigate(.attendance(.clockIn)) }
            )
        case .employmentCertRequest:
            EmploymentCertRequestView(
                state: .sample,
                onBack: router.back,
                onRequest: { _, done in
                    done(true)
                    router.navigate(.staff(.employmentCertIssue))
                }
            )
        case .employmentCertIssued:
            EmploymentCertIssuedView(state: .sample, onBack: router.back)
        }
    }

    static let connected: Set<Self> = [
        .notificationSettings, .myInfo, .afterLeaving, .accountSecurity, .withdraw, .consents,
        .policies, .appPermissions, .ownerNotificationSettings, .documentBox, .helpCenter,
        .privacyAppInfo, .forceUpdate, .maintenance, .employmentCertRequest, .employmentCertIssued,
    ]
}
