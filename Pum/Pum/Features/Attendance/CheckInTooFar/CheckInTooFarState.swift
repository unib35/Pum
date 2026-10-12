// UI-IOS-10u · REQ-022 · REQ-029 — 출근 판정 · 거리 초과: 기록하지 않고 대체 경로
// 거리 초과는 서버 판정 결과라 출근을 기록하지 않는다(REQ-029의 「막지 않음」은 오류 상황 — 이건 판정). 대신 사장님 확인 요청으로 간다.
// 거리 · 허용 · 정확도 · 시각 · 「측정은 정확해요」는 서버 값 그대로 — 화면은 계산하지 않고 단위 표기만 한다.
import Foundation

nonisolated struct CheckInTooFarState: Equatable, Sendable {
    var workplaceName: String
    /// 서버가 준 날짜 · 시각 글자(Asia/Seoul)
    var dateText: String
    var timeText: String
    /// 서버 판정 값(정수 m)
    var distanceMeters: Int
    var radiusMeters: Int
    var accuracyMeters: Int
    /// 서버가 준 정확도 설명
    var accuracyNote: String

    static let screenTitle = "출근"
    static let title = "출근을 기록하지 못했어요"
    static let sectionTitle = "확인"
    static let qrTitle = "QR 확인"
    static let locationTitle = "위치 확인"
    static let mapLabel = "지도"
    static let mapMessage = "사업장에서 너무 멀리 떨어져 있어요"
    static let accuracyTitle = "위치 정확도"
    static let ownerRowTitle = "매장에 있는데 안 된다면"
    static let ownerAction = "사장님에게 확인 요청"
    static let retryTitle = "다시 확인"
    static let retryingTitle = "확인 중"

    var subtitle: String { "\(workplaceName) \u{00B7} \(dateText) \(timeText)" }
    var qrDetail: String { "\(workplaceName) 출근 QR" }
    var distanceText: String { Self.lengthText(distanceMeters) }
    var radiusText: String { Self.lengthText(radiusMeters) }
    var locationDetail: String { "현재 거리 \(distanceText) \u{00B7} 허용 \(radiusText)" }
    var accuracyText: String { "\u{00B1}\(Self.lengthText(accuracyMeters))" }
    var ownerRowDetail: String { "승인되면 \(timeText) 출근으로 기록" }

    var locationAccessibilityLabel: String {
        "위치 확인, 실패, 현재 거리 \(Self.spoken(distanceMeters)), 허용 \(Self.spoken(radiusMeters))"
    }
    var accuracyAccessibilityLabel: String {
        "위치 정확도, \(accuracyNote), 플러스마이너스 \(Self.spoken(accuracyMeters))"
    }
    var ownerRowAccessibilityLabel: String { "\(Self.ownerRowTitle), \(ownerRowDetail), \(Self.ownerAction)" }

    /// 1000m 미만은 「Nm」, 이상은 소수 한 자리 km(0.1km 단위 반올림, 정수 계산)
    static func lengthText(_ meters: Int) -> String {
        guard meters >= 1000 else { return "\(meters)m" }
        let tenths = (meters + 50) / 100
        return tenths % 10 == 0 ? "\(tenths / 10)km" : "\(tenths / 10).\(tenths % 10)km"
    }

    /// VoiceOver용(「2.4킬로미터」 · 「100미터」)
    static func spoken(_ meters: Int) -> String {
        lengthText(meters).replacingOccurrences(of: "km", with: "킬로미터").replacingOccurrences(of: "m", with: "미터")
    }

    /// 디자인 10u 예시 값(가짜 데이터)
    static let sample = CheckInTooFarState(
        workplaceName: "종민김밥 본점", dateText: "10월 6일 화", timeText: "09:56",
        distanceMeters: 2400, radiusMeters: 100, accuracyMeters: 12, accuracyNote: "측정은 정확해요"
    )
}

/// 「다시 확인」 한 번만 — 판정 중 잠그고, 끝나면 푼다(성공이면 부모가 10t로 바꾼다).
nonisolated struct CheckInTooFarLock: Equatable, Sendable {
    private(set) var isChecking = false
    mutating func begin() -> Bool {
        guard !isChecking else { return false }
        isChecking = true
        return true
    }
    mutating func finish() { isChecking = false }
}
