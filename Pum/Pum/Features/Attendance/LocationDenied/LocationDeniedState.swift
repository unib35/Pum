// UI-IOS-6r · REQ-022 · REQ-095 — 위치 권한이 꺼져 있을 때 대체 경로. 문구 · 사업장 · 반경은 서버 값 그대로.
// 시스템 설정 열기는 호출자 몫(여기서 CoreLocation을 쓰지 않는다). 대체 경로는 어떤 경우에도 잠그지 않는다(REQ-029).
import Foundation

nonisolated struct LocationDeniedStep: Equatable, Sendable, Identifiable {
    /// 번호 원 글자
    let number: Int
    let title: String

    var id: Int { number }
    /// 「1단계, iPhone 설정 열기」
    var spoken: String { "\(number)단계, \(title)" }
}

nonisolated struct LocationDeniedState: Equatable, Sendable {
    static let screenTitle = "출근 기록"
    static let heading = "위치 권한이 꺼져 있어요"
    static let openSettingsTitle = "iPhone 설정으로 이동"
    static let useQRTitle = "매장 QR로 출근"
    static let requestManualTitle = "관리자에게 수동 기록 요청"
    static let steps: [LocationDeniedStep] = [
        .init(number: 1, title: "iPhone 설정 열기"),
        .init(number: 2, title: "품 \u{2192} 위치"),
        .init(number: 3, title: "\"앱을 사용하는 동안\" 선택"),
    ]

    /// 서버 값
    var workplaceName: String
    /// 매장 반경(m) — 서버 값
    var radiusMeters: Int

    /// 「종민김밥 본점은 매장 반경 100m 안에서 출근하도록 설정돼 있어요. 위치를 켜거나 매장 QR로 출근할 수 있어요.」
    var message: String {
        "\(workplaceName)은 매장 반경 \(radiusMeters)m 안에서 출근하도록 설정돼 있어요. 위치를 켜거나 매장 QR로 출근할 수 있어요."
    }

    static let sample = LocationDeniedState(workplaceName: "종민김밥 본점", radiusMeters: 100)
}
