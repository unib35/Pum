// UI-IOS-10n · REQ-080 — 사장님 · 퇴사 정산 (하위 화면, 탭 바 없음)
// 금액(「약」 포함) · 기한 · 대상 여부 · 설명 · 단계 · 완료 여부 · 버튼 문구는 서버(엔진) 값 그대로.
// 화면에서 퇴직금 · 연차수당을 계산하거나 기한 날짜를 만들지 않는다.
// 퇴직금 「대상 아님」(10r) · DC형(10s)은 다른 화면 — 여기서는 설명 · 금액 문자열을 서버가 주는 구조로만 받는다.
import Foundation

/// 지급할 것 한 행. 금액은 서버가 만든 문자열(「약 1,790,000원」)
nonisolated struct OffboardingPayItem: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var amountText: String

    var spoken: String { "\(title), \(detail), \(amountText)" }
}

/// 처리 순서 한 단계. detail이 없으면 한 줄. isDone은 서버 값
nonisolated struct OffboardingStep: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String?
    var isDone: Bool
}

nonisolated struct OffboardingState: Equatable, Sendable {
    static let screenTitle = "퇴사 정산"
    static let payTitle = "지급할 것 · 예상"
    static let stepsTitle = "처리 순서"

    var name: String
    var colorIndex: Int
    /// 「2025.8.18 입사 · 10월 31일 퇴사」
    var periodText: String
    /// 「퇴사 예정」
    var statusText: String
    /// 「지급 기한 11월 14일」
    var deadlineText: String
    /// 「퇴사 후 14일 안」
    var deadlineNote: String
    var payItems: [OffboardingPayItem]
    var steps: [OffboardingStep]
    /// 다음 할 일 버튼 문구(서버 값)
    var nextStepTitle: String

    var deadlineSpoken: String { "\(deadlineText), \(deadlineNote)" }
    var headerSpoken: String { "\(name), \(periodText), \(statusText)" }

    func stepSpoken(_ step: OffboardingStep) -> String {
        guard let i = steps.firstIndex(where: { $0.id == step.id }) else { return step.title }
        let parts = [step.title, step.detail, step.isDone ? "완료" : "아직"].compactMap { $0 }
        return parts.joined(separator: ", ") + ", \(steps.count)단계 중 \(i + 1)번째"
    }

    /// 원문 값(지급 대상)
    static let sample = OffboardingState(
        name: "박서준", colorIndex: 3,
        periodText: "2025.8.18 입사 \u{00B7} 10월 31일 퇴사",
        statusText: "퇴사 예정",
        deadlineText: "지급 기한 11월 14일",
        deadlineNote: "퇴사 후 14일 안",
        payItems: [
            OffboardingPayItem(id: "salary", title: "10월 급여", detail: "근무 마감 후 확정", amountText: "880,000원"),
            OffboardingPayItem(id: "severance", title: "퇴직금", detail: "1년 2개월 \u{00B7} 주 18시간 \u{00B7} 지급 대상", amountText: "약 1,790,000원"),
            OffboardingPayItem(id: "leave", title: "미사용 연차 수당", detail: "남은 8시간 \u{00D7} 11,000", amountText: "88,000원"),
        ],
        steps: [
            OffboardingStep(id: "date", title: "퇴사일 확정", detail: "10월 31일 \u{00B7} 사직서 받음", isDone: true),
            OffboardingStep(id: "close", title: "10월 근무 마감", detail: nil, isDone: false),
            OffboardingStep(id: "final", title: "최종 급여 \u{00B7} 퇴직금 확정", detail: nil, isDone: false),
            OffboardingStep(id: "pay", title: "지급 \u{00B7} 명세서 발행", detail: nil, isDone: false),
            OffboardingStep(id: "insurance", title: "4대보험 상실 신고", detail: "직접 신고 \u{00B7} 11월 15일까지", isDone: false),
        ],
        nextStepTitle: "10월 근무 마감하기")
}
