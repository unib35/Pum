// UI-IOS-10w · REQ-022 · REQ-029 — 출근 판정 · 위치 오차가 클 때: 판정 보류, 기록하지 않고 다른 방법 안내
// 오차 · 허용 · 시각 · QR 위치 설명 · 안내 문구는 서버 값 그대로 — 화면은 계산하지 않고 단위 표기만 한다.
import Foundation

nonisolated struct CheckInLowAccuracyState: Equatable, Sendable {
    /// 서버가 준 대체 경로(매장에 QR이 없으면 QR 항목이 빠질 수 있다)
    struct Alternative: Equatable, Sendable, Identifiable {
        enum Kind: Equatable, Sendable { case scanQR, requestOwner }
        var kind: Kind
        var title: String
        var detail: String
        var id: Kind { kind }
    }

    var workplaceName: String
    var dateText: String
    var timeText: String
    /// 서버 판정 값(정수 m) — 오차가 허용보다 크면 보류
    var accuracyMeters: Int
    var radiusMeters: Int
    /// 서버가 준 안내 문구
    var hint: String
    var alternatives: [Alternative]

    static let screenTitle = "출근"
    static let title = "위치를 정확히 확인하지 못했어요"
    static let sectionTitle = "확인"
    static let locationTitle = "위치 확인"
    static let mapLabel = "지도"
    static let alternativesTitle = "다른 방법"
    static let retryTitle = "다시 시도"
    static let retryingTitle = "확인 중"

    var subtitle: String { "\(workplaceName) \u{00B7} \(dateText) \(timeText)" }
    var accuracyText: String { CheckInTooFarState.lengthText(accuracyMeters) }
    var radiusText: String { CheckInTooFarState.lengthText(radiusMeters) }
    var locationDetail: String { "오차 \u{00B1}\(accuracyText) \u{00B7} 허용 \(radiusText)보다 커요" }
    var locationAccessibilityLabel: String {
        "위치 확인, 보류, 오차 \(CheckInTooFarState.spoken(accuracyMeters)), 허용 \(CheckInTooFarState.spoken(radiusMeters))보다 커요"
    }

    func accessibilityLabel(for alt: Alternative) -> String { "\(alt.title), \(alt.detail)" }

    /// 디자인 10w 예시 값(가짜 데이터)
    static let sample = CheckInLowAccuracyState(
        workplaceName: "종민김밥 본점", dateText: "10월 6일 화", timeText: "16:57",
        accuracyMeters: 180, radiusMeters: 100, hint: "실내나 지하에서는 오차가 커질 수 있어요",
        alternatives: [
            Alternative(kind: .scanQR, title: "매장 QR로 확인", detail: "카운터 옆 출근 QR"),
            Alternative(kind: .requestOwner, title: "사장님에게 확인 요청", detail: "승인되면 16:57 출근")
        ]
    )
}

/// 「다시 시도」 한 번만 — 판정 중 잠그고, 끝나면 푼다. 다른 방법은 이 잠금과 무관(REQ-029).
nonisolated struct CheckInLowAccuracyLock: Equatable, Sendable {
    private(set) var isChecking = false
    mutating func begin() -> Bool {
        guard !isChecking else { return false }
        isChecking = true
        return true
    }
    mutating func finish() { isChecking = false }
}
