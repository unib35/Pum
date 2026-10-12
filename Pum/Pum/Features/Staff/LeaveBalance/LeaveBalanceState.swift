// UI-IOS-10q · REQ-073 — 사장님 · 직원별 연차 현황 (하위 화면, 탭 바 없음)
// 남은 · 생김 · 씀 · 발생 예정 · 대상 여부 · 이유 · 계산식 설명 · 금액은 서버(엔진) 값 그대로.
// 화면에서 남은 연차(생김 − 씀)나 발생량을 계산하지 않는다. 시간 · 금액은 서버가 만든 문자열.
import Foundation

/// 직원 한 명의 연차 요약 행
nonisolated struct LeaveBalanceStaff: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    /// 아바타 색 순환 번호(사람 ID 고정 키)
    var colorIndex: Int
    /// 「주 20시간 · 2년 7개월」 — 대상 아님이면 이유(「주 12시간 · 15시간 미만」)
    var descriptionText: String
    /// 대상 여부(서버 값). false면 값 대신 「대상 아님」 배지
    var isEligible: Bool
    /// 「36시간」(대상일 때)
    var remainingText: String
    /// 「60시간 중 24시간 씀」 또는 「11월 6일 +3.6시간」(대상일 때, 서버 문구)
    var usageText: String

    var spoken: String {
        isEligible
            ? "\(name), \(descriptionText), 남은 연차 \(remainingText), \(usageText)"
            : "\(name), \(descriptionText), 대상 아님"
    }
}

/// 연차 내역 한 행(서버 값). 오른쪽 값은 굵게, isAmount이면 초록
nonisolated struct LeaveBalanceEntry: Equatable, Sendable, Identifiable {
    nonisolated enum Kind: Equatable, Sendable {
        case plain      // 생김 · 수당 등 읽기 행
        case usage      // 사용 내역으로 이동(›)
    }
    var id: String
    var title: String
    /// 계산식 · 설명(서버 값). 없으면 한 줄
    var detail: String?
    var valueText: String
    var kind: Kind = .plain
    /// 금액(미사용 연차 수당) — 초록
    var isAmount: Bool = false

    var spoken: String {
        [title, detail, valueText].compactMap { $0 }.joined(separator: ", ")
    }
}

nonisolated struct LeaveBalanceState: Equatable, Sendable {
    static let screenTitle = "연차 현황"
    static let remainingCaption = "남은 연차"
    static let notEligibleText = "대상 아님"

    /// 「2026년 · 입사일 기준」
    var headingText: String
    var staff: [LeaveBalanceStaff]
    /// 기본 선택 직원(서버 값)
    var selectedId: String?
    /// 직원 ID별 내역(서버가 직원별로 준다). 없으면 섹션 숨김
    var entriesByStaff: [String: [LeaveBalanceEntry]]

    func staffMember(id: String?) -> LeaveBalanceStaff? { staff.first { $0.id == id } }
    func entries(for id: String?) -> [LeaveBalanceEntry] { id.flatMap { entriesByStaff[$0] } ?? [] }
    /// 「박서준 · 연차 내역」
    func sectionTitle(for name: String) -> String { "\(name) \u{00B7} 연차 내역" }

    /// 원문 값(박서준 선택)
    static let sample = LeaveBalanceState(
        headingText: "2026년 \u{00B7} 입사일 기준",
        staff: [
            .init(id: "jongmin", name: "이종민", colorIndex: 0,
                  descriptionText: "주 20시간 \u{00B7} 2년 7개월", isEligible: true,
                  remainingText: "36시간", usageText: "60시간 중 24시간 씀"),
            .init(id: "seojun", name: "박서준", colorIndex: 3,
                  descriptionText: "주 18시간 \u{00B7} 10월 31일 퇴사", isEligible: true,
                  remainingText: "8시간", usageText: "54시간 중 46시간 씀"),
            .init(id: "haneul", name: "김하늘", colorIndex: 1,
                  descriptionText: "주 18시간 \u{00B7} 1년 미만", isEligible: true,
                  remainingText: "0시간", usageText: "11월 6일 +3.6시간"),
            .init(id: "yuna", name: "최유나", colorIndex: 2,
                  descriptionText: "주 12시간 \u{00B7} 15시간 미만", isEligible: false,
                  remainingText: "", usageText: ""),
        ],
        selectedId: "seojun",
        entriesByStaff: [
            "seojun": [
                .init(id: "accrual", title: "8월 18일 \u{00B7} 2년차 연차 생김",
                      detail: "15일 \u{00D7} 18/40 \u{00D7} 8시간", valueText: "+54시간"),
                .init(id: "usage", title: "휴무 요청으로 사용 \u{00B7} 10회",
                      detail: nil, valueText: "\u{2212}46시간", kind: .usage),
                .init(id: "payout", title: "10월 31일 퇴사 \u{00B7} 남은 8시간",
                      detail: "미사용 연차 수당 \u{00B7} 퇴사 정산으로", valueText: "88,000원", isAmount: true),
            ],
        ]
    )
}
