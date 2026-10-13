import SwiftUI

enum OnboardingRoute: String, CaseIterable, Hashable {
    case inviteAccept = "1o"
    case phoneVerify = "2b"
    case welcome = "2a"
    case startChoice = "2c"
    case inviteCode = "2d"
    case personalTerms = "2e"
    case inviteCodeRetry = "15e"
    case inviteExpired = "15f"
    case inviteSwitch = "2h"
    case inviteOffer = "5f"
    case inviteOfferUnverified = "21g"
    case inviteAfterSignup = "15c"
    case invitePhoneMismatch = "15g"
    case onboardingChecklist = "6i"
    case accessEnded = "6s"

    var title: String {
        switch self {
        case .inviteAccept: "초대 수락"
        case .phoneVerify: "휴대폰 인증"
        case .welcome: "시작"
        case .startChoice: "시작 방식"
        case .inviteCode: "초대 코드 입력"
        case .personalTerms: "개인 근로조건"
        case .inviteCodeRetry: "초대 코드 틀림"
        case .inviteExpired: "초대 만료"
        case .inviteSwitch: "초대 수락 전환"
        case .inviteOffer: "직원이 보는 초대"
        case .inviteOfferUnverified: "미인증 사업장 초대"
        case .inviteAfterSignup: "가입 직후 받은 초대"
        case .invitePhoneMismatch: "초대 번호가 다를 때"
        case .onboardingChecklist: "입사 준비"
        case .accessEnded: "만료 · 접근 종료"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .inviteAccept:
            InviteAcceptView()
        case .phoneVerify:
            PhoneVerifyView(state: .sample)
        case .welcome:
            WelcomeView(state: .sample)
        case .startChoice:
            StartChoiceView(state: .sample)
        case .inviteCode:
            InviteCodeView(state: .sample)
        case .personalTerms:
            PersonalTermsView(state: .sample)
        case .inviteCodeRetry:
            InviteCodeRetryView(state: .sample)
        case .inviteExpired:
            InviteExpiredView(state: .sample)
        case .inviteSwitch:
            InviteSwitchView(state: .sample)
        case .inviteOffer:
            InviteOfferView(state: .sample)
        case .inviteOfferUnverified:
            InviteOfferView(state: .unverifiedSample)
        case .inviteAfterSignup:
            InviteAfterSignupView(state: .sample)
        case .invitePhoneMismatch:
            InvitePhoneMismatchView(state: .sample)
        case .onboardingChecklist:
            OnboardingChecklistView(state: .sample)
        case .accessEnded:
            AccessEndedView(state: .inviteExpired)
        }
    }

    static let connected: Set<Self> = []
}
