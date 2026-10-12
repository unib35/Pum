// UI-IOS-10n · REQ-080 — 사장님 · 퇴사 정산 (하위 화면, 탭 바 없음)
// 금액(「약」 포함) · 기한 · 대상 여부 · 설명 · 단계 · 완료 여부 · 버튼 문구는 서버(엔진) 값 그대로.
// 화면에서 퇴직금 · 연차수당을 계산하거나 기한 날짜를 만들지 않는다.
// 퇴직금 「대상 아님」(10r) · DC형(10s)은 다른 화면 — 여기서는 설명 · 금액 문자열을 서버가 주는 구조로만 받는다.
import Foundation

/// 지급 행 오른쪽 값(서버 값). 금액 · 상태 배지 · 상태 글자 중 하나
nonisolated enum OffboardingPayValue: Equatable, Sendable {
    /// 금액 문자열(「약 1,790,000원」 포함) — 굵은 먹색
    case won(String)
    /// 상태 배지(「대상 아님」) — 회색 배지
    case badge(String)
    /// 상태 글자(「DC 계좌」) — 금액 아님, 회색 글자
    case note(String)

    var text: String {
        switch self {
        case .won(let t), .badge(let t), .note(let t): t
        }
    }
}

/// 지급할 것 한 행. 값은 서버가 만든 문자열
nonisolated struct OffboardingPayItem: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var value: OffboardingPayValue

    init(id: String, title: String, detail: String, value: OffboardingPayValue) {
        self.id = id; self.title = title; self.detail = detail; self.value = value
    }

    /// 금액 행(10n)
    init(id: String, title: String, detail: String, amountText: String) {
        self.init(id: id, title: title, detail: detail, value: .won(amountText))
    }

    var amountText: String { value.text }
    /// 금액 행은 기존 순서(제목, 설명, 금액). 배지 · 글자 행은 상태를 먼저(「퇴직금, 대상 아님, …」)
    var spoken: String {
        switch value {
        case .won(let t): "\(title), \(detail), \(t)"
        case .badge(let t), .note(let t): "\(title), \(t), \(detail)"
        }
    }
}

/// 선택 행 「약정 지급 추가 ›」 — 서버가 줄 때만(10r)
nonisolated struct OffboardingAddRow: Equatable, Sendable {
    var title: String
    var detail: String
    var spoken: String { "\(title), \(detail)" }
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
    /// 지급 목록 끝의 「약정 지급 추가」 행 — nil이면 안 그린다
    var addAgreedPay: OffboardingAddRow? = nil
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

extension OffboardingState {
    /// 10r 원문 값(퇴직금 · 연차수당 대상 아님 · 최유나)
    static let notEligible = OffboardingState(
        name: "최유나", colorIndex: 2,
        periodText: "2026.3.2 \u{2013} 10.31 \u{00B7} 주 12시간",
        statusText: "퇴사 예정",
        deadlineText: "지급 기한 11월 14일",
        deadlineNote: "퇴사 후 14일 안",
        payItems: [
            OffboardingPayItem(id: "salary", title: "10월 급여", detail: "근무 마감 후 확정", value: .won("624,000원")),
            OffboardingPayItem(id: "severance", title: "퇴직금", detail: "근속 8개월 \u{00B7} 1년 미만", value: .badge("대상 아님")),
            OffboardingPayItem(id: "leave", title: "미사용 연차 수당", detail: "주 12시간 \u{00B7} 15시간 미만", value: .badge("대상 아님")),
        ],
        addAgreedPay: OffboardingAddRow(title: "약정 지급 추가", detail: "대상이 아니어도 매장이 주는 금액"),
        steps: [
            OffboardingStep(id: "date", title: "퇴사일 확정", detail: "10월 31일", isDone: true),
            OffboardingStep(id: "close", title: "10월 근무 마감", detail: nil, isDone: false),
            OffboardingStep(id: "final", title: "최종 급여 확정 \u{00B7} 지급 \u{00B7} 명세서", detail: nil, isDone: false),
            OffboardingStep(id: "insurance", title: "고용보험 상실 신고", detail: "3개월 이상 근무 \u{00B7} 직접 신고", isDone: false),
        ],
        nextStepTitle: "10월 근무 마감하기")

    /// 10s 원문 값(퇴직연금 DC형 · 이종민)
    static let dcPension = OffboardingState(
        name: "이종민", colorIndex: 0,
        periodText: "2024.3.4 \u{2013} 10.31 \u{00B7} 주 20시간",
        statusText: "퇴직연금 DC",
        deadlineText: "지급 \u{00B7} 적립 기한 11월 14일",
        deadlineNote: "퇴사 후 14일 안",
        payItems: [
            OffboardingPayItem(id: "salary", title: "10월 급여", detail: "근무 마감 후 확정", value: .won("1,218,000원")),
            OffboardingPayItem(id: "leave", title: "미사용 연차 수당", detail: "남은 36시간 \u{00D7} 12,000", value: .won("432,000원")),
            OffboardingPayItem(id: "severance", title: "퇴직급여", detail: "연금사업자가 지급 \u{00B7} 앱에서 계산 안 함", value: .note("DC 계좌")),
        ],
        steps: [
            OffboardingStep(id: "date", title: "퇴사일 확정", detail: "10월 31일 \u{00B7} 사직서 받음", isDone: true),
            OffboardingStep(id: "close", title: "10월 근무 마감", detail: nil, isDone: false),
            OffboardingStep(id: "final", title: "최종 급여 \u{00B7} 연차 수당 확정 \u{00B7} 지급", detail: nil, isDone: false),
            OffboardingStep(id: "dc", title: "퇴직연금 미납 부담금 적립", detail: "\u{25CB}\u{25CB}은행 퇴직연금 \u{00B7} 11월 14일까지", isDone: false),
            OffboardingStep(id: "insurance", title: "4대보험 상실 신고", detail: "직접 신고 \u{00B7} 11월 15일까지", isDone: false),
        ],
        nextStepTitle: "10월 근무 마감하기")
}
