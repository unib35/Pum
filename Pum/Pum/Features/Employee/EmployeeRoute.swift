import SwiftUI

enum EmployeeRoute: String, CaseIterable, Hashable {
    case documentBox = "6k"
    case employmentCertRequest = "19d"
    case employmentCertIssued = "19f"
    case contractReview = "1z"
    case signaturePad = "1aa"
    case contractList = "1ab"
    case workTermsInput = "10a"
    case contractChange = "10c"
    case contractPreview = "10b"
    case wageChangeContract = "19c"
    case contractPDFViewer = "1ap"
    case inviteAccept = "1o"
    case inviteCode = "2d"
    case inviteCodeRetry = "15e"
    case inviteExpired = "15f"
    case inviteSwitch = "2h"
    case inviteOffer = "5f"
    case inviteOfferUnverified = "21g"
    case inviteAfterSignup = "15c"
    case invitePhoneMismatch = "15g"
    case onboardingChecklist = "6i"
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
        case .documentBox: "문서함"
        case .employmentCertRequest: "재직증명서 요청"
        case .employmentCertIssued: "발급된 재직증명서"
        case .contractReview: "근로계약서 확인"
        case .signaturePad: "서명 패드"
        case .contractList: "계약서 보관함"
        case .workTermsInput: "근로조건 입력"
        case .contractChange: "조건 변경"
        case .contractPreview: "계약서 미리보기"
        case .wageChangeContract: "변경 계약서 받음"
        case .contractPDFViewer: "계약서 전문 PDF"
        case .inviteAccept: "초대 수락"
        case .inviteCode: "초대 코드 입력"
        case .inviteCodeRetry: "초대 코드 틀림"
        case .inviteExpired: "초대 만료"
        case .inviteSwitch: "초대 수락 전환"
        case .inviteOffer: "직원이 보는 초대"
        case .inviteOfferUnverified: "미인증 사업장 초대"
        case .inviteAfterSignup: "가입 직후 받은 초대"
        case .invitePhoneMismatch: "초대 번호가 다를 때"
        case .onboardingChecklist: "입사 준비"
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
        case .documentBox:
            DocumentBoxView(
                state: .sample,
                onPickWorkplace: { router.navigate(.home(.workplaceSwitcher)) }, // 6k 사업장 필터 → 1y
                onOpen: { id in
                    // 이름이 확정 화면과 같은 문서만 연다: 변경 근로계약서 → 19c · 근로계약서 → 1ab · 급여명세서 → 1m
                    switch id {
                    case "change-contract": router.navigate(.employee(.wageChangeContract))
                    case "contract-2026": router.navigate(.employee(.contractList))
                    case "payslip-main", "payslip-c": router.navigate(.payroll(.payslip))
                    default: break
                    }
                },
                onIssue: { _ in router.navigate(.employee(.employmentCertRequest)) }
            )
        case .employmentCertRequest:
            EmploymentCertRequestView(
                state: .sample,
                onBack: router.back,
                onRequest: { _, done in
                    done(true)
                    router.back()
                }
            )
        case .employmentCertIssued:
            EmploymentCertIssuedView(state: .sample, onBack: router.back)
        case .contractReview:
            ContractReviewView(
                startsAgreed: true,
                onBack: router.back,
                onSign: { router.navigate(.employee(.signaturePad)) },
                onViewFull: { router.navigate(.employee(.contractPDFViewer)) }
            )
        case .signaturePad:
            SignaturePadView(
                drawing: .sample,
                onBack: router.back,
                onComplete: { _ in
                    if router.role == .owner {
                        router.backToRoot()
                    } else {
                        router.replace(with: .employee(.onboardingChecklist))
                    }
                },
                onDismissSheet: router.back
            )
        case .contractList:
            ContractListView(
                onBack: router.back,
                onViewPDF: { _ in router.navigate(.employee(.contractPDFViewer)) },
                onConfirmChange: { _ in router.navigate(.employee(.wageChangeContract)) }
            )
        case .workTermsInput:
            WorkTermsInputView(
                state: .sample,
                onBack: router.back,
                onPreview: { router.navigate(.employee(.contractPreview)) }
            )
        case .contractChange:
            ContractChangeView(
                state: .sample,
                onBack: router.back,
                onSend: { done in
                    done(true)
                    router.backToRoot()
                }
            )
        case .contractPreview:
            ContractPreviewView(
                state: .sample,
                onBack: router.back,
                onShowFull: { router.navigate(.employee(.contractPDFViewer)) },
                onSignAndSend: { done in
                    done(true)
                    router.navigate(.employee(.signaturePad))
                }
            )
        case .wageChangeContract:
            WageChangeContractView(
                state: .sample,
                onBack: router.back,
                onOpenFull: { router.navigate(.employee(.contractPDFViewer)) },
                onSign: { router.navigate(.employee(.signaturePad)) }
            )
        case .contractPDFViewer:
            ContractPDFViewerView(
                state: .sample,
                onBack: router.back
            )
        case .inviteAccept:
            InviteAcceptView(
                onAccept: { router.navigate(.employee(.inviteOffer)) },
                onLater: router.backToRoot
            )
        case .inviteCode:
            InviteCodeView(
                state: .sample,
                onBack: router.back,
                onConfirm: { _, done in
                    done(true)
                    router.navigate(.employee(.inviteAccept))
                }
            )
        case .inviteCodeRetry:
            InviteCodeRetryView(
                state: .sample,
                onBack: router.back,
                onConfirm: { _, done in
                    done(true)
                    router.navigate(.employee(.inviteAccept))
                }
            )
        case .inviteExpired:
            InviteExpiredView(
                state: .sample,
                onBack: router.back
            )
        case .inviteSwitch:
            InviteSwitchView(
                state: .sample,
                onAccept: { done in
                    done(true)
                    router.backToRoot()
                },
                onDecline: router.back
            )
        case .inviteOffer:
            InviteOfferView(
                state: .sample,
                onJoin: { done in
                    done(true)
                    router.navigate(.employee(.contractReview))
                }
            )
        case .inviteOfferUnverified:
            InviteOfferView(
                state: .unverifiedSample,
                onJoin: { done in
                    done(true)
                    router.navigate(.employee(.contractReview))
                }
            )
        case .inviteAfterSignup:
            InviteAfterSignupView(
                state: .sample,
                onConfirm: { router.navigate(.employee(.inviteAccept)) },
                onStartWithout: { router.navigate(.auth(.startChoice)) }
            )
        case .invitePhoneMismatch:
            InvitePhoneMismatchView(
                state: .sample,
                onBack: router.back,
                onLoginWithInvitedNumber: { router.navigate(.auth(.phoneVerify)) } // 「초대받은 번호로 로그인」 → 2b
            )
        case .onboardingChecklist:
            OnboardingChecklistView(
                state: .sample,
                onBack: router.backToRoot // J2: 입사 준비 다음은 홈(1at)
            )
        case .staffInvite:
            StaffInviteView(
                draft: .sample,
                showsPhoneFocus: true,
                onBack: router.back,
                onSend: { _ in router.navigate(.employee(.workTermsInput)) }
            )
        case .staffList:
            StaffListView(
                onMember: { _ in router.navigate(.employee(.staffDetail)) },
                onSetCondition: { _ in router.navigate(.employee(.workTermsInput)) }, // 「조건 설정」 → 10a
                onAdd: { router.navigate(.employee(.staffAdd)) }
            )
        case .staffDetail:
            StaffDetailView(
                state: .sample,
                onBack: router.back,
                onEdit: { router.navigate(.employee(.employmentStatus)) },
                onOpenDocument: { id in
                    if id == "contract" { router.navigate(.employee(.contractList)) } // 「근로계약서」 → 1ab
                }
            )
        case .offboarding:
            OffboardingView(
                state: .sample,
                onBack: router.back,
                onNextStep: { router.navigate(.auth(.afterLeaving)) }
            )
        case .leaveBalance:
            LeaveBalanceView(state: .sample, onBack: router.back)
        case .offboardingNotEligible:
            OffboardingView(
                state: .notEligible,
                onBack: router.back,
                onNextStep: { router.navigate(.auth(.afterLeaving)) }
            )
        case .offboardingPension:
            OffboardingView(
                state: .dcPension,
                onBack: router.back,
                onNextStep: { router.navigate(.auth(.afterLeaving)) }
            )
        case .managerPermissions:
            ManagerPermissionsView(
                state: .sample,
                onBack: router.back,
                onSelectOwnerRole: { router.navigate(.employee(.ownerTransfer)) },
                onSave: { _, _ in router.back() }
            )
        case .employmentStatus:
            EmploymentStatusView(
                state: .sample,
                onBack: router.back,
                onConfirmLeave: { _ in router.navigate(.employee(.offboarding)) }
            )
        case .managerInvite:
            ManagerInviteView(
                state: .sample,
                onBack: router.back,
                onSend: { _, _, _, _, done in
                    done(true)
                    router.navigate(.employee(.managerInviteReceived))
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
                    router.navigate(.employee(.ownerTransfer))
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
                    router.navigate(.employee(.managerPermissions))
                }
            )
        case .ownerTransfer:
            OwnerTransferView(
                state: .sample,
                onBack: router.back,
                onSendWithVerification: { _, _, done in
                    done(true)
                    router.navigate(.employee(.ownerTransferReceived))
                }
            )
        case .employmentCertIssue:
            EmploymentCertIssueView(
                state: .sample,
                onBack: router.back,
                onDecline: router.back,
                onIssue: { _, done in
                    done(true)
                    router.navigate(.employee(.employmentCertIssued))
                }
            )
        case .staffAdd:
            StaffAddPreviewHost(state: .sample, onNext: { method in
                router.replace(with: method == .direct ? .employee(.directRegisterBasic) : .employee(.staffInvite))
            })
        case .directRegisterBasic:
            DirectRegisterBasicView(
                state: .sample,
                onBack: router.back,
                onNext: { _, done in
                    done()
                    router.navigate(.employee(.directRegisterTerms))
                }
            )
        case .directRegisterContract:
            DirectRegisterContractView(
                state: .sample,
                onBack: router.back,
                onRegister: { _, done in
                    done()
                    router.navigate(.employee(.appLessStaff))
                }
            )
        case .directRegisterTerms:
            DirectRegisterTermsView(
                state: .sample,
                onBack: router.back,
                onNext: { _, done in
                    done()
                    router.navigate(.employee(.directRegisterContract))
                }
            )
        case .appLessStaff:
            AppLessStaffView(
                state: .sample,
                sheet: .sample,
                onBack: router.back,
                onFixOtherDay: { router.navigate(.employee(.dayFix)) }, // 다른 날 고치기 → 20f(사용자 확인)
                onContract: { router.navigate(.employee(.contractList)) }, // 「계약서」 → 1ab
                onInvite: { router.navigate(.employee(.staffInvite)) },
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
                onFixOtherDay: { router.navigate(.employee(.dayFix)) }, // 다른 날 고치기 → 20f(사용자 확인)
                onContract: { router.navigate(.employee(.contractList)) }, // 「계약서」 → 1ab
                onInvite: { router.navigate(.employee(.staffInvite)) },
                onSave: { _, done in
                    done(true)
                    router.navigate(.payroll(.workClosingDirect))
                }
            )
        }
    }

    static let connected: Set<Self> = [
        .documentBox, .employmentCertRequest, .employmentCertIssued, .contractReview,
        .signaturePad, .contractList, .workTermsInput, .contractChange,
        .contractPreview, .wageChangeContract, .contractPDFViewer, .inviteAccept,
        .inviteCode, .inviteCodeRetry, .inviteExpired, .inviteSwitch,
        .inviteOffer, .inviteOfferUnverified, .inviteAfterSignup, .invitePhoneMismatch,
        .onboardingChecklist, .staffInvite, .staffList, .staffDetail,
        .offboarding, .leaveBalance, .offboardingNotEligible, .offboardingPension,
        .managerPermissions, .employmentStatus, .managerInvite, .managerInviteReceived,
        .ownerTransferReceived, .ownerTransfer, .employmentCertIssue, .staffAdd,
        .directRegisterBasic, .directRegisterContract, .directRegisterTerms, .appLessStaff,
        .dayFix,
    ]

}
