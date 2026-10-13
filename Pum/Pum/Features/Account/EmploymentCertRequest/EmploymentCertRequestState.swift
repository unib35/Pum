// UI-IOS-19d · REQ-062 — 직원 · 재직증명서 요청. 들어가는 내용은 서버 값(화면이 정하지 않음).
// 생년월일 · 주소는 넣을지 고르기만 하고 실제 값은 이 화면에 없다. 토글 · 용도는 화면 초안.
import Foundation

nonisolated enum EmploymentCertPurpose: String, CaseIterable, Identifiable, Equatable, Sendable {
    case financial, government, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .financial: "금융기관"
        case .government: "관공서"
        case .other: "기타"
        }
    }
}

/// 화면 초안 — 서버 초기값에서 시작
nonisolated struct EmploymentCertRequestDraft: Equatable, Sendable {
    var includesBirthDate: Bool
    var includesAddress: Bool
    var purpose: EmploymentCertPurpose
}

/// 사장님께 보낼 값
nonisolated struct EmploymentCertRequestValue: Equatable, Sendable {
    let includesBirthDate: Bool
    let includesAddress: Bool
    let purpose: EmploymentCertPurpose
}

/// 들어가는 내용 한 줄 — 서버 값
nonisolated struct EmploymentCertRequestInfoRow: Identifiable, Equatable, Sendable {
    let title: String
    let value: String
    var id: String { title }
}

nonisolated struct EmploymentCertRequestState: Equatable, Sendable {
    static let backTitle = "문서함"
    static let title = "재직증명서 요청"
    static let contentHeader = "들어가는 내용"
    static let chooseHeader = "넣을지 고르기"
    static let birthDateTitle = "생년월일"
    static let addressTitle = "주소"
    static let purposeHeader = "용도"
    static let sendTitle = "사장님께 요청"
    static let sendingTitle = "보내는 중"
    static let footerNotice = "발급되면 알림 · 문서함에 보관돼요"

    /// 이름 · 근무지 · 재직 기간 · 업무
    let rows: [EmploymentCertRequestInfoRow]
    let initialDraft: EmploymentCertRequestDraft

    func value(_ draft: EmploymentCertRequestDraft) -> EmploymentCertRequestValue {
        EmploymentCertRequestValue(includesBirthDate: draft.includesBirthDate,
                                   includesAddress: draft.includesAddress,
                                   purpose: draft.purpose)
    }

    /// 읽기 문구 — 「생년월일, 켬」
    func toggleReadout(_ title: String, isOn: Bool) -> String { "\(title), \(isOn ? "켬" : "끔")" }
    /// 읽기 문구 — 「금융기관, 선택됨」
    func purposeReadout(_ purpose: EmploymentCertPurpose, draft: EmploymentCertRequestDraft) -> String {
        draft.purpose == purpose ? "\(purpose.title), 선택됨" : purpose.title
    }
    func infoReadout(_ row: EmploymentCertRequestInfoRow) -> String { "\(row.title), \(row.value)" }

    static let sample = EmploymentCertRequestState(
        rows: [
            .init(title: "이름", value: "김하늘"),
            .init(title: "근무지", value: "종민김밥 본점"),
            .init(title: "재직 기간", value: "2026.3.9 – 현재"),
            .init(title: "업무", value: "홀 서빙"),
        ],
        initialDraft: .init(includesBirthDate: true, includesAddress: false, purpose: .financial))
}
