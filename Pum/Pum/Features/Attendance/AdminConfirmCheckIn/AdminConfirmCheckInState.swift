// UI-IOS-10x · REQ-021 — 관리자 확인 방식: 누른 시각으로 요청, 사장님 확인 후 기록
// 시각 · 거리 · 확인자 · 문구 · 단계 상태 · 배지는 모두 서버 값 그대로 — 화면은 시각 · 거리를 계산하지 않는다.
import Foundation

nonisolated struct AdminConfirmCheckInState: Equatable, Sendable {
    nonisolated enum StepStatus: Equatable, Sendable {
        case done, inProgress, pending

        var spoken: String {
            switch self {
            case .done: "완료"
            case .inProgress: "진행 중"
            case .pending: "아직"
            }
        }
    }

    nonisolated struct Step: Equatable, Sendable, Identifiable {
        var id: String
        var title: String
        var detail: String
        var status: StepStatus
    }

    var workplaceName: String
    /// 칩 안 파랑 네모 글자(사업장 첫 글자)
    var workplaceInitial: String
    var dateText: String
    /// 서버가 준 근무 시간 글자(예: 17:00 – 22:00)
    var shiftText: String
    var statusText: String
    var steps: [Step]
    var noticeTitle: String
    var noticeDetail: String
    var noticeValue: String

    static let todayTitle = "오늘 근무"
    static let sectionTitle = "출근"
    static let cancelTitle = "요청 취소"

    func stepSpoken(_ step: Step) -> String {
        let n = (steps.firstIndex(where: { $0.id == step.id }) ?? 0) + 1
        return "\(step.title), \(step.detail), \(step.status.spoken), \(steps.count)단계 중 \(n)번째"
    }

    var noticeAccessibilityLabel: String { "\(noticeTitle), \(noticeDetail), \(noticeValue)" }

    /// 디자인 10x 예시 값(가짜 데이터)
    static let sample = AdminConfirmCheckInState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종", dateText: "10월 6일 화",
        shiftText: "17:00 \u{2013} 22:00", statusText: "확인 대기",
        steps: [
            Step(id: "request", title: "출근 요청", detail: "16:58 \u{00B7} 매장에서 12m", status: .done),
            Step(id: "confirm", title: "사장님 확인", detail: "박민수 \u{00B7} 알림 보냄", status: .inProgress),
            Step(id: "record", title: "출근 기록", detail: "확인되면 16:58로 기록돼요", status: .pending),
        ],
        noticeTitle: "확인 전에도", noticeDetail: "근무시간은 요청 시각부터", noticeValue: "그대로 근무하면 돼요"
    )
}
