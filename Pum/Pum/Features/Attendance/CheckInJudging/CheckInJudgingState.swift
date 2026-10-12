// UI-IOS-21m · REQ-022 · REQ-095 — 출근 판정 중(직원): QR은 완료 · 위치는 확인 중
// 행 제목 · 설명 · 상태(done · checking)와 사업장 이름은 서버(판정 엔진) 값 그대로 — 화면은 계산하지 않는다.
// 10초가 넘으면 「다시 확인 / 사장님 확인 요청」(10w)으로 바꾸는 일은 화면 밖(호출자) 책임이다.
import Foundation

nonisolated struct CheckInJudgingStep: Equatable, Sendable, Identifiable {
    enum Status: Equatable, Sendable { case done, checking }

    let id: String
    /// 제목 · 설명은 서버(판정 엔진) 글자 그대로 — 사업장 이름 · 정확도 기준(100m)도 서버가 채운다
    let title: String
    let detail: String
    let status: Status

    /// 진행 중 행은 제목이 이미 「확인 중」이라 같은 말을 되풀이하지 않게 「진행 중」
    var statusText: String { status == .done ? "완료" : "진행 중" }
    /// 「QR 확인, 종민김밥 본점 · 매장 QR, 완료」
    var accessibilityText: String { "\(title), \(detail), \(statusText)" }
}

nonisolated struct CheckInJudgingState: Equatable, Sendable {
    var workplaceName: String
    var steps: [CheckInJudgingStep]

    static let backTitle = "홈"
    static let title = "출근 확인"
    static let buttonTitle = "확인 중"
    static let footnote = "위치는 지금 한 번만 확인해요"

    /// 디자인 21m 예시 값(가짜 데이터)
    static let sample = CheckInJudgingState(
        workplaceName: "종민김밥 본점",
        steps: [
            CheckInJudgingStep(id: "qr", title: "QR 확인", detail: "종민김밥 본점 \u{00B7} 매장 QR", status: .done),
            CheckInJudgingStep(id: "distance", title: "현재 거리 확인 중", detail: "정확도 100m 안이 될 때까지 기다려요", status: .checking),
        ]
    )
}
