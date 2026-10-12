// UI-IOS-10v · REQ-021 · REQ-022 · REQ-023 — 위치만 · 간편 출근
// 거리 · 허용 · 사업장 이름 · 근무 시각 · 방식 문구는 서버 값 그대로 — 화면은 계산하지 않고 단위 표기만 한다.
// 위치는 누르는 순간 1회만 판정(REQ-023). 「현재 위치」 값은 직전 판정 결과로 부모가 준다.
import Foundation

nonisolated struct LocationCheckInState: Equatable, Sendable {
    var workplaceName: String
    /// 칩 안 파랑 네모 글자(사업장 첫 글자)
    var workplaceInitial: String
    var dateText: String
    /// 서버가 준 근무 시간 글자(예: 17:00 – 22:00)
    var shiftText: String
    var statusText: String
    /// 직전 판정 값(정수 m). 값이 없어도 출근하기는 활성(REQ-029)
    var distanceMeters: Int?
    /// 서버 판정 — 반경 안이면 true. 체크 표시 · 「확인됨」은 이 값으로만(거리 숫자로 화면이 판단하지 않는다)
    var isWithinRadius: Bool = false
    var radiusMeters: Int
    /// 서버가 준 사업장 짧은 이름(「종민김밥」)
    var placeShortName: String
    var methodNote: String
    var methodValue: String

    static let todayTitle = "오늘 근무"
    static let mapLabel = "지도"
    static let currentLocationTitle = "현재 위치"
    static let methodTitle = "출근 방식"
    static let checkInTitle = "출근하기"
    static let checkingTitle = "확인 중"
    static let footnote = "누르는 순간의 위치만 확인해요"

    var distanceDetail: String? {
        distanceMeters.map { "\(placeShortName) \u{00B7} \(Self.lengthText($0))" }
    }
    var radiusText: String { "허용 \(Self.lengthText(radiusMeters))" }
    var methodDetail: String { methodNote }

    var locationAccessibilityLabel: String {
        guard let d = distanceMeters else { return "현재 위치, 아직 확인 전, 허용 \(Self.spoken(radiusMeters))" }
        let tail = isWithinRadius ? ", 확인됨" : ""
        return "현재 위치, \(placeShortName), \(Self.spoken(d)), 허용 \(Self.spoken(radiusMeters))\(tail)"
    }

    /// 10u와 같은 규칙 — 1000m 미만은 「Nm」, 이상은 소수 한 자리 km
    static func lengthText(_ meters: Int) -> String { CheckInTooFarState.lengthText(meters) }
    static func spoken(_ meters: Int) -> String { CheckInTooFarState.spoken(meters) }

    /// 디자인 10v 예시 값(가짜 데이터)
    static let sample = LocationCheckInState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종", dateText: "10월 6일 화",
        shiftText: "17:00 \u{2013} 22:00", statusText: "출근 전",
        distanceMeters: 12, isWithinRadius: true, radiusMeters: 100, placeShortName: "종민김밥",
        methodNote: "사업장 설정 \u{00B7} 사장님이 정해요", methodValue: "위치 확인"
    )
}

/// 「출근하기」 한 번만 — 처리 중 잠그고, 끝나면 푼다.
nonisolated struct LocationCheckInLock: Equatable, Sendable {
    private(set) var isChecking = false
    mutating func begin() -> Bool {
        guard !isChecking else { return false }
        isChecking = true
        return true
    }
    mutating func finish() { isChecking = false }
}
