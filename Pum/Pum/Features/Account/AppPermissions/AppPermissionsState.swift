// UI-IOS-6f · REQ-023 — 앱 권한 상태. 각 권한 상태는 기기(호출자)가 준 값이다. 화면은 권한 API를 import하지 않는다.
import Foundation

/// 권한 종류 — 원문 순서
nonisolated enum AppPermissionKind: String, CaseIterable, Sendable {
    case location, camera, notification, faceID, photos

    var title: String {
        switch self {
        case .location: "위치"
        case .camera: "카메라"
        case .notification: "알림"
        case .faceID: "Face ID"
        case .photos: "사진"
        }
    }

    var reason: String {
        switch self {
        case .location: "출퇴근 장소 확인 · 출퇴근 버튼을 누를 때만"
        case .camera: "매장 QR 스캔 · 사업자등록증 · 보건증 촬영"
        case .notification: "출퇴근 · 근무 요청 · 급여 확정"
        case .faceID: "급여 · 명세서 · 계좌 정보 보호"
        case .photos: "서류 제출 시 앨범에서 선택"
        }
    }

    var symbol: String {
        switch self {
        case .location: "mappin.and.ellipse"
        case .camera: "camera"
        case .notification: "bell"
        case .faceID: "faceid"
        case .photos: "photo"
        }
    }
}

/// 권한 상태 글자. 원문은 앱 사용 중 · 허용 · 켜짐 · 묻지 않음만 있다. 「거부됨」 「꺼짐」은 원문에 없어 정한 값.
nonisolated enum AppPermissionStatus: Equatable, Sendable {
    case whileUsing, granted, on, notAsked, denied, off

    var text: String {
        switch self {
        case .whileUsing: "앱 사용 중"
        case .granted: "허용"
        case .on: "켜짐"
        case .notAsked: "묻지 않음"
        case .denied: "거부됨"
        case .off: "꺼짐"
        }
    }

    /// 초록(완료 의미)은 쓰는 중인 상태만. 나머지는 회색
    var isActive: Bool {
        switch self {
        case .whileUsing, .granted, .on: true
        case .notAsked, .denied, .off: false
        }
    }
}

nonisolated struct AppPermissionRow: Equatable, Sendable, Identifiable {
    let kind: AppPermissionKind
    let status: AppPermissionStatus
    var id: AppPermissionKind { kind }
}

nonisolated struct AppPermissionsState: Equatable, Sendable {
    static let headerTitle = "앱 권한"
    static let intro = "필요한 기능을 처음 쓸 때 한 번만 물어봐요. 허용 여부는 iPhone 설정에서 바꿀 수 있어요."
    static let unrequestedHeader = "요청하지 않는 권한"
    static let unrequestedBody = "연락처 · 마이크 · 백그라운드 위치(항상 허용) · 추적(ATT)은 쓰지 않아요."
    static let openSettingsTitle = "iPhone 설정 열기"

    /// 기기에서 읽은 상태, 원문 순서(위치 · 카메라 · 알림 · Face ID · 사진)
    let rows: [AppPermissionRow]

    /// 「위치, 출퇴근 장소 확인 · 출퇴근 버튼을 누를 때만, 앱 사용 중」
    func rowAccessibility(_ row: AppPermissionRow) -> String {
        "\(row.kind.title), \(row.kind.reason), \(row.status.text)"
    }

    static let sample = AppPermissionsState(rows: [
        AppPermissionRow(kind: .location, status: .whileUsing),
        AppPermissionRow(kind: .camera, status: .granted),
        AppPermissionRow(kind: .notification, status: .granted),
        AppPermissionRow(kind: .faceID, status: .on),
        AppPermissionRow(kind: .photos, status: .notAsked),
    ])
}
