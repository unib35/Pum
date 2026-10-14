import SwiftUI

enum SettingsRoute: String, CaseIterable, Hashable {
    case notificationSettings = "4b"
    case myInfo = "4a"
    case consents = "6d"
    case policies = "6c"
    case appPermissions = "6f"
    case ownerNotificationSettings = "6g"
    case helpCenter = "6m"
    case privacyAppInfo = "6o"
    case forceUpdate = "6t"
    case maintenance = "6w"

    var title: String {
        switch self {
        case .notificationSettings: "알림 설정"
        case .myInfo: "내 정보"
        case .consents: "내 동의 내역"
        case .policies: "약관 및 정책"
        case .appPermissions: "앱 권한"
        case .ownerNotificationSettings: "사장님 알림 설정"
        case .helpCenter: "고객센터"
        case .privacyAppInfo: "개인정보 · 앱 정보"
        case .forceUpdate: "업데이트 필수"
        case .maintenance: "점검 중"
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
                onOpenAccount: { router.navigate(.auth(.accountSecurity)) },
                onAddInviteCode: { router.navigate(.employee(.inviteCode)) },
                onOpenPersonalTerms: { router.navigate(.auth(.personalTerms)) },
                onOpenContracts: { router.navigate(.employee(.contractList)) },
                onOpenDocuments: { router.navigate(.employee(.documentBox)) },
                onOpenNotifications: { router.navigate(.settings(.notificationSettings)) },
                onStartOwnerMode: { router.navigate(.workplace(.workplaceCreate)) },
                onOpenSupport: { router.navigate(.settings(.helpCenter)) }
            )
        case .consents:
            ConsentsView(state: .sample, onBack: router.back)
        case .policies:
            PoliciesView(
                state: .sample,
                onBack: router.back,
                onOpenConsents: { router.navigate(.settings(.consents)) }
            )
        case .appPermissions:
            AppPermissionsView(state: .sample, onBack: router.back)
        case .ownerNotificationSettings:
            OwnerNotificationSettingsView(
                state: .sample,
                onBack: router.back,
                onPickWorkplace: { router.navigate(.home(.workplaceSwitcher)) }
            )
        case .helpCenter:
            HelpCenterView(state: .sample, onBack: router.back)
        case .privacyAppInfo:
            PrivacyAppInfoView(
                state: .sample,
                onBack: router.back,
                onOpen: { id in
                    switch id {
                    case "my-info": router.navigate(.settings(.myInfo))
                    case "consents": router.navigate(.settings(.consents))
                    case "documents": router.navigate(.employee(.documentBox))
                    case "delete-account": router.navigate(.auth(.withdraw))
                    case "terms", "privacy-policy": router.navigate(.settings(.policies))
                    default: break
                    }
                }
            )
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
        }
    }

    static let connected: Set<Self> = [
        .notificationSettings, .myInfo, .consents, .policies,
        .appPermissions, .ownerNotificationSettings, .helpCenter, .privacyAppInfo,
        .forceUpdate, .maintenance,
    ]

}
