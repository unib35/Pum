// UI-IOS-1e · REQ-021 · REQ-022 · REQ-023 · REQ-029 — 출근 기록(QR 스캔 + 위치 확인) 데이터
// 위치는 출퇴근 순간 1회만 판정한다(REQ-023). 이번 범위는 화면 — 실제 카메라 · 위치 연결은 후속 이슈.
// 거리 · 반경은 정수 m. 판정은 주입된 값으로만 계산한다.
import Foundation

/// 위치 판정 상태(REQ-022). 디자인 1e는 「확인됨」만 있다 — 나머지는 문구 · 색이 없어 뷰에 표시하지 않는다.
nonisolated enum ClockInLocationStatus: Equatable, Sendable {
    /// 거리 ≤ 허용 반경
    case confirmed
    /// 거리 > 허용 반경
    case outOfRange
    /// 위치 정확도가 기준(100m)을 넘어 판정할 수 없음 — 기록하지 않고 대체 경로
    case undetermined
    /// 확인 중
    case checking
}

nonisolated struct ClockInState: Equatable, Sendable {
    var workplaceName: String
    /// 사업장 허용 반경(m)
    var radiusMeters: Int
    /// 현재 위치에서 사업장까지 거리(m) · 위치 정확도(m)
    var distanceMeters: Int
    var accuracyMeters: Int
    var isChecking = false
    /// 하루 안의 분
    var plannedStart: Int
    var now: Int
    /// 사업장 정책: 자동 인정 기준(±분, REQ-026)
    var autoApproveMinutes: Int

    /// 정확도가 이 값(m)을 넘으면 판정 보류(REQ-022)
    static let accuracyLimitMeters = 100

    var locationStatus: ClockInLocationStatus {
        if isChecking { return .checking }
        if accuracyMeters > Self.accuracyLimitMeters { return .undetermined }
        return distanceMeters <= radiusMeters ? .confirmed : .outOfRange
    }

    var scanTitle: String { "매장 QR을 스캔하세요" }
    var scanHint: String { "계산대 옆 QR \u{00B7} \(workplaceName)" }
    var locationDetail: String { "\(workplaceName)에서 \(distanceMeters)m \u{00B7} 허용 반경 \(radiusMeters)m" }
    var plannedText: String { "예정 출근 \(HomeFormat.clock(plannedStart))" }

    /// 지금이 예정 출근 ±자동 인정 기준 안이면 정시 출근 안내(경계 포함). 밖이면 디자인에 문구가 없어 nil.
    var onTimeNote: String? {
        abs(now - plannedStart) <= autoApproveMinutes ? "정시 출근으로 기록돼요" : nil
    }

    /// 디자인 1e 예시 값(가짜 데이터)
    static let sample = ClockInState(
        workplaceName: "종민김밥 본점", radiusMeters: 100,
        distanceMeters: 32, accuracyMeters: 10,
        plannedStart: 17 * 60, now: 16 * 60 + 58, autoApproveMinutes: 45
    )
}
