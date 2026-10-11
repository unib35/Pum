// UI-IOS-5a · REQ-010 · REQ-105 — 미인증 사업장 홈: 1aq와 같은 순서, 할 일 자리에 「시작 준비」
// 날짜 · 지역 · 반경 · 인원은 서버 값. 인건비는 화면에서 계산하지 않는다.
import Foundation

nonisolated struct OwnerHomeUnverifiedState: Equatable, Sendable {
    /// 시작 준비 한 단계
    struct Step: Identifiable, Equatable, Sendable {
        enum Status: Equatable, Sendable {
            case done
            case todo
            /// 사업장 인증 후에만 가능
            case locked
        }
        let id: String
        let title: String
        let detail: String
        let status: Status
        /// 오른쪽 버튼 글자(완료 단계는 없음)
        let actionTitle: String?

        /// VoiceOver 한 줄: 「사업장 정보, 완료」 · 「직원 초대, 사업장 인증 후, 잠김」
        var accessibilityText: String {
            switch status {
            case .done: "\(title), 완료"
            case .todo: "\(title), \(detail)"
            case .locked: "\(title), \(detail.components(separatedBy: " · ").first ?? detail), 잠김"
            }
        }
    }

    let workplaceName: String
    let workplaceInitial: String
    let dateText: String
    let hasUnreadNotification: Bool
    let steps: [Step]
    /// 오늘 근무 직원 수 · 이번 달 직원 수 (서버 값)
    let todayStaffCount: Int
    let staffCount: Int
    let payrollMonthText: String

    var todayTitle: String { "오늘 근무" }
    var staffCountText: String { "직원 \(staffCount)명" }
    var todayStaffCountText: String { "직원 \(todayStaffCount)명" }
    var payrollTitle: String { "\(payrollMonthText) 예상 인건비" }
    var doneCount: Int { steps.filter { $0.status == .done }.count }

    /// 원문(5a) 값
    static let sample = OwnerHomeUnverifiedState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        dateText: "10월 3일 토",
        hasUnreadNotification: true,
        steps: [
            .init(id: "workplace", title: "사업장 정보", detail: "종민김밥 본점 · 대구 수성구", status: .done, actionTitle: nil),
            .init(id: "clockin", title: "출근 방식 · QR", detail: "QR + 위치 · 반경 100m", status: .done, actionTitle: nil),
            .init(id: "shifts", title: "근무 시간대", detail: "오전 · 오후 · 마감 같은 기본 근무", status: .todo, actionTitle: "만들기"),
            .init(id: "invite", title: "직원 초대", detail: "사업장 인증 후 · 약 2분", status: .locked, actionTitle: "인증"),
        ],
        todayStaffCount: 0,
        staffCount: 0,
        payrollMonthText: "10월"
    )
}
