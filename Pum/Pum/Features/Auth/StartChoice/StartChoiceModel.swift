// UI-IOS-2c · REQ-001 · REQ-005 — 시작 방식: 선택지 3개와 선택 상태(순수 로직). 문구는 디자인 원문 그대로.
import Foundation

nonisolated enum StartChoice: CaseIterable, Equatable, Sendable {
    case personal, inviteCode, owner

    var title: String {
        switch self {
        case .personal: "혼자 기록할게요"
        case .inviteCode: "초대 코드가 있어요"
        case .owner: "사장님이에요"
        }
    }

    var detail: String {
        switch self {
        case .personal: "내 출퇴근을 직접 기록하고 이번 달 예상 월급을 확인해요. 사장님이 앱을 안 써도 돼요."
        case .inviteCode: "사장님께 받은 링크·QR·6자리 코드로 사업장에 참여해요."
        case .owner: "사업장을 만들고 직원을 초대해요. 사업자 정보는 나중에 입력해도 돼요."
        }
    }

    /// 기능 태그 — 개인 모드에만 있다(원문)
    var tags: [String] {
        switch self {
        case .personal: ["근무 캘린더", "급여 계산기", "출퇴근 기록"]
        default: []
        }
    }

    /// 1부터 시작하는 순서(VoiceOver 「3개 중 1번째」)
    var position: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }
}

struct StartChoiceState: Equatable, Sendable {
    /// 아무것도 고르지 않았으면 nil — 실제 진입 상태
    var selected: StartChoice?

    init(selected: StartChoice? = nil) { self.selected = selected }

    /// 원문 캡처: 「혼자 기록할게요」 선택
    static let sample = StartChoiceState(selected: .personal)

    /// 고르지 않았으면 「다음」 비활성(이유 문구 없음, 충돌 #30과 같은 처리)
    var isNextEnabled: Bool { selected != nil }

    mutating func select(_ choice: StartChoice) { selected = choice }

    func isSelected(_ choice: StartChoice) -> Bool { selected == choice }

    /// 카드 한 장의 VoiceOver 문장 — 설명과 태그를 함께 읽는다
    func accessibilityLabel(for choice: StartChoice) -> String {
        var text = "\(choice.title), \(choice.detail)"
        if !choice.tags.isEmpty { text += " 기능: " + choice.tags.joined(separator: ", ") }
        return text
    }

    /// 선택 여부는 .isSelected 특성이 읽어 준다 — 값에 넣으면 두 번 읽힘(공통 PumRadioRow와 같은 방식)
    func accessibilityValue(for choice: StartChoice) -> String {
        "\(StartChoice.allCases.count)개 중 \(choice.position)번째"
    }
}
