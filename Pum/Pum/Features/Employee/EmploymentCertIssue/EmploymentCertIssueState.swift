// UI-IOS-19e · REQ-062 — 사장님 · 재직증명서 요청 확인 · 발급.
// 문서 내용 · 등록된 서명 정보는 서버 값 그대로(let). 생년월일은 서버가 가린 문자열을 그대로 보여 준다.
// 「다음부터 바로 발급」은 REQ-062에서 미정 — 화면은 값만 넘기고 동작을 정하지 않는다.
import Foundation

nonisolated struct EmploymentCertIssueState: Equatable, Sendable {
    static let backTitle = "요청"
    static let needsDecisionTitle = "결정 필요"
    static let headerTitle = "재직증명서 요청"
    static let documentTitle = "재직증명서"
    static let nameLabel = "성명"
    static let birthLabel = "생년월일"
    static let workplaceLabel = "근무지"
    static let periodLabel = "재직 기간"
    static let dutyLabel = "업무"
    static let purposeLabel = "용도"
    static let attestation = "위와 같이 재직하고 있음을 증명합니다."
    static let signatureChip = "사업주 서명"
    static let useSignatureTitle = "등록된 사업주 서명으로 발급"
    static let issueNextTimeTitle = "다음부터 바로 발급"
    static let issueNextTimeSubtitle = "기본 항목 · 용도만 다를 때"
    static let declineTitle = "거절"
    static let issueTitle = "발급하기"

    /// 「김하늘」
    let staffName: String
    /// 「오늘 09:12」
    let sentText: String
    /// 서버가 가린 문자열 「2003.05.**」
    let birthText: String
    /// 「종민김밥 본점」
    let workplaceText: String
    /// 「2026.3.9 – 현재」
    let periodText: String
    /// 「홀 서빙」
    let dutyText: String
    /// 「금융기관 제출」
    let purposeText: String
    /// 「2026년 10월 7일」
    let issueDateText: String
    /// 「박민수」
    let ownerName: String
    /// 「2026.3」 — 서명 등록 연월
    let signatureRegisteredText: String
    /// 서버 초기값 — 등록된 서명으로 발급
    let useRegisteredSignature: Bool
    /// 서버 초기값 — 다음부터 바로 발급
    let issueNextTime: Bool

    /// 「김하늘 · 오늘 09:12」
    var senderText: String { "\(staffName) · \(sentText)" }
    /// 「결정 필요, 김하늘, 오늘 09:12」
    var senderSpoken: String { "\(Self.needsDecisionTitle), \(staffName), \(sentText)" }
    /// 「박민수 · 2026.3 등록」
    var signatureSubtitle: String { "\(ownerName) · \(signatureRegisteredText) 등록" }
    /// 「2026년 10월 7일 · 대표 박민수」 — 뒤에 「사업주 서명」 칩
    var signLineText: String { "\(issueDateText) · 대표 \(ownerName)" }
    /// 「김하늘님 문서함으로 · 활동 기록에 남아요」
    var footerNotice: String { "\(staffName)님 문서함으로 · 활동 기록에 남아요" }

    /// 문서 표 — (이름, 값) 순서 그대로
    var rows: [EmploymentCertIssueRow] {
        [EmploymentCertIssueRow(label: Self.nameLabel, value: staffName),
         EmploymentCertIssueRow(label: Self.birthLabel, value: birthText),
         EmploymentCertIssueRow(label: Self.workplaceLabel, value: workplaceText),
         EmploymentCertIssueRow(label: Self.periodLabel, value: periodText),
         EmploymentCertIssueRow(label: Self.dutyLabel, value: dutyText),
         EmploymentCertIssueRow(label: Self.purposeLabel, value: purposeText)]
    }

    /// 「위와 같이 … 증명합니다. 2026년 10월 7일 · 대표 박민수 사업주 서명」
    var closingSpoken: String { "\(Self.attestation) \(signLineText) \(Self.signatureChip)" }
    /// 「등록된 사업주 서명으로 발급, 박민수 · 2026.3 등록, 선택됨」
    func signatureSpoken(isOn: Bool) -> String {
        "\(Self.useSignatureTitle), \(signatureSubtitle), \(isOn ? "선택됨" : "선택 안 됨")"
    }
    func issueNextTimeSpoken(isOn: Bool) -> String {
        "\(Self.issueNextTimeTitle), \(Self.issueNextTimeSubtitle), \(isOn ? "선택됨" : "선택 안 됨")"
    }

    /// 발급 가능 조건 — 등록된 서명을 끄면 비활성(원문 없음, 안내 문구 없이 비활성만)
    static func canIssue(useRegisteredSignature: Bool) -> Bool { useRegisteredSignature }

    /// 원문 캡처 값
    static let sample = EmploymentCertIssueState(
        staffName: "김하늘", sentText: "오늘 09:12", birthText: "2003.05.**",
        workplaceText: "종민김밥 본점", periodText: "2026.3.9 – 현재", dutyText: "홀 서빙",
        purposeText: "금융기관 제출", issueDateText: "2026년 10월 7일", ownerName: "박민수",
        signatureRegisteredText: "2026.3", useRegisteredSignature: true, issueNextTime: false)
}

nonisolated struct EmploymentCertIssueRow: Equatable, Sendable {
    let label: String
    let value: String
    /// 「성명, 김하늘」
    var spoken: String { "\(label), \(value)" }
}

/// 발급하기로 보내는 선택 값
nonisolated struct EmploymentCertIssueChoice: Equatable, Sendable {
    let useRegisteredSignature: Bool
    let issueNextTime: Bool
}
