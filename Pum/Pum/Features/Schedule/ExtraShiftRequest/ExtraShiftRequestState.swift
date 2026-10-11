// UI-IOS-2j · REQ-043 — 사장님 · 추가 근무 요청 (원래 근무일이 아닌 날)
// 날짜 · 시간 · 인정 시간 · 가산 배율 · 직원별 주간 시간 · 시급은 서버/엔진 값 — 화면에서 계산하지 않는다.
// REQ-051: 직원 행에 수당 회피를 유도하는 추천 · 강조 · 경고를 만들지 않는다(원문 문구만 서버 값으로 표시).
import Foundation

nonisolated enum ExtraShiftPremium: Equatable, Sendable { case none, holiday, custom }

nonisolated enum ExtraShiftReason: CaseIterable, Sendable {
    case holidayOpen, groupBooking, festival, vacancy, other

    var title: String {
        switch self {
        case .holidayOpen: "공휴일 영업"
        case .groupBooking: "단체 예약"
        case .festival: "명절"
        case .vacancy: "결원 대체"
        case .other: "기타"
        }
    }
}

nonisolated struct ExtraShiftCandidate: Equatable, Identifiable, Sendable {
    let id: Int
    var name: String
    var colorIndex: Int
    /// 서버 값 — 예: 「그 주 13.5h → 18h」, 「그 주 이미 28h」
    var weekText: String
    /// 시급(원, 정수)
    var hourlyWon: Int
    var isSelected: Bool

    var detailText: String { "\(weekText) · \(ExtraShiftFormat.won(hourlyWon))원/h" }

    /// 예: 「이종민, 그 주 13.5시간에서 18시간, 시급 12,000원, 선택됨」
    var accessibilityText: String {
        let week = weekText.replacingOccurrences(of: "h", with: "시간").replacingOccurrences(of: " → ", with: "에서 ")
        return "\(name), \(week), 시급 \(ExtraShiftFormat.won(hourlyWon))원, \(isSelected ? "선택됨" : "선택 안 됨")"
    }
}

nonisolated enum ExtraShiftFormat {
    /// 정수 원 → 천 단위 쉼표 (부동소수점 없음)
    static func won(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (i, ch) in digits.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return (value < 0 ? "-" : "") + String(out.reversed())
    }
}

nonisolated struct ExtraShiftRequestState: Equatable, Sendable {
    static let title = "추가 근무 요청"
    static let notice = "수락하면 그 날 스케줄에 추가되고 평소처럼 출퇴근해요. 거절해도 불이익 표시는 남지 않아요."

    /// 「10월 9일 (금)」
    var dateText: String
    /// 공휴일 이름(서버 값). nil이면 숨김
    var holidayName: String?
    var startText: String
    var endText: String
    /// 「30분」
    var breakText: String
    /// 「인정 4시간 30분」 — 엔진 값. nil이면 숨김
    var recognizedText: String?
    var premium: ExtraShiftPremium
    /// 「휴일 1.5배」 — 규칙 값
    var holidayPremiumTitle: String
    var reason: ExtraShiftReason?
    /// 필요 인원(서버 값)
    var neededCount: Int
    var candidates: [ExtraShiftCandidate]
    private(set) var isSending = false

    init(dateText: String, holidayName: String?, startText: String, endText: String,
         breakText: String, recognizedText: String?, premium: ExtraShiftPremium,
         holidayPremiumTitle: String, reason: ExtraShiftReason?, neededCount: Int,
         candidates: [ExtraShiftCandidate]) {
        self.dateText = dateText; self.holidayName = holidayName
        self.startText = startText; self.endText = endText
        self.breakText = breakText; self.recognizedText = recognizedText
        self.premium = premium; self.holidayPremiumTitle = holidayPremiumTitle
        self.reason = reason; self.neededCount = neededCount; self.candidates = candidates
    }

    var selectedCount: Int { candidates.filter(\.isSelected).count }
    var sendTitle: String { "\(selectedCount)명에게 요청 보내기" }
    var canSend: Bool { selectedCount > 0 && !isSending }
    var recipientsLead: String { "누구에게 보낼까요" }
    var recipientsTail: String { " · \(neededCount)명 필요 · 먼저 수락한 사람으로 확정" }

    mutating func toggle(candidate id: Int) {
        guard let i = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[i].isSelected.toggle()
    }

    mutating func toggle(reason r: ExtraShiftReason) { reason = (reason == r) ? nil : r }

    mutating func setPremium(_ p: ExtraShiftPremium) { premium = p }

    /// 보내기는 한 번만 — 처리 중이면 false
    mutating func beginSend() -> Bool {
        guard canSend else { return false }
        isSending = true
        return true
    }
    mutating func endSend() { isSending = false }

    /// 2j 원문 캡처 값
    static let sample = ExtraShiftRequestState(
        dateText: "10월 9일 (금)", holidayName: "한글날",
        startText: "11:00", endText: "16:00",
        breakText: "30분", recognizedText: "인정 4시간 30분",
        premium: .holiday, holidayPremiumTitle: "휴일 1.5배",
        reason: .holidayOpen, neededCount: 1,
        candidates: [
            .init(id: 1, name: "이종민", colorIndex: 0, weekText: "그 주 13.5h → 18h", hourlyWon: 12_000, isSelected: true),
            .init(id: 2, name: "김하늘", colorIndex: 1, weekText: "그 주 15h → 19.5h", hourlyWon: 11_500, isSelected: true),
            .init(id: 3, name: "박서준", colorIndex: 3, weekText: "그 주 이미 28h", hourlyWon: 11_000, isSelected: false),
        ])
}
