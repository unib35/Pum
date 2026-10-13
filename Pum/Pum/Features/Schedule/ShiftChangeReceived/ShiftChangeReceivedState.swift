// UI-IOS-17f · REQ-050 — 직원 · 게시 후 근무 변경 요청 받음 (수락 / 거절)
// 인정 근무 · 예상 급여 증감은 서버/엔진 값 — 화면에서 빼거나 더하지 않는다. 모든 값 let.
// REQ-051: 수락 · 거절을 유도하는 문구를 만들지 않는다. 응답 전까지는 기존 근무로 계산된다.
import Foundation

/// 어느 버튼이 처리 중인지 — 누른 버튼에만 처리 중 표시, 다른 버튼은 모양 그대로 누르기만 막는다
nonisolated enum ShiftChangeResponse: Equatable, Sendable { case decline, accept }

nonisolated struct ShiftChangeReceivedState: Equatable, Sendable {
    static let backTitle = "소식"
    static let title = "근무 시간 변경"
    static let needsDecisionTitle = "결정 필요"
    static let beforeLabel = "기존"
    static let afterLabel = "변경"
    static let reasonLabel = "사유"
    static let impactTitle = "바뀌면"
    static let creditedLabel = "인정 근무"
    static let payLabel = "예상 급여"
    static let declineTitle = "거절"
    static let acceptTitle = "수락"
    static let footerNotice = "응답하기 전까지는 기존 근무예요"

    /// 「10월 4일 14:20」
    let sentAtText: String
    /// 「박」 — 사장님 이름 첫 글자(서버 값)
    let senderInitial: String
    /// 「박민수 사장님 · 종민김밥 본점」
    let senderText: String
    /// 「10월 7일 수」
    let dateText: String
    /// 「17:00 – 22:00」
    let beforeTimeText: String
    let afterTimeText: String
    let reason: String
    /// 서버 값 — 「4h 30m → 3h 30m」
    let creditedText: String
    /// 서버 값 — 「−12,000원」(증감 부호 포함)
    let payDeltaText: String
    let responding: ShiftChangeResponse?

    init(sentAtText: String, senderInitial: String, senderText: String, dateText: String,
         beforeTimeText: String, afterTimeText: String, reason: String,
         creditedText: String, payDeltaText: String, responding: ShiftChangeResponse? = nil) {
        self.sentAtText = sentAtText
        self.senderInitial = senderInitial
        self.senderText = senderText
        self.dateText = dateText
        self.beforeTimeText = beforeTimeText
        self.afterTimeText = afterTimeText
        self.reason = reason
        self.creditedText = creditedText
        self.payDeltaText = payDeltaText
        self.responding = responding
    }

    var isResponding: Bool { responding != nil }
    func isLoading(_ button: ShiftChangeResponse) -> Bool { responding == button }

    /// 처리 중으로 바꾼 사본 — 이미 처리 중이면 nil(두 번 보내지 않기)
    func beginning(_ button: ShiftChangeResponse) -> ShiftChangeReceivedState? {
        guard responding == nil else { return nil }
        return with(responding: button)
    }

    /// 실패했을 때만 풀린다
    func ended() -> ShiftChangeReceivedState { with(responding: nil) }

    /// 「기존 17:00부터 22:00, 변경 18:00부터 22:00」
    var timesAccessibilityText: String {
        "\(Self.beforeLabel) \(Self.spokenRange(beforeTimeText)), \(Self.afterLabel) \(Self.spokenRange(afterTimeText))"
    }

    /// 「예상 급여, 12,000원 줄어요」 — 서버 글자의 맨 앞 부호(−·-·+)로 판단. 부호가 없으면 값 그대로
    var payAccessibilityText: String {
        let trimmed = payDeltaText.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return Self.payLabel }
        let body = String(trimmed.dropFirst())
        switch first {
        case "−", "-", "–": return "\(Self.payLabel), \(body) 줄어요"
        case "+": return "\(Self.payLabel), \(body) 늘어요"
        default: return "\(Self.payLabel), \(trimmed)"
        }
    }

    var creditedAccessibilityText: String {
        let spoken = creditedText
            .replacingOccurrences(of: #"(\d+)h"#, with: "$1시간", options: .regularExpression)
            .replacingOccurrences(of: #"(\d+)m"#, with: "$1분", options: .regularExpression)
            .replacingOccurrences(of: " → ", with: "에서 ")
        return "\(Self.creditedLabel), \(spoken)"
    }

    /// 「17:00 – 22:00」 → 「17:00부터 22:00」
    private static func spokenRange(_ text: String) -> String {
        let parts = text.components(separatedBy: CharacterSet(charactersIn: "–-—")).map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.count == 2 ? "\(parts[0])부터 \(parts[1])" : text
    }

    private func with(responding: ShiftChangeResponse?) -> ShiftChangeReceivedState {
        ShiftChangeReceivedState(sentAtText: sentAtText, senderInitial: senderInitial, senderText: senderText,
                                 dateText: dateText, beforeTimeText: beforeTimeText, afterTimeText: afterTimeText,
                                 reason: reason, creditedText: creditedText, payDeltaText: payDeltaText,
                                 responding: responding)
    }

    /// 원문 캡처 값
    static let sample = ShiftChangeReceivedState(
        sentAtText: "10월 4일 14:20", senderInitial: "박", senderText: "박민수 사장님 · 종민김밥 본점",
        dateText: "10월 7일 수", beforeTimeText: "17:00 – 22:00", afterTimeText: "18:00 – 22:00",
        reason: "저녁 단체 예약 취소", creditedText: "4h 30m → 3h 30m", payDeltaText: "−12,000원")
}
