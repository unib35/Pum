// UI-IOS-2k · REQ-043 — 직원 · 추가 근무 요청 받음 (수락 / 거절)
// 예상 급여 · 계산 근거 문구 · 주간 시간 · 요약은 서버/엔진 값 — 화면에서 곱하거나 더하지 않는다.
// REQ-051: 수당이나 시간을 이유로 수락 · 거절을 유도하는 문구를 만들지 않는다(원문 문구만 서버 값으로 표시).
import Foundation

/// 그 주 7칸 중 하나
nonisolated struct ExtraShiftOfferDay: Equatable, Identifiable, Sendable {
    enum Kind: Equatable, Sendable { case off, worked, thisRequest }

    let id: Int
    /// 「월」
    var weekday: String
    /// 일(1–31)
    var day: Int
    var kind: Kind
    /// 서버 값 — 예: 「5h」 · 이 요청이면 「+5h」. 쉬는 날은 빈 문자열
    var hoursText: String

    /// 원문: 근무가 있는 날만 날짜를 붙인다(월 5 · 화 · 수 7 …)
    var labelText: String { kind == .off ? weekday : "\(weekday) \(day)" }
    /// 쉬는 날은 「–」
    var valueText: String { kind == .off ? "–" : hoursText }

    /// 예: 「금요일 9일, 추가 5시간, 이번 요청」
    var accessibilityText: String {
        let head = "\(weekday)요일 \(day)일"
        let hours = extraShiftSpokenHours(hoursText)
        switch kind {
        case .off: return "\(head), 근무 없음"
        case .worked: return "\(head), \(hours)"
        case .thisRequest: return "\(head), 추가 \(hours.replacingOccurrences(of: "+", with: "")), 이번 요청"
        }
    }
}

nonisolated struct ExtraShiftOfferState: Equatable, Sendable {
    static let title = "추가 근무 요청"
    static let acceptTitle = "나갈게요"
    static let declineTitle = "어려워요"
    static let weekCardTitle = "그 주 내 근무"
    static let confirmNotice = "먼저 수락한 사람으로 확정되고, 수락하면 스케줄에 바로 추가돼요."

    /// 「종민김밥 본점 · 박민수 사장님 · 방금」
    var metaText: String
    /// 큰 제목 (줄바꿈 포함)
    var headline: String
    /// 「10월 9일 (금)」
    var dateText: String
    var holidayName: String?
    /// 「11:00 – 16:00」
    var timeText: String
    /// 「휴게 30분」 — 없으면 nil
    var breakText: String?
    var reason: String
    /// 서버 값 — 「81,000원」
    var expectedPayText: String
    /// 서버 값 — 「4.5h × 12,000 × 」 + 배율
    var payBasisText: String
    /// 서버 값 — 「1.5배」 (없으면 nil)
    var premiumText: String?
    var week: [ExtraShiftOfferDay]
    /// 서버 값 — 「이 주 13.5h → 18h · 금요일 저녁 근무(17–22)는 그대로예요」
    var weekSummary: String
    /// 함께 요청된 사람 이름들(없으면 안내 앞 문장을 숨긴다)
    var coRequestedNames: [String]
    private(set) var isResponding = false

    /// 「김하늘님에게도 함께 요청됐어요.」 — 없으면 nil
    var coRequestedText: String? {
        coRequestedNames.isEmpty ? nil : "\(coRequestedNames.joined(separator: ", "))님에게도 함께 요청됐어요."
    }

    /// 안내 전체 문장
    var noticeText: String {
        [coRequestedText, Self.confirmNotice].compactMap { $0 }.joined(separator: " ")
    }

    var dateAccessibilityText: String { "날짜, \(dateText)" + (holidayName.map { ", \($0)" } ?? "") }
    var payAccessibilityText: String {
        "예상 급여, \(expectedPayText), \(payBasisText)\(premiumText ?? "")"
            .replacingOccurrences(of: #"(\d)h"#, with: "$1시간", options: .regularExpression).replacingOccurrences(of: "×", with: "곱하기")
    }

    /// 수락 · 거절은 한 번만. 이미 처리 중이면 false
    mutating func beginRespond() -> Bool {
        guard !isResponding else { return false }
        isResponding = true
        return true
    }

    /// 실패했을 때만 풀린다(성공이면 잠근 채 호출한 쪽이 화면을 닫는다)
    mutating func endRespond() { isResponding = false }

    /// 원문 캡처 값
    static let sample = ExtraShiftOfferState(
        metaText: "종민김밥 본점 · 박민수 사장님 · 방금",
        headline: "10월 9일 한글날,\n11시–16시 나올 수 있어요?",
        dateText: "10월 9일 (금)", holidayName: "공휴일",
        timeText: "11:00 – 16:00", breakText: "휴게 30분",
        reason: "공휴일 영업",
        expectedPayText: "81,000원", payBasisText: "4.5h × 12,000 × ", premiumText: "1.5배",
        week: [
            .init(id: 0, weekday: "월", day: 5, kind: .worked, hoursText: "5h"),
            .init(id: 1, weekday: "화", day: 6, kind: .off, hoursText: ""),
            .init(id: 2, weekday: "수", day: 7, kind: .worked, hoursText: "5h"),
            .init(id: 3, weekday: "목", day: 8, kind: .off, hoursText: ""),
            .init(id: 4, weekday: "금", day: 9, kind: .thisRequest, hoursText: "+5h"),
            .init(id: 5, weekday: "토", day: 10, kind: .off, hoursText: ""),
            .init(id: 6, weekday: "일", day: 11, kind: .off, hoursText: ""),
        ],
        weekSummary: "이 주 13.5h → 18h · 금요일 저녁 근무(17–22)는 그대로예요",
        coRequestedNames: ["김하늘"])
}

/// 음성용 — 숫자 바로 뒤의 h만 「시간」으로(다른 글자의 h는 그대로)
nonisolated func extraShiftSpokenHours(_ text: String) -> String {
    text.replacingOccurrences(of: #"(\d)h"#, with: "$1시간", options: .regularExpression)
}
