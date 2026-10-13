// UI-IOS-20a · REQ-007 · DEC-001 — 사장님 · 직원 추가 선택 시트(초대 보내기 / 직접 등록).
// 처음 선택값은 서버 · 호출자 값. 선택이 없으면 「다음」 비활성(원문엔 미선택 상태 없음 — 추정).
import Foundation

nonisolated enum StaffAddMethod: String, CaseIterable, Identifiable, Equatable, Sendable {
    case invite, direct

    var id: String { rawValue }
    var title: String { self == .invite ? "초대 보내기" : "직접 등록" }
    var detail: String {
        self == .invite ? "직원이 앱으로 출퇴근해요 · 기록은 직원이 남겨요" : "앱 없이 시작해요 · 근무는 사장님이 기록해요"
    }
    /// 「직접 등록, 앱 없이 시작해요 · 근무는 사장님이 기록해요」
    var readout: String { "\(title), \(detail)" }
}

nonisolated struct StaffAddState: Equatable, Sendable {
    static let title = "직원 추가"
    static let notice = "직접 등록한 직원도 나중에 초대할 수 있어요. 그동안의 기록은 그대로 이어져요."
    static let nextTitle = "다음"

    /// 처음 선택 — 서버 · 호출자 값(원문 캡처는 직접 등록)
    let initialSelection: StaffAddMethod?

    func canNext(_ selection: StaffAddMethod?) -> Bool { selection != nil }

    static let sample = StaffAddState(initialSelection: .direct)
}
