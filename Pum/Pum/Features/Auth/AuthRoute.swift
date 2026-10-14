import SwiftUI

enum AuthRoute: String, CaseIterable, Hashable {
    case afterLeaving = "10o"
    case accountSecurity = "6a"
    case withdraw = "6b"
    case phoneVerify = "2b"
    case welcome = "2a"
    case startChoice = "2c"
    case personalTerms = "2e"
    case accessEnded = "6s"

    var title: String {
        switch self {
        case .afterLeaving: "퇴사 후"
        case .accountSecurity: "계정 · 로그인 및 보안"
        case .withdraw: "회원 탈퇴"
        case .phoneVerify: "휴대폰 인증"
        case .welcome: "시작"
        case .startChoice: "시작 방식"
        case .personalTerms: "개인 근로조건"
        case .accessEnded: "만료 · 접근 종료"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .afterLeaving:
            AfterLeavingView(
                state: .sample,
                onBack: router.back,
                onOpenDocument: { kind in
                    switch kind {
                    case .contract: router.navigate(.employee(.contractList)) // 「근로계약서」 → 1ab
                    case .payslip: router.navigate(.payroll(.payslip)) // 「급여명세서」 → 1m
                    case .workRecord: break // 근거 없음
                    }
                },
                onRequestCertificate: { router.navigate(.employee(.employmentCertRequest)) }
            )
        case .accountSecurity:
            AccountSecurityView(
                state: .sample,
                onBack: router.back,
                onLogout: { // 로그아웃 → 2a 시작(처음부터)
                    router.backToRoot()
                    router.replace(with: .auth(.welcome))
                },
                onWithdraw: { router.navigate(.auth(.withdraw)) }
            )
        case .withdraw:
            WithdrawView(
                state: .sample,
                onBack: router.back,
                onTransferOwnership: { _ in router.navigate(.employee(.ownerTransfer)) },
                onWithdraw: { // 탈퇴 끝 → 2a
                    router.backToRoot()
                    router.replace(with: .auth(.welcome))
                }
            )
        case .phoneVerify:
            PhoneVerifyView(
                state: .sample,
                onBack: router.back,
                onConfirm: { _ in router.navigate(.auth(.startChoice)) }
            )
        case .welcome:
            WelcomeView(
                state: .sample,
                onKakao: { router.navigate(.auth(.phoneVerify)) },
                onApple: { router.navigate(.auth(.phoneVerify)) },
                onPhone: { router.navigate(.auth(.phoneVerify)) }
            )
        case .startChoice:
            StartChoiceView(
                state: .sample,
                onNext: { choice in
                    switch choice {
                    case .personal: router.navigate(.auth(.personalTerms))
                    case .inviteCode: router.navigate(.employee(.inviteCode))
                    case .owner: router.navigate(.workplace(.workplaceCreate))
                    }
                }
            )
        case .personalTerms:
            PersonalTermsView(
                state: .sample,
                onBack: router.back,
                onStart: { _ in router.replace(with: .home(.personalHome)) },
                onLater: { router.replace(with: .home(.personalHome)) }
            )
        case .accessEnded:
            AccessEndedView(
                state: .inviteExpired,
                onSecondary: { router.navigate(.employee(.inviteCode)) }
            )
        }
    }

    static let connected: Set<Self> = [
        .afterLeaving, .accountSecurity, .withdraw, .phoneVerify,
        .welcome, .startChoice, .personalTerms, .accessEnded,
    ]

}
