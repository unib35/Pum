// UI-IOS-10l · REQ-020 · REQ-021 — 출근 확인 방식: 방식 · 위치 · 허용 반경 · 대체 경로 · 출근 QR.
// 방식 목록 · 설명 · 배지 · 반경 선택지 · 주소 · 대체 경로 문구는 서버 값 — 화면에서 만들거나 판단하지 않는다.
// 공용기기는 충돌 #10(V1 이후): 쓸 수 있는지는 서버 isAvailable.
import Foundation

nonisolated enum CheckInMethodKind: Equatable, Hashable, Sendable {
    case qrAndLocation, locationOnly, qrOnly, adminConfirm, sharedDevice

    /// 위치(매장 위치 · 허용 반경)를 쓰는 방식. 원문에 없는 경우(QR만 · 관리자 확인)는 「위치」 섹션을 잠근다(판단).
    var usesLocation: Bool { self == .qrAndLocation || self == .locationOnly }
}

nonisolated enum CheckInBadgeTone: Equatable, Sendable {
    /// 연파랑 — 「추천」
    case recommended
    /// 회색 — 「기기가 있을 때」
    case neutral
}

nonisolated struct CheckInBadge: Equatable, Sendable {
    var text: String
    var tone: CheckInBadgeTone
}

nonisolated struct CheckInMethodOption: Equatable, Identifiable, Sendable {
    var kind: CheckInMethodKind
    var title: String
    var detail: String
    var badge: CheckInBadge?
    /// 서버가 정한다. false면 흐리게 · 선택 불가(공용기기 = 충돌 #10).
    var isAvailable: Bool
    var id: CheckInMethodKind { kind }
}

/// 저장하는 값 — 방식 · 허용 반경(m)
nonisolated struct CheckInPolicy: Equatable, Sendable {
    var method: CheckInMethodKind
    var radiusMeters: Int
}

nonisolated struct CheckInMethodState: Equatable, Sendable {
    var options: [CheckInMethodOption]
    /// 서버가 준 반경 선택지(m)
    var radiusChoices: [Int]
    /// 지금 저장된 값
    var policy: CheckInPolicy
    /// 예: 「양화로 12」
    var address: String
    /// 예: 「사장님에게 확인 요청」
    var fallbackValue: String
    /// 예: 「PDF · 이미지 저장」
    var qrValue: String

    static let headerTitle = "출근 확인"
    static let methodHeader = "방식"
    static let locationHeader = "위치"
    static let addressTitle = "매장 위치"
    static let radiusTitle = "허용 반경"
    static let fallbackTitle = "위치가 안 될 때"
    static let qrTitle = "출근 QR"
    static let saveTitle = "저장"
    static let notice = "근무 중에는 위치를 수집하지 않아요 · 출퇴근 순간 1회"

    static func radiusText(_ meters: Int) -> String { "\(meters)m" }

    /// VoiceOver — 「QR + 위치, 추천, 매장 QR로…, 선택됨, 5개 중 1번째」
    func optionAccessibility(_ option: CheckInMethodOption, isOn: Bool) -> String {
        let index = (options.firstIndex(of: option) ?? 0) + 1
        var parts = [option.title]
        if let badge = option.badge { parts.append(badge.text) }
        parts.append(option.detail)
        if isOn { parts.append("선택됨") }
        parts.append("\(options.count)개 중 \(index)번째")
        return parts.joined(separator: ", ")
    }

    /// VoiceOver — 「허용 반경, 100m, 선택됨」
    static func radiusAccessibility(_ meters: Int, isOn: Bool) -> String {
        "\(radiusTitle), \(radiusText(meters)), \(isOn ? "선택됨" : "선택 안 됨")"
    }

    /// 원문 캡처 값
    static let sample = CheckInMethodState(
        options: [
            CheckInMethodOption(kind: .qrAndLocation, title: "QR + 위치", detail: "매장 QR로 사업장 확인 + 반경 안인지 확인",
                                badge: CheckInBadge(text: "추천", tone: .recommended), isAvailable: true),
            CheckInMethodOption(kind: .locationOnly, title: "위치만", detail: "반경 안에서 출근 버튼 · 사장님이 함께 일하는 매장",
                                badge: nil, isAvailable: true),
            CheckInMethodOption(kind: .qrOnly, title: "QR만", detail: "위치 권한 없이 · 사진 QR로도 출근될 수 있어요",
                                badge: nil, isAvailable: true),
            CheckInMethodOption(kind: .adminConfirm, title: "관리자 확인", detail: "직원이 출근을 누르면 사장님이 확인",
                                badge: nil, isAvailable: true),
            CheckInMethodOption(kind: .sharedDevice, title: "공용기기", detail: "매장에 있는 태블릿 · PC에 바뀌는 QR",
                                badge: CheckInBadge(text: "기기가 있을 때", tone: .neutral), isAvailable: true),
        ],
        radiusChoices: [50, 100, 200],
        policy: CheckInPolicy(method: .qrAndLocation, radiusMeters: 100),
        address: "양화로 12", fallbackValue: "사장님에게 확인 요청", qrValue: "PDF · 이미지 저장")
}

/// 사용자가 고른 값. 시작값은 서버가 준 저장값.
nonisolated struct CheckInMethodDraft: Equatable, Sendable {
    var method: CheckInMethodKind
    var radiusMeters: Int

    init(_ policy: CheckInPolicy) {
        method = policy.method
        radiusMeters = policy.radiusMeters
    }

    var policy: CheckInPolicy { CheckInPolicy(method: method, radiusMeters: radiusMeters) }

    /// 서버가 쓸 수 없다고 한 방식은 바꾸지 않는다
    mutating func select(_ option: CheckInMethodOption) {
        guard option.isAvailable else { return }
        method = option.kind
    }

    /// 서버가 준 선택지 밖 값은 받지 않는다
    mutating func selectRadius(_ meters: Int, in state: CheckInMethodState) {
        guard state.radiusChoices.contains(meters) else { return }
        radiusMeters = meters
    }

    /// 바뀐 게 없으면 저장하지 않는다
    func canSave(for state: CheckInMethodState) -> Bool { policy != state.policy }
}

/// 저장은 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
nonisolated struct CheckInMethodLock: Equatable, Sendable {
    private(set) var isSaving = false
    mutating func begin() -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        return true
    }
    /// 끝나면 풀린다 — 설정 저장은 다시 해도 되는 일이라 성공 뒤에도 화면에 갇히지 않게(처리 중에만 한 번)
    mutating func finish(success: Bool) { isSaving = false }
}
