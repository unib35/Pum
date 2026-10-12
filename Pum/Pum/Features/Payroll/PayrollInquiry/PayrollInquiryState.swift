// UI-IOS-6n · REQ-096 — 급여 계산 문의: 관련 데이터를 붙여서 보내기(직원).
// 사업장 · 기간 · 명세서 금액 · 근거 건수는 서버가 준 문구 그대로(화면이 금액을 계산하지 않음).
// 항목 · 내용 · 근거 첨부 · 받는 곳은 보내기 전 초안(Draft). 내용은 개인정보라 로그에 남기지 않는다.
import Foundation

nonisolated enum InquiryItem: String, CaseIterable, Identifiable, Equatable, Sendable {
    case workHours, basePay, weeklyHoliday, overtime, deduction

    var id: String { rawValue }
    var title: String {
        switch self {
        case .workHours: "근무시간"
        case .basePay: "기본급"
        case .weeklyHoliday: "주휴수당"
        case .overtime: "연장수당"
        case .deduction: "공제"
        }
    }
}

nonisolated enum InquiryRecipient: String, CaseIterable, Identifiable, Equatable, Sendable {
    case owner, support

    var id: String { rawValue }
    var title: String {
        switch self {
        case .owner: "사장님께 문의"
        case .support: "고객센터에 문의"
        }
    }
    var detail: String {
        switch self {
        case .owner: "근무 인정 · 급여 기준 관련"
        case .support: "앱 계산 오류가 의심될 때"
        }
    }
}

nonisolated struct PayrollInquiryDraft: Equatable, Sendable {
    var item: InquiryItem
    var body: String
    var attachesEvidence: Bool
    var recipient: InquiryRecipient
}

/// 요약 카드 한 줄 — 왼쪽 라벨 · 오른쪽 값(둘 다 서버 값)
nonisolated struct InquirySummaryRow: Identifiable, Equatable, Sendable {
    let label: String
    let value: String
    var id: String { label }
}

nonisolated struct PayrollInquirySubmission: Equatable, Sendable {
    let item: InquiryItem
    let body: String
    let attachesEvidence: Bool
    let recipient: InquiryRecipient
}

nonisolated struct PayrollInquiryState: Equatable, Sendable {
    static let headerTitle = "급여 문의"
    static let titleLines = ["급여 계산에", "문제가 있나요?"]
    static let itemHeader = "문제가 있는 항목"
    static let evidenceTitle = "계산 근거 함께 보내기"
    static let sendTitle = "문의 보내기"
    /// 내용이 비었을 때 입력칸 자리 글자 — 원문 없음(임의 문구)
    static let placeholder = "어떤 점이 이상한지 적어 주세요."

    let workplace: String
    /// 「2026년 10월」
    let period: String
    /// 「1,188,000원」 — 서버 값
    let payslipAmount: String
    /// 「10월 근무기록 17건 · 주휴 계산 과정」
    let evidenceDetail: String
    let initialItem: InquiryItem
    let initialBody: String
    let initialAttachesEvidence: Bool
    let initialRecipient: InquiryRecipient

    var initialDraft: PayrollInquiryDraft {
        PayrollInquiryDraft(item: initialItem, body: initialBody,
                            attachesEvidence: initialAttachesEvidence, recipient: initialRecipient)
    }

    var rows: [InquirySummaryRow] {
        [InquirySummaryRow(label: "사업장", value: workplace),
         InquirySummaryRow(label: "기간", value: period),
         InquirySummaryRow(label: "명세서 금액", value: payslipAmount)]
    }

    var summarySpoken: String { rows.map { "\($0.label) \($0.value)" }.joined(separator: ", ") }
    var evidenceSpoken: String { "\(Self.evidenceTitle), \(evidenceDetail)" }

    /// 내용이 공백뿐이면 보낼 수 없다(원문엔 비활성 표시가 없어 정한 규칙)
    func canSend(_ draft: PayrollInquiryDraft) -> Bool {
        !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 보낼 내용 — 앞뒤 공백 정리
    func submission(_ draft: PayrollInquiryDraft) -> PayrollInquirySubmission {
        PayrollInquirySubmission(item: draft.item,
                                 body: draft.body.trimmingCharacters(in: .whitespacesAndNewlines),
                                 attachesEvidence: draft.attachesEvidence,
                                 recipient: draft.recipient)
    }

    /// 서버 값이 새로 올 때 편집 중인 초안을 지우지 않기 위한 판정
    func hasChanges(_ draft: PayrollInquiryDraft) -> Bool { draft != initialDraft }

    static let sample = PayrollInquiryState(
        workplace: "종민김밥 본점",
        period: "2026년 10월",
        payslipAmount: "1,188,000원",
        evidenceDetail: "10월 근무기록 17건 · 주휴 계산 과정",
        initialItem: .weeklyHoliday,
        initialBody: "10월 넷째 주에 15시간 넘게 일했는데 주휴수당이 빠진 것 같아요.",
        initialAttachesEvidence: true,
        initialRecipient: .owner
    )
}
