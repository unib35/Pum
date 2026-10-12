// UI-IOS-1t · REQ-042 · REQ-050 — 사업장 스케줄(사장님): 주간 · 일별 근무 · 대타 요청 승인
// 인원 수 · 시간 · 주간 시간(23h → 28h) · 「부족」 여부는 서버 값 그대로 — 화면에서 계산하지 않는다.
import Foundation

/// 주간 스트립 한 칸
nonisolated struct ScheduleDay: Identifiable, Equatable, Sendable {
    /// 날짜(일)
    let id: Int
    /// 「월」
    let weekday: String
    /// 소리용 「10월 5일 월요일」
    let spoken: String
    /// 일하는 인원(서버)
    let headcount: Int
    /// 서버가 「인원 부족」으로 표시한 날 — 기준은 화면이 정하지 않는다
    let isShort: Bool
    /// 휴무일(일요일 등) — 인원 대신 「휴무」
    let isClosed: Bool
    let isSunday: Bool
    /// 선택하면 아래 줄에 나오는 제목(서버): 「10월 5일 월 · 4명 · 22시간」
    let title: String
    let groups: [ScheduleGroup]

    /// 칸 아래 글자
    var countText: String { isClosed ? "휴무" : "\(headcount)명" }

    func accessibilityLabel(selected: Bool) -> String {
        var s = "\(spoken), " + (isClosed ? "휴무" : "\(headcount)명")
        // 「선택됨」은 .isSelected 특성이 읽는다
        if isShort && !isClosed { s += ", 인원 부족" }
        return s
    }
}

/// 같은 시간대(예: 09:00–15:00) 근무자 묶음
nonisolated struct ScheduleGroup: Identifiable, Equatable, Sendable {
    let id: Int
    let start: String
    let end: String
    /// 「오전」 · 「오후」
    let period: String
    /// 서버 문구 「6h」
    let hours: String
    let people: [SchedulePerson]

    var periodText: String { "\(period) \u{00B7} \(hours)" }
}

nonisolated struct SchedulePerson: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let colorIndex: Int
    /// 「1h」 · 「30m」(서버)
    let breakText: String
    var breakLabel: String { "휴게 \(breakText)" }
    /// 낭독: 「1h」 → 「1시간」, 「30m」 → 「30분」(서버 표기 「Nh」 「Nm」 가정)
    var breakSpoken: String { "휴게 " + OwnerScheduleFormat.spokenDuration(breakText) }
}

/// 대타 요청 1건(REQ-042: 승인하면 담당자가 바뀐다)
nonisolated struct ScheduleSwapRequest: Equatable, Sendable {
    /// 「어제 21:40」(서버)
    let requestedAgo: String
    /// 「10월 12일 월」 · 소리 「10월 12일 월요일」
    let dateText: String
    let dateSpoken: String
    let start: String
    let end: String
    let fromName: String
    let fromColorIndex: Int
    let toName: String
    let toColorIndex: Int
    /// 그 주 새 담당자의 주간 시간(서버): 23 → 28
    let toWeekHoursBefore: Int
    let toWeekHoursAfter: Int

    var title: String { "대타 요청 1건" }
    var whenText: String { "\(dateText) \u{00B7} \(PumFormat.timeRange(start, end))" }
    var weekHoursText: String { "그 주 \(toName) \(toWeekHoursBefore)h \u{2192} \(toWeekHoursAfter)h" }

    var accessibilityText: String {
        "대타 요청, 승인 대기, \(dateSpoken) \(start)부터 \(end), \(fromName)에서 \(toName)으로, 그 주 \(toName) \(toWeekHoursBefore)시간에서 \(toWeekHoursAfter)시간"
    }
}

struct OwnerScheduleState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    /// 「10월 5일 – 11일」(서버, en dash)
    var weekTitle: String
    var days: [ScheduleDay]
    var selectedID: Int
    var swap: ScheduleSwapRequest?
    /// 탭 바 근무 배지 — 원문 탭 바에는 배지가 없다
    var workTabBadge = 0

    var selectedDay: ScheduleDay? { days.first { $0.id == selectedID } }

    /// 날짜 선택은 화면 상태만 바꾼다
    mutating func select(_ id: Int) {
        if days.contains(where: { $0.id == id }) { selectedID = id }
    }

    static let sample: OwnerScheduleState = {
        let morning = ScheduleGroup(id: 1, start: "09:00", end: "15:00", period: "오전", hours: "6h", people: [
            .init(id: 1, name: "최유나", colorIndex: 2, breakText: "1h"),
            .init(id: 2, name: "박서준", colorIndex: 3, breakText: "1h"),
        ])
        let evening = ScheduleGroup(id: 2, start: "17:00", end: "22:00", period: "오후", hours: "5h", people: [
            .init(id: 3, name: "이종민", colorIndex: 0, breakText: "30m"),
            .init(id: 4, name: "김하늘", colorIndex: 1, breakText: "30m"),
        ])
        func day(_ n: Int, _ wd: String, _ count: Int, short: Bool = false, closed: Bool = false,
                 title: String, groups: [ScheduleGroup] = []) -> ScheduleDay {
            .init(id: n, weekday: wd, spoken: "10월 \(n)일 \(wd)요일", headcount: count, isShort: short,
                  isClosed: closed, isSunday: wd == "일", title: title, groups: groups)
        }
        return OwnerScheduleState(
            workplaceName: "종민김밥 본점", workplaceInitial: "종",
            weekTitle: "10월 5일 \u{2013} 11일",
            days: [
                day(5, "월", 4, title: "10월 5일 월 \u{00B7} 4명 \u{00B7} 22시간", groups: [morning, evening]),
                day(6, "화", 2, title: "10월 6일 화 \u{00B7} 2명 \u{00B7} 16시간"),
                day(7, "수", 4, title: "10월 7일 수 \u{00B7} 4명 \u{00B7} 17시간"),
                day(8, "목", 1, short: true, title: "10월 8일 목 \u{00B7} 1명 \u{00B7} 6시간"),
                day(9, "금", 4, title: "10월 9일 금 \u{00B7} 4명 \u{00B7} 21시간"),
                day(10, "토", 3, title: "10월 10일 토 \u{00B7} 3명 \u{00B7} 18시간"),
                day(11, "일", 0, closed: true, title: "10월 11일 일 \u{00B7} 휴무"),
            ],
            selectedID: 5,
            swap: .init(requestedAgo: "어제 21:40", dateText: "10월 12일 월", dateSpoken: "10월 12일 월요일",
                        start: "17:00", end: "22:00", fromName: "이종민", fromColorIndex: 0,
                        toName: "박서준", toColorIndex: 3, toWeekHoursBefore: 23, toWeekHoursAfter: 28))
    }()
}

enum OwnerScheduleFormat {
    /// 「1h」 → 「1시간」, 「30m」 → 「30분」, 「6h」 → 「6시간」. 형식이 다르면 그대로
    nonisolated static func spokenDuration(_ s: String) -> String {
        if s.hasSuffix("h"), let n = Int(s.dropLast()) { return "\(n)시간" }
        if s.hasSuffix("m"), let n = Int(s.dropLast()) { return "\(n)분" }
        return s
    }
}
