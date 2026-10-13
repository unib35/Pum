// UI-IOS-19f · REQ-062 — 직원 · 발급된 재직증명서.
// 문서 내용 · 확인 번호는 서버 값 그대로(let). 생년월일은 서버가 가린 문자열, 사업자번호는 문자열 그대로.
// 복사 뒤 안내 문구는 원문 없음 — 화면은 클로저만 부른다.
import Foundation

nonisolated struct EmploymentCertIssuedState: Equatable, Sendable {
    static let backTitle = "문서함"
    static let issuedTitle = "발급됨"
    static let documentTitle = "재직증명서"
    static let nameLabel = "성명"
    static let birthLabel = "생년월일"
    static let workplaceLabel = "근무지"
    static let periodLabel = "재직 기간"
    static let dutyLabel = "업무"
    static let purposeLabel = "용도"
    static let shopNameLabel = "상호"
    static let businessNumberLabel = "사업자번호"
    static let ownerLabel = "대표자"
    static let addressLabel = "소재지"
    static let attestation = "위와 같이 재직하고 있음을 증명합니다."
    static let signatureChip = "사업주 서명"
    static let verifyHint = "받는 곳에서 pum.kr/v 에 넣으면 확인돼요"
    static let codeTitle = "확인 번호"
    static let copyTitle = "복사"
    static let shareTitle = "공유"
    static let savePDFTitle = "PDF 저장"

    /// 「김하늘」
    let staffName: String
    /// 「10월 7일 10:05」
    let issuedAtText: String
    /// 「금융기관 제출용」
    let usageText: String
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
    /// 「종민김밥 본점」
    let shopNameText: String
    /// 「123-45-67890」
    let businessNumberText: String
    /// 「박민수」
    let ownerName: String
    /// 「대구 수성구 들안로 12」
    let addressText: String
    /// 「2026년 10월 7일」
    let issueDateText: String
    /// 「7K4X-92MD」
    let verifyCode: String

    /// 「10월 7일 10:05 · 금융기관 제출용」
    var issuedLineText: String { "\(issuedAtText) · \(usageText)" }
    /// 「발급됨, 10월 7일 10:05 · 금융기관 제출용」
    var issuedSpoken: String { "\(Self.issuedTitle), \(issuedLineText)" }
    /// 「확인 번호 7K4X-92MD」
    var codeText: String { "\(Self.codeTitle) \(verifyCode)" }
    /// 「확인 번호, 7K4X-92MD」
    var codeSpoken: String { "\(Self.codeTitle), \(verifyCode)" }
    /// 「확인 번호, 7K4X-92MD, 받는 곳에서 …」 — 카드 한 덩어리 읽기
    var codeCardSpoken: String { "\(codeSpoken), \(Self.verifyHint)" }
    /// 「2026년 10월 7일 · 대표 박민수」 — 뒤에 「사업주 서명」 칩
    var signLineText: String { "\(issueDateText) · 대표 \(ownerName)" }
    /// 「위와 같이 … 증명합니다. 2026년 10월 7일 · 대표 박민수 사업주 서명」
    var closingSpoken: String { "\(Self.attestation) \(signLineText) \(Self.signatureChip)" }

    /// 사람 표 — (이름, 값) 순서 그대로
    var personRows: [EmploymentCertIssuedRow] {
        [EmploymentCertIssuedRow(label: Self.nameLabel, value: staffName),
         EmploymentCertIssuedRow(label: Self.birthLabel, value: birthText),
         EmploymentCertIssuedRow(label: Self.workplaceLabel, value: workplaceText),
         EmploymentCertIssuedRow(label: Self.periodLabel, value: periodText),
         EmploymentCertIssuedRow(label: Self.dutyLabel, value: dutyText),
         EmploymentCertIssuedRow(label: Self.purposeLabel, value: purposeText)]
    }

    /// 사업장 표
    var shopRows: [EmploymentCertIssuedRow] {
        [EmploymentCertIssuedRow(label: Self.shopNameLabel, value: shopNameText),
         EmploymentCertIssuedRow(label: Self.businessNumberLabel, value: businessNumberText),
         EmploymentCertIssuedRow(label: Self.ownerLabel, value: ownerName),
         EmploymentCertIssuedRow(label: Self.addressLabel, value: addressText)]
    }

    /// 원문 캡처 값
    static let sample = EmploymentCertIssuedState(
        staffName: "김하늘", issuedAtText: "10월 7일 10:05", usageText: "금융기관 제출용",
        birthText: "2003.05.**", workplaceText: "종민김밥 본점", periodText: "2026.3.9 – 현재",
        dutyText: "홀 서빙", purposeText: "금융기관 제출", shopNameText: "종민김밥 본점",
        businessNumberText: "123-45-67890", ownerName: "박민수", addressText: "대구 수성구 들안로 12",
        issueDateText: "2026년 10월 7일", verifyCode: "7K4X-92MD")
}

nonisolated struct EmploymentCertIssuedRow: Equatable, Sendable {
    let label: String
    let value: String
    /// 「상호, 종민김밥 본점」
    var spoken: String { "\(label), \(value)" }
}
