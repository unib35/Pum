import SwiftUI

enum StaffRoute: String, CaseIterable, Hashable {
    case staffInvite = "1x"
    case staffList = "1ac"
    case staffDetail = "2l"
    case offboarding = "10n"
    case leaveBalance = "10q"
    case offboardingNotEligible = "10r"
    case offboardingPension = "10s"
    case managerPermissions = "6h"
    case employmentStatus = "6j"
    case managerInvite = "17h"
    case managerInviteReceived = "17i"
    case ownerTransferReceived = "17k"
    case ownerTransfer = "17j"
    case employmentCertIssue = "19e"
    case staffAdd = "20a"
    case directRegisterBasic = "20b"
    case directRegisterContract = "20d"
    case directRegisterTerms = "20c"
    case appLessStaff = "20e"
    case dayFix = "20f"

    var title: String {
        switch self {
        case .staffInvite: "직원 초대"
        case .staffList: "직원 관리"
        case .staffDetail: "직원 상세"
        case .offboarding: "퇴사 정산"
        case .leaveBalance: "연차 현황"
        case .offboardingNotEligible: "퇴사 정산 · 대상 아님"
        case .offboardingPension: "퇴사 정산 · 퇴직연금 DC"
        case .managerPermissions: "관리자 권한"
        case .employmentStatus: "재직 상태"
        case .managerInvite: "관리자 초대"
        case .managerInviteReceived: "관리자 초대 받음"
        case .ownerTransferReceived: "대표 권한 이전 요청 받음"
        case .ownerTransfer: "대표 변경"
        case .employmentCertIssue: "재직증명서 발급"
        case .staffAdd: "직원 추가"
        case .directRegisterBasic: "직접 등록 · 기본 정보"
        case .directRegisterContract: "직접 등록 · 근로계약서"
        case .directRegisterTerms: "직접 등록 · 근로조건"
        case .appLessStaff: "앱 없는 직원"
        case .dayFix: "하루 고치기"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .staffInvite:
            StaffInviteView(
                draft: .sample,
                showsPhoneFocus: true,
                onBack: router.back,
                onSend: { _ in router.navigate(.contract(.workTermsInput)) }
            )
        case .staffList:
            StaffListView(
                onMember: { _ in router.navigate(.staff(.staffDetail)) },
                onAdd: { router.navigate(.staff(.staffAdd)) }
            )
        case .staffDetail:
            StaffDetailView(
                state: .sample,
                onBack: router.back,
                onEdit: { router.navigate(.staff(.employmentStatus)) }
            )
        case .offboarding:
            OffboardingView(
                state: .sample,
                onBack: router.back,
                onNextStep: { router.navigate(.account(.afterLeaving)) }
            )
        case .leaveBalance:
            LeaveBalanceView(state: .sample, onBack: router.back)
        case .offboardingNotEligible:
            OffboardingView(
                state: .notEligible,
                onBack: router.back,
                onNextStep: { router.navigate(.account(.afterLeaving)) }
            )
        case .offboardingPension:
            OffboardingView(
                state: .dcPension,
                onBack: router.back,
                onNextStep: { router.navigate(.account(.afterLeaving)) }
            )
        case .managerPermissions:
            ManagerPermissionsView(
                state: .sample,
                onBack: router.back,
                onSelectOwnerRole: { router.navigate(.staff(.ownerTransfer)) },
                onSave: { _, _ in router.back() }
            )
        case .employmentStatus:
            EmploymentStatusView(
                state: .sample,
                onBack: router.back,
                onConfirmLeave: { _ in router.navigate(.staff(.offboarding)) }
            )
        case .managerInvite:
            ManagerInviteView(
                state: .sample,
                onBack: router.back,
                onSend: { _, _, _, _, done in
                    done(true)
                    router.navigate(.staff(.managerInviteReceived))
                }
            )
        case .managerInviteReceived:
            RoleOfferReceivedView(
                state: .managerInvite,
                onBack: router.back,
                onDecline: { done in
                    done(true)
                    router.backToRoot()
                },
                onAcceptWithVerification: { done in
                    done(true)
                    router.navigate(.staff(.ownerTransfer))
                }
            )
        case .ownerTransferReceived:
            RoleOfferReceivedView(
                state: .ownerTransfer,
                onBack: router.back,
                onDecline: { done in
                    done(true)
                    router.backToRoot()
                },
                onAcceptWithVerification: { done in
                    done(true)
                    router.navigate(.staff(.managerPermissions))
                }
            )
        case .ownerTransfer:
            OwnerTransferView(
                state: .sample,
                onBack: router.back,
                onSendWithVerification: { _, _, done in
                    done(true)
                    router.navigate(.staff(.ownerTransferReceived))
                }
            )
        case .employmentCertIssue:
            EmploymentCertIssueView(
                state: .sample,
                onBack: router.back,
                onDecline: router.back,
                onIssue: { _, done in
                    done(true)
                    router.navigate(.account(.employmentCertIssued))
                }
            )
        case .staffAdd:
            StaffAddPreviewHost(state: .sample, onNext: { method in
                router.replace(with: method == .direct ? .staff(.directRegisterBasic) : .staff(.staffInvite))
            })
        case .directRegisterBasic:
            DirectRegisterBasicView(
                state: .sample,
                onBack: router.back,
                onNext: { _, done in
                    done()
                    router.navigate(.staff(.directRegisterTerms))
                }
            )
        case .directRegisterContract:
            DirectRegisterContractView(
                state: .sample,
                onBack: router.back,
                onRegister: { _, done in
                    done()
                    router.navigate(.staff(.appLessStaff))
                }
            )
        case .directRegisterTerms:
            DirectRegisterTermsView(
                state: .sample,
                onBack: router.back,
                onNext: { _, done in
                    done()
                    router.navigate(.staff(.directRegisterContract))
                }
            )
        case .appLessStaff:
            AppLessStaffView(
                state: .sample,
                sheet: .sample,
                onBack: router.back,
                onInvite: { router.navigate(.staff(.staffInvite)) },
                onSave: { _, done in
                    done(true)
                    router.navigate(.payroll(.workClosingDirect))
                }
            )
        case .dayFix:
            AppLessStaffView(
                state: .sample,
                sheet: .sample,
                startsWithSheetOpen: true,
                onBack: router.back,
                onInvite: { router.navigate(.staff(.staffInvite)) },
                onSave: { _, done in
                    done(true)
                    router.navigate(.payroll(.workClosingDirect))
                }
            )
        }
    }

    static let connected: Set<Self> = [
        .staffAdd, .staffInvite, .staffList, .staffDetail, .offboarding, .leaveBalance,
        .offboardingNotEligible, .offboardingPension, .managerPermissions, .employmentStatus,
        .managerInvite, .managerInviteReceived, .ownerTransferReceived, .ownerTransfer,
        .employmentCertIssue, .directRegisterBasic, .directRegisterContract,
        .directRegisterTerms, .appLessStaff, .dayFix,
    ]
}
