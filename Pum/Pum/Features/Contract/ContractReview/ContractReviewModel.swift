// UI-IOS-1z · REQ-060 · REQ-028 — 근로계약서 확인 화면 데이터
// 계약 조건 값은 서버가 준 문구 그대로 보여 준다(화면에서 계산 · 조합하지 않는다). 「주 13.5시간」도 받은 값.
import SwiftUI

nonisolated struct ContractTerm: Equatable, Sendable, Identifiable {
    /// 서버 순서 번호
    let order: Int
    let label: String        // 「근무일·시간」
    let value: String        // 「월·수·금 17:00 – 22:00」
    /// 값 아래 오른쪽 정렬 보조 줄(예: 「휴게 30분 · 주 13.5시간」). 없으면 nil.
    var subline: String? = nil
    /// 값 바로 뒤 같은 줄 덧붙임(예: 「 · 주휴수당 별도」, 12px 400 보조색). 없으면 nil.
    var suffix: String? = nil
    var id: Int { order }

    /// 「근무일·시간, 월·수·금 17:00부터 22:00, 휴게 30분, 주 13.5시간」 — 낭독용(범위 대시 → 「부터」, 가운뎃점 구분 → 쉼표)
    var accessibilityText: String {
        var parts = [label, value.replacingOccurrences(of: " – ", with: "부터 ")]
        if let subline { parts.append(subline.replacingOccurrences(of: " · ", with: ", ")) }
        if let suffix { parts.append(suffix.replacingOccurrences(of: "·", with: "").trimmingCharacters(in: .whitespaces)) }
        return parts.joined(separator: ", ")
    }
}

nonisolated struct ContractReviewRecord: Equatable, Sendable {
    var docTitle: String         // 「표준근로계약서」
    var statusText: String       // 「서명 대기」
    var kindText: String         // 「단시간근로자용」
    var workplaceName: String
    var ownerName: String        // 사장님 호칭은 화면이 붙임
    var sentDateText: String     // 「10월 1일」(서버 문구)
    var terms: [ContractTerm]
    var fullTextTitle: String    // 「계약서 전문 보기」
    var fullTextDetail: String   // 「3쪽 · 근로기준법 제17조 기재사항 포함」
    var consentText: String

    /// 「종민김밥 본점 · 박민수 사장님이 보냄 · 10월 1일」
    var subtitleText: String { "\(workplaceName) · \(ownerName) 사장님이 보냄 · \(sentDateText)" }

    /// 서명하기는 동의 체크 후에만 활성(REQ-060). 서명 전에도 출퇴근은 막지 않는다(REQ-028) — 이 화면과 무관.
    static func canSign(agreed: Bool) -> Bool { agreed }

    static let sample = ContractReviewRecord(
        docTitle: "표준근로계약서", statusText: "서명 대기", kindText: "단시간근로자용",
        workplaceName: "종민김밥 본점", ownerName: "박민수", sentDateText: "10월 1일",
        terms: [
            .init(order: 1, label: "계약 기간", value: "2026.10.05 – 2027.04.04"),
            .init(order: 2, label: "근무 장소", value: "종민김밥 본점"),
            .init(order: 3, label: "업무 내용", value: "홀 서빙·마감"),
            .init(order: 4, label: "근무일·시간", value: "월·수·금 17:00 – 22:00", subline: "휴게 30분 · 주 13.5시간"),
            .init(order: 5, label: "시급", value: "12,000원", suffix: " · 주휴수당 별도"),
            .init(order: 6, label: "임금 지급일", value: "매월 10일 · 계좌이체"),
            .init(order: 7, label: "4대보험", value: "고용·산재 가입"),
        ],
        fullTextTitle: "계약서 전문 보기", fullTextDetail: "3쪽 · 근로기준법 제17조 기재사항 포함",
        consentText: "계약 조건을 모두 확인했고, 전자서명이 서면 서명과 같은 효력을 가진다는 점에 동의합니다.")
}
