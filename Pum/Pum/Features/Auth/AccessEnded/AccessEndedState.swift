// UI-IOS-6s · REQ-095 — 만료 · 접근 종료 공통 틀 데이터
// 제목 · 안내 · 대상 카드 · 버튼 글자를 모두 값으로 받는다. 기간 · 날짜 · 이름은 서버 글자 그대로.
// 원문은 「만료된 초대」 하나뿐 — 삭제된 사업장 · 권한 없음 · 세션 만료 문구는 원문 없음(만들지 않았다).
import Foundation

nonisolated struct AccessEndedState: Equatable, Sendable {
    /// 카드의 라벨-값 행(보낸 날 · 만료 등)
    nonisolated struct Row: Equatable, Sendable {
        let label: String
        let value: String
        /// VoiceOver — 「보낸 날, 2026.10.01」
        var spokenText: String { "\(label), \(value)" }
    }

    /// 대상 카드 — 세션 만료처럼 대상이 없으면 상태의 card가 nil
    nonisolated struct Card: Equatable, Sendable {
        /// 타일 글자 — nil이면 이름 첫 글자
        let tileText: String?
        let name: String
        let subtitle: String
        let badgeText: String
        let rows: [Row]

        var initial: String { tileText ?? name.first.map(String.init) ?? "" }
        /// VoiceOver — 「종민김밥 본점, 박민수 사장님, 만료」
        var spokenText: String { "\(name), \(subtitle), \(badgeText)" }
    }

    let title: String
    let message: String
    let card: Card?
    let primaryTitle: String
    let secondaryTitle: String

    /// 원문(6s): 만료된 초대
    static let inviteExpired = AccessEndedState(
        title: "초대가 만료됐어요",
        message: "초대 링크는 보낸 날로부터 7일 동안만 쓸 수 있어요. 사장님께 새 초대를 요청해주세요.",
        card: Card(
            tileText: nil, name: "종민김밥 본점", subtitle: "박민수 사장님", badgeText: "만료",
            rows: [Row(label: "보낸 날", value: "2026.10.01"), Row(label: "만료", value: "2026.10.08")]),
        primaryTitle: "사장님께 새 초대 요청",
        secondaryTitle: "다른 코드 입력")
}
