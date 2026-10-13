// UI-IOS-17g · REQ-042 — 직원 · 동료의 대타 요청 받음 (수락 / 거절)
// 그 주 근무 시간 · 예상 급여 · 단계 진행은 서버/엔진 값 — 화면에서 계산하지 않는다. 모든 값 let.
// REQ-051: 수락 · 거절을 유도하는 문구를 만들지 않는다. 사장님 승인 전까지는 요청한 동료의 근무다.
import Foundation

/// 어느 버튼이 처리 중인지 — 누른 버튼에만 처리 중 표시, 다른 버튼은 모양 그대로 누르기만 막는다
nonisolated enum CoverRequestResponse: Equatable, Sendable { case decline, accept }

/// 3단계 한 칸 — 진행 상태는 서버 값
nonisolated struct CoverRequestStep: Equatable, Sendable, Identifiable {
    let number: Int
    let title: String
    /// 둘째 줄(없을 수 있음)
    let note: String?
    let isDone: Bool

    var id: Int { number }

    /// 「1단계, 내가 수락, 아직」 — 둘째 줄이 있으면 뒤에 붙인다
    var spoken: String {
        let base = "\(number)단계, \(title), \(isDone ? "완료" : "아직")"
        guard let note else { return base }
        return "\(base), \(note)"
    }
}

nonisolated struct CoverRequestReceivedState: Equatable, Sendable {
    static let backTitle = "소식"
    static let title = "대타 요청"
    static let needsDecisionTitle = "결정 필요"
    static let ifAcceptTitle = "수락하면"
    static let weekHoursLabel = "그 주 내 근무"
    static let payLabel = "예상 급여"
    static let declineTitle = "거절"
    static let acceptTitle = "수락"

    /// 「어제 21:40 · 먼저 수락한 1명」 — 서버 글자
    let sentAtText: String
    /// 「종」 — 요청한 동료 이름 첫 글자
    let senderInitial: String
    /// 「이종민」
    let senderName: String
    /// 「학교 시험 기간」
    let reason: String
    /// 「10월」 — 읽기용(화면에는 안 보임)
    let monthText: String
    /// 「월」
    let weekdayText: String
    /// 「12」
    let dayText: String
    /// 「17:00 – 22:00」
    let timeText: String
    /// 「종민김밥 본점 · 휴게 30분」
    let placeText: String
    /// 서버 값 — 「23h → 27h 30m」
    let weekHoursText: String
    /// 서버 값 — 「소정근로 초과 2.5h 50% 가산 포함」
    let payNote: String
    /// 서버 값 — 「+63,250원」(증감 부호 포함)
    let payDeltaText: String
    /// 「내가 수락」 · 「사장님 승인」 · 「내 스케줄에 추가」 — 진행 상태는 서버 값
    let steps: [CoverRequestStep]
    /// 먼저 수락한 1명이 이미 차면 false — 원문 없음(결정 필요), 수락만 막는다
    let canAccept: Bool
    let responding: CoverRequestResponse?

    init(sentAtText: String, senderInitial: String, senderName: String, reason: String,
         monthText: String, weekdayText: String, dayText: String, timeText: String, placeText: String,
         weekHoursText: String, payNote: String, payDeltaText: String,
         steps: [CoverRequestStep], canAccept: Bool = true, responding: CoverRequestResponse? = nil) {
        self.sentAtText = sentAtText
        self.senderInitial = senderInitial
        self.senderName = senderName
        self.reason = reason
        self.monthText = monthText
        self.weekdayText = weekdayText
        self.dayText = dayText
        self.timeText = timeText
        self.placeText = placeText
        self.weekHoursText = weekHoursText
        self.payNote = payNote
        self.payDeltaText = payDeltaText
        self.steps = steps
        self.canAccept = canAccept
        self.responding = responding
    }

    /// 「이종민 · 학교 시험 기간」
    var senderText: String { "\(senderName) · \(reason)" }

    var isResponding: Bool { responding != nil }
    func isLoading(_ button: CoverRequestResponse) -> Bool { responding == button }

    /// 처리 중으로 바꾼 사본 — 이미 처리 중이거나 수락할 수 없는 상태의 수락이면 nil
    func beginning(_ button: CoverRequestResponse) -> CoverRequestReceivedState? {
        guard responding == nil else { return nil }
        if button == .accept && !canAccept { return nil }
        return with(responding: button)
    }

    /// 실패했을 때만 풀린다
    func ended() -> CoverRequestReceivedState { with(responding: nil) }

    /// 「10월 12일 월, 17:00부터 22:00, 종민김밥 본점 · 휴게 30분」
    var shiftAccessibilityText: String {
        "\(monthText) \(dayText)일 \(weekdayText), \(Self.spokenRange(timeText)), \(placeText)"
    }

    /// 「그 주 내 근무, 23시간에서 27시간 30분」
    var weekHoursAccessibilityText: String {
        let spoken = weekHoursText
            .replacingOccurrences(of: #"(\d+)h"#, with: "$1시간", options: .regularExpression)
            .replacingOccurrences(of: #"(\d+)m"#, with: "$1분", options: .regularExpression)
            .replacingOccurrences(of: " → ", with: "에서 ")
        return "\(Self.weekHoursLabel), \(spoken)"
    }

    /// 「예상 급여, 63,250원 늘어요, 소정근로 초과 …」 — 서버 글자의 맨 앞 부호로 판단. 부호가 없으면 값 그대로
    var payAccessibilityText: String {
        let trimmed = payDeltaText.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return Self.payLabel }
        let body = String(trimmed.dropFirst())
        let amount: String
        switch first {
        case "−", "-", "–": amount = "\(body) 줄어요"
        case "+": amount = "\(body) 늘어요"
        default: amount = trimmed
        }
        return "\(Self.payLabel), \(amount), \(payNote)"
    }

    /// 「17:00 – 22:00」 → 「17:00부터 22:00」
    private static func spokenRange(_ text: String) -> String {
        let parts = text.components(separatedBy: CharacterSet(charactersIn: "–-—")).map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.count == 2 ? "\(parts[0])부터 \(parts[1])" : text
    }

    private func with(responding: CoverRequestResponse?) -> CoverRequestReceivedState {
        CoverRequestReceivedState(sentAtText: sentAtText, senderInitial: senderInitial, senderName: senderName,
                                  reason: reason, monthText: monthText, weekdayText: weekdayText, dayText: dayText,
                                  timeText: timeText, placeText: placeText, weekHoursText: weekHoursText,
                                  payNote: payNote, payDeltaText: payDeltaText, steps: steps,
                                  canAccept: canAccept, responding: responding)
    }

    /// 원문 캡처 값 — 세 단계 모두 아직
    static let sample = CoverRequestReceivedState(
        sentAtText: "어제 21:40 · 먼저 수락한 1명", senderInitial: "종", senderName: "이종민", reason: "학교 시험 기간",
        monthText: "10월", weekdayText: "월", dayText: "12", timeText: "17:00 – 22:00",
        placeText: "종민김밥 본점 · 휴게 30분",
        weekHoursText: "23h → 27h 30m", payNote: "소정근로 초과 2.5h 50% 가산 포함", payDeltaText: "+63,250원",
        steps: [
            CoverRequestStep(number: 1, title: "내가 수락", note: nil, isDone: false),
            CoverRequestStep(number: 2, title: "사장님 승인", note: "승인 전까지는 이종민 근무예요", isDone: false),
            CoverRequestStep(number: 3, title: "내 스케줄에 추가", note: nil, isDone: false),
        ])
}
