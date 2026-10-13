// UI-IOS-6d · REQ-090 — 내 동의 내역 상태. 날짜 · 버전 · 범위 글자는 모두 서버 값(let), 화면이 만들지 않는다.
// 동의 내용은 개인정보 — print · 로그 금지.
import Foundation

/// 동의 한 줄. 필수는 › (토글 없음), 선택은 토글.
nonisolated struct ConsentRow: Identifiable, Equatable, Sendable {
    nonisolated enum Kind: Equatable, Sendable { case required, optional }

    let id: String
    let title: String
    let kind: Kind
    /// 「2026.10.03 동의 · v1.2」 · 「동의 안 함」 — 서버 값
    let detail: String
    /// 선택 동의의 현재 서버 값. 필수는 항상 true(화면에 쓰지 않음).
    let isOn: Bool

    var hasToggle: Bool { kind == .optional }
    var badgeText: String { kind == .required ? ConsentsState.requiredBadge : ConsentsState.optionalBadge }
    /// 「서비스 이용약관, 필수, 2026.10.03 동의 · v1.2」
    var spoken: String { "\(title), \(badgeText), \(detail)" }
}

/// 서버가 알려 주는 약관 변경 예정
nonisolated struct ConsentPendingChange: Equatable, Sendable {
    /// 「시행 2027.01.01」
    let effectiveText: String
    /// 「서비스 이용약관 v1.2 → v1.3」
    let summary: String

    var spoken: String { "\(ConsentsState.changeBadge), \(effectiveText), \(summary)" }
}

nonisolated struct ConsentsState: Equatable, Sendable {
    static let headerTitle = "내 동의 내역"
    static let changeBadge = "변경 예정"
    static let changeConfirm = "확인"
    static let requiredBadge = "필수"
    static let optionalBadge = "선택"
    static let thirdPartyHeader = "제3자 제공 · 사업장별"
    static let footnote = "필수 동의 철회는 해당 사업장 퇴사 또는 회원 탈퇴로 진행돼요."

    /// nil이면 변경 예정 카드를 그리지 않는다.
    let pendingChange: ConsentPendingChange?
    let consents: [ConsentRow]
    let thirdParties: [ConsentRow]

    static let sample = ConsentsState(
        pendingChange: ConsentPendingChange(effectiveText: "시행 2027.01.01", summary: "서비스 이용약관 v1.2 → v1.3"),
        consents: [
            ConsentRow(id: "terms", title: "서비스 이용약관", kind: .required, detail: "2026.10.03 동의 · v1.2", isOn: true),
            ConsentRow(id: "privacy", title: "개인정보 수집 · 이용", kind: .required, detail: "2026.10.03 동의 · v1.4", isOn: true),
            ConsentRow(id: "esign", title: "전자문서 · 전자서명", kind: .required, detail: "2026.10.03 동의 · v1.0", isOn: true),
            ConsentRow(id: "location", title: "위치정보 이용", kind: .optional, detail: "2026.10.05 동의 · v1.1 · 위치 출근", isOn: true),
            ConsentRow(id: "marketing", title: "마케팅 정보 수신", kind: .optional, detail: "동의 안 함", isOn: false),
        ],
        thirdParties: [
            ConsentRow(id: "wp1", title: "종민김밥 본점", kind: .required, detail: "2026.10.03 · 근무기록 · 계좌 · 서류", isOn: true),
            ConsentRow(id: "wp2", title: "B카페 서면점", kind: .required, detail: "2026.03.01 · 근무기록 · 계좌", isOn: true),
            ConsentRow(id: "wp3", title: "C학원", kind: .required, detail: "2026.09.01 · 근무기록 · 계좌", isOn: true),
        ]
    )
}
