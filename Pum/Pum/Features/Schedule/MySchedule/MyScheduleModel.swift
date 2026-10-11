// UI-IOS-1j · REQ-042 — 내 스케줄 목록 + 대타 요청 시트 데이터
// 시간 · 상태 문구는 모델 값으로 만들고, 화면은 그대로 보여 준다. 요청은 승인되기 전까지 예정대로 보인다(REQ-042).
import Foundation

/// 목록 · 달력 보기 전환(달력은 후속 이슈)
nonisolated enum MyScheduleMode: CaseIterable, Equatable, Sendable {
    case list, calendar

    var title: String {
        switch self {
        case .list: "목록"
        case .calendar: "달력"
        }
    }
}

/// 스케줄 한 칸(근무 하나)
nonisolated struct ScheduleItem: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case normal
        /// 오늘 — 요일 자리에 「오늘」, 오른쪽에 상태 배지(출근 전)
        case today(statusText: String)
        /// 변경됨 — 기존 시간을 보조 줄에 보여 준다
        case changed(originalStart: String, originalEnd: String)
        /// 대타 요청 중 — 승인 전까지 예정대로(REQ-042)
        case substituteRequested(statusText: String)
    }

    let id: Int
    let month: Int
    let day: Int
    /// 「월」「화」… 한 글자
    let weekday: String
    let start: String
    let end: String
    let workplace: String
    var breakMinutes: Int?
    var kind: Kind = .normal

    static let changedText = "변경됨"
    static let todayText = "오늘"

    var timeRange: String { PumFormat.timeRange(start, end) }
    var weekdayLong: String { weekday + "요일" }
    var dateText: String { "\(month)월 \(day)일 \(weekdayLong)" }

    var isToday: Bool { if case .today = kind { true } else { false } }
    var isChanged: Bool { if case .changed = kind { true } else { false } }
    var isSubstituteRequested: Bool { if case .substituteRequested = kind { true } else { false } }

    /// 오른쪽 끝 꺾쇠: 오늘 · 대타 요청 중은 배지가 대신한다
    var showsChevron: Bool { badge == nil }

    var badge: (text: String, kind: PumBadge.Kind)? {
        switch kind {
        case .today(let t): (t, .waiting)
        case .substituteRequested(let t): (t, .attention)
        default: nil
        }
    }

    /// 아래 줄: 「종민김밥 본점 · 휴게 30분」「종민김밥 본점 · 기존 17:00 – 22:00」
    var subtitle: String {
        var parts = [workplace]
        if case .changed(let s, let e) = kind { parts.append("기존 " + PumFormat.timeRange(s, e)) }
        if case .today = kind, let b = breakMinutes { parts.append("휴게 \(b)분") }
        return parts.joined(separator: " · ")
    }

    /// VoiceOver 한 문장
    var accessibilityLabel: String {
        var parts: [String] = []
        if isToday { parts.append(Self.todayText) }
        parts.append(dateText)
        parts.append("\(start)부터 \(end)")
        switch kind {
        case .normal:
            parts.append(workplace)
        case .today(let t):
            parts.append(t)
            parts.append(workplace)
            if let b = breakMinutes { parts.append("휴게 \(b)분") }
        case .changed(let s, let e):
            parts.append(Self.changedText)
            parts.append("기존 \(s)부터 \(e)")
        case .substituteRequested(let t):
            parts.append(t)
            parts.append(workplace)
        }
        return parts.joined(separator: ", ")
    }
}

nonisolated struct ScheduleSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let items: [ScheduleItem]
}

/// 시트에 보이는 신청 직원 한 명
nonisolated struct SubstituteApplicant: Equatable, Sendable {
    let name: String
    /// 「어제 21:40 신청」 — 서버가 준 문구
    let requestedText: String
    /// C7 팔레트 색 번호(같은 사람은 항상 같은 색)
    let colorIndex: Int

    var statusLine: String { requestedText + " · 사장님 승인을 기다리고 있어요" }
}

/// 대타 요청 시트 내용
nonisolated struct SubstituteRequest: Equatable, Sendable {
    let item: ScheduleItem
    let statusText: String
    let applicants: [SubstituteApplicant]
    let reason: String

    static let heading = "대타 요청"
    static let reasonLabel = "요청 사유"
    static let cancelTitle = "대타 요청 취소"

    /// 「10월 12일 월 · 17:00 – 22:00」
    var title: String { "\(item.month)월 \(item.day)일 \(item.weekday) · \(item.timeRange)" }
    var titleAccessibility: String { "\(Self.heading), \(item.dateText), \(item.start)부터 \(item.end)" }
    var applicantsHeader: String { "신청한 직원 \(applicants.count)명" }

    /// 승인되면 담당자가 바뀌고 내 스케줄에서 사라진다는 안내
    var notice: String {
        let who = applicants.first?.name ?? "신청한 직원"
        return "승인되면 이 근무의 담당자가 \(who)\(Self.toParticle(who)) 바뀌고, 내 스케줄에서 사라져요."
    }

    /// 「박서준으로」 — 받침 없으면 「로」, 있으면 「으로」(ㄹ 받침은 「로」)
    static func toParticle(_ name: String) -> String {
        guard let last = name.unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else { return "로" }
        let jong = (last.value - 0xAC00) % 28
        return (jong == 0 || jong == 8) ? "로" : "으로"
    }
}

nonisolated struct MyScheduleState: Equatable, Sendable {
    var sections: [ScheduleSection]
    var substitute: SubstituteRequest?

    /// 디자인 1j 예시 값(가짜)
    static let sample: MyScheduleState = {
        let shop = "종민김밥 본점"
        let next = ScheduleItem(id: 5, month: 10, day: 12, weekday: "월", start: "17:00", end: "22:00", workplace: shop,
                                kind: .substituteRequested(statusText: "대타 요청 중"))
        return MyScheduleState(
            sections: [
                ScheduleSection(id: "thisWeek", title: "이번 주 · 10월 첫째 주", items: [
                    ScheduleItem(id: 1, month: 10, day: 5, weekday: "월", start: "17:00", end: "22:00", workplace: shop),
                    ScheduleItem(id: 2, month: 10, day: 6, weekday: "화", start: "17:00", end: "22:00", workplace: shop,
                                 breakMinutes: 30, kind: .today(statusText: "출근 전")),
                    ScheduleItem(id: 3, month: 10, day: 7, weekday: "수", start: "17:00", end: "22:00", workplace: shop),
                    ScheduleItem(id: 4, month: 10, day: 9, weekday: "금", start: "18:00", end: "23:00", workplace: shop,
                                 kind: .changed(originalStart: "17:00", originalEnd: "22:00")),
                ]),
                ScheduleSection(id: "nextWeek", title: "다음 주", items: [
                    next,
                    ScheduleItem(id: 6, month: 10, day: 14, weekday: "수", start: "17:00", end: "22:00", workplace: shop),
                ]),
            ],
            substitute: SubstituteRequest(
                item: next, statusText: "승인 대기",
                applicants: [SubstituteApplicant(name: "박서준", requestedText: "어제 21:40 신청", colorIndex: 3)],
                reason: "학교 시험 기간이라 근무가 어렵습니다."))
    }()
}
