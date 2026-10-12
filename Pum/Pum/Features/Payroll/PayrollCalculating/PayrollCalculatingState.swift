// UI-IOS-21l · REQ-070 · REQ-095 — 급여 계산 중(사장님) 화면 데이터
// 끝난 수 · 전체 수 · 금액은 서버가 준 값 그대로. 화면에서 금액을 계산하지 않는다(막대는 두 정수 비율만 그린다).
import Foundation

nonisolated struct PayrollCalculatingRow: Equatable, Sendable, Identifiable {
    nonisolated enum Status: Equatable, Sendable { case done, calculating, waiting }

    let id: Int
    let name: String
    /// 아바타 색 순환 번호(사람 고정 키)
    let colorIndex: Int
    let status: Status
    /// 서버가 준 실지급액(정수 원) — 끝난 사람만 값이 있다
    let amountWon: Int?

    /// 금액은 끝난 행만 보인다
    var amountText: String? {
        guard status == .done, let amountWon else { return nil }
        return "\(PumFormat.amount(amountWon))원"
    }

    var detailText: String? {
        switch status {
        case .done: nil
        case .calculating: "계산 중"
        case .waiting: "기다리는 중"
        }
    }

    var accessibilityText: String {
        switch status {
        case .done: amountText.map { "\(name), 완료, \($0)" } ?? "\(name), 완료"
        case .calculating: "\(name), 계산 중"
        case .waiting: "\(name), 기다리는 중"
        }
    }
}

nonisolated struct PayrollCalculatingState: Equatable, Sendable {
    let periodText: String      // 서버가 준 「9월분 · 근무 마감 10월 7일」
    let doneCount: Int          // 서버가 준 끝난 수
    let totalCount: Int         // 서버가 준 전체 수
    let rows: [PayrollCalculatingRow]   // 서버가 준 순서(끝난 순서)

    static let backTitle = "급여"
    static let title = "급여 계산 중"
    static let buttonTitle = "계산 중"

    var progressText: String { "\(doneCount) / \(totalCount)명 \u{00B7} 화면을 나가도 계속 계산해요" }
    var progressAccessibilityText: String { "\(totalCount)명 중 \(doneCount)명 계산 끝" }

    /// 막대 비율 — 서버가 준 두 정수의 비율만. 전체가 0이면 0
    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return min(max(Double(doneCount) / Double(totalCount), 0), 1)
    }

    /// 원문 캡처 값. 아바타 색: 하=자두 · 서=남색 · 종=블루 · 유=호박 · 세=초록 · 다=연보라(팔레트에 없어 남색에 가장 가깝게)
    static let sample = PayrollCalculatingState(
        periodText: "9월분 \u{00B7} 근무 마감 10월 7일",
        doneCount: 3,
        totalCount: 6,
        rows: [
            .init(id: 1, name: "김하늘", colorIndex: 1, status: .done, amountWon: 1_062_000),
            .init(id: 2, name: "박서준", colorIndex: 3, status: .done, amountWon: 880_000),
            .init(id: 3, name: "이종민", colorIndex: 0, status: .done, amountWon: 1_118_610),
            .init(id: 4, name: "최유나", colorIndex: 2, status: .calculating, amountWon: nil),
            .init(id: 5, name: "오세진", colorIndex: 4, status: .waiting, amountWon: nil),
            .init(id: 6, name: "정다은", colorIndex: 3, status: .waiting, amountWon: nil),
        ]
    )
}
