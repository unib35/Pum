// UI-IOS-5e · REQ-011 — 관리 권한 확인 화면 데이터
// 이름 · 일치 여부 · 영업 상태 · 권한 값은 서버 값 그대로(화면에서 비교하거나 만들지 않는다).
import Foundation

nonisolated enum AuthorityChoice: Equatable, Sendable {
    case representative // 제가 대표자예요
    case delegate       // 대표자에게 위임받은 관리자예요
}

nonisolated struct AuthorityVerifyState: Equatable, Sendable {
    var choice: AuthorityChoice
    var signupName: String         // 가입한 이름 — 「박민수」
    var representativeName: String // 사업자 대표자명 — 「박민수」
    /// 서버가 비교한 결과. 다르면 첫 카드 첫 문장은 숨긴다(다를 때 문구는 디자인에 없음).
    var namesMatch: Bool
    var businessStatus: String     // 「영업 중」
    var authorityLabel: String     // 「대표자」 — 위임 선택 시 값은 디자인에 없어 서버가 준 값
    var isSubmitting = false

    static let sample = AuthorityVerifyState(
        choice: .representative, signupName: "박민수", representativeName: "박민수",
        namesMatch: true, businessStatus: "영업 중", authorityLabel: "대표자")

    static let representativeTitle = "제가 대표자예요"
    static let delegateTitle = "대표자에게 위임받은 관리자예요"
    static let delegateDetail = "대표자 휴대폰으로 승인 링크를 보내요. 대표자가 승인하면 관리자 권한이 부여돼요."
    static let representativeTail = "휴대폰 본인확인으로 바로 완료돼요."
    static let previewBadge = "인증된 사업장"
    static let previewLead = "완료되면 이렇게 표시돼요"
    static let noteBold = "이체"

    /// 첫 카드 설명(굵기 없는 글자). 일치하지 않으면 첫 문장을 뺀다.
    var representativeDetailPlain: String {
        namesMatch
            ? "가입한 이름 \(signupName)와 사업자 대표자명 \(representativeName)가 일치해요. \(Self.representativeTail)"
            : Self.representativeTail
    }

    var noteText: String {
        "직원 초대·근로계약·급여 확정이 열려요. 급여 \(Self.noteBold)는 금융 파트너 요건에 따라 추가 확인이 있을 수 있어요."
    }

    var previewAccessibilityText: String {
        "완료되면, 본인 \(signupName) 확인, 사업자 \(businessStatus), 권한 \(authorityLabel)"
    }

    var canSubmit: Bool { !isSubmitting }
}
