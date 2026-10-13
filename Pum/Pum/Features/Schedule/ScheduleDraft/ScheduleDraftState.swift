// UI-IOS-17a · UI-IOS-17b · REQ-050 — 사장님 · 다음 주 초안 + 근무 추가 시트
// 인원 수 · 시간 · 인건비 · 가산 근거는 서버(엔진) 값 그대로 — 화면에서 시간 · 금액을 계산하지 않는다.
// 시트 입력(직원 · 시간 · 휴게 · 반복)만 화면 초안이고, 바뀌면 onDraftChange로 알리고 새 계산 값을 다시 받는다.
import Foundation

/// 주간 스트립 한 칸
nonisolated struct DraftDay: Identifiable, Equatable, Sendable {
    /// 날짜(일)
    let id: Int
    /// 「월」
    let weekday: String
    /// 소리용 「10월 5일 월요일」
    let spoken: String
    /// 「4명」(서버)
    let countText: String
    /// 빨간 날짜(일요일 · 공휴일 — 서버가 표시)
    let isRed: Bool

    func accessibilityLabel() -> String { "\(spoken), \(countText)" }
}

/// 근무 한 줄
nonisolated struct DraftShift: Identifiable, Equatable, Sendable {
    nonisolated enum Badge: String, Equatable, Sendable { case changed = "변경", added = "추가" }

    let id: Int
    let start: String
    let end: String
    let name: String
    let colorIndex: Int
    /// 회색 설명 「출근 09:00 → 10:00 · 휴게 30분」(서버)
    let note: String
    let badge: Badge?

    var badgeText: String? { badge?.rawValue }

    /// 「10:00부터 15:00, 최유나, 출근 09:00 → 10:00 · 휴게 30분, 변경」
    var accessibilityText: String {
        (["\(start)부터 \(end)", name, note] + (badgeText.map { [$0] } ?? [])).joined(separator: ", ")
    }
}

/// 시트에 고를 수 있는 직원
nonisolated struct DraftStaff: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let colorIndex: Int
}

nonisolated enum DraftTimeField: Equatable, Sendable { case start, end }

/// 시트 입력 초안 — 이 값이 바뀔 때마다 서버가 시간 · 인건비를 다시 계산해 보낸다
nonisolated struct AddShiftDraft: Equatable, Sendable {
    var staffID: Int
    /// 하루 중 분(0 ..< 1440)
    var startMinutes: Int
    var endMinutes: Int
    var breakMinutes: Int
    /// 반복 선택 칸 번호(0 = 이번만)
    var repeatIndex: Int
}

/// 서버가 계산한 「이 주 근무」 · 예상 인건비 — 글자 그대로 보여준다
nonisolated struct DraftEstimate: Equatable, Sendable {
    /// 「박서준 · 이 주 근무」
    let title: String
    /// 「23h → 27h 30m」
    let hoursText: String
    /// 「예상 인건비」
    let costLabel: String
    /// 「기본 49,500 · 소정근로 25h 초과 2.5h 가산 13,750」
    let basis: String
    /// 「+63,250원」
    let total: String

    var accessibilityText: String { "\(title), \(hoursText), \(costLabel) \(total), \(basis)" }
}

nonisolated struct AddShiftSheetState: Equatable, Sendable {
    static let staffLabel = "직원"
    static let startLabel = "출근"
    static let endLabel = "퇴근"
    static let breakLabel = "휴게"
    static let repeatLabel = "반복"
    static let addTitle = "초안에 추가"

    /// 「근무 추가 · 10월 7일 수」
    let title: String
    /// 「초안」
    let badge: String
    let staff: [DraftStaff]
    /// 휴게 고르기(분) — 서버 값
    let breakOptions: [Int]
    /// 「이번만」 · 「매주 수」
    let repeatOptions: [String]
    /// 시트 입력의 기준 값(처음 열릴 때 · 서버 새 값이 올 때 초안의 바탕)
    let initialDraft: AddShiftDraft
    /// 입력 중 칸(파란 테두리)
    let focusedField: DraftTimeField
    let estimate: DraftEstimate

    /// 540 → 「09:00」(입력 칸 글자)
    func clock(_ minutes: Int) -> String {
        let m = min(max(minutes, 0), 1439)
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    /// 휴게 칸 글자: 30 → 「30분」, 0 → 「없음」, 60 → 「1시간」
    func breakText(_ minutes: Int) -> String {
        if minutes == 0 { return "없음" }
        if minutes % 60 == 0 { return "\(minutes / 60)시간" }
        return "\(minutes)분"
    }

    func hasChanges(_ draft: AddShiftDraft) -> Bool { draft != initialDraft }
}

nonisolated struct ScheduleDraftState: Equatable, Sendable {
    static let title = "스케줄"
    static let draftBadge = "초안 \u{00B7} 직원에게 안 보임"
    static let addShiftTitle = "근무 추가"
    static let copyLastWeekTitle = "지난주 복사"
    static let publishTitle = "게시"

    var workplaceName: String
    var workplaceInitial: String
    /// 「10월 5일 – 11일」(서버, en dash)
    var weekTitle: String
    var days: [DraftDay]
    var selectedID: Int
    /// 「10월 7일 수 · 3명」(서버)
    var selectedTitle: String
    var shifts: [DraftShift]
    /// 「바뀐 것 3건 · 게시하면 직원 6명에게 알림」(서버)
    var footnote: String
    /// 탭 바 근무 배지
    var workTabBadge: Int
    /// 근무 추가 시트(있으면 처음부터 열림)
    var sheet: AddShiftSheetState?

    var selectedDay: DraftDay? { days.first { $0.id == selectedID } }

    /// 날짜 선택은 화면 상태만 바꾼다
    mutating func select(_ id: Int) {
        if days.contains(where: { $0.id == id }) { selectedID = id }
    }

    static let sample: ScheduleDraftState = {
        func day(_ n: Int, _ wd: String, _ count: Int, red: Bool = false) -> DraftDay {
            .init(id: n, weekday: wd, spoken: "10월 \(n)일 \(wd)요일", countText: "\(count)명", isRed: red)
        }
        return ScheduleDraftState(
            workplaceName: "종민김밥 본점", workplaceInitial: "종",
            weekTitle: "10월 5일 \u{2013} 11일",
            days: [day(5, "월", 4), day(6, "화", 2), day(7, "수", 3), day(8, "목", 3),
                   day(9, "금", 4, red: true), day(10, "토", 5), day(11, "일", 2, red: true)],
            selectedID: 7,
            selectedTitle: "10월 7일 수 \u{00B7} 3명",
            shifts: [
                .init(id: 1, start: "10:00", end: "15:00", name: "최유나", colorIndex: 2,
                      note: "출근 09:00 \u{2192} 10:00 \u{00B7} 휴게 30분", badge: .changed),
                .init(id: 2, start: "17:00", end: "22:00", name: "김하늘", colorIndex: 1,
                      note: "휴게 30분", badge: nil),
                .init(id: 3, start: "17:00", end: "22:00", name: "이종민", colorIndex: 0,
                      note: "휴게 30분", badge: .added),
            ],
            footnote: "바뀐 것 3건 \u{00B7} 게시하면 직원 6명에게 알림",
            workTabBadge: 4, sheet: nil)
    }()

    /// 17b — 17a 위에 근무 추가 시트가 열린 상태
    static let addingShift: ScheduleDraftState = {
        var s = sample
        s.sheet = .sample
        return s
    }()
}

nonisolated extension AddShiftSheetState {
    static let sample = AddShiftSheetState(
        title: "근무 추가 \u{00B7} 10월 7일 수", badge: "초안",
        staff: [
            .init(id: 1, name: "박서준", colorIndex: 3),
            .init(id: 2, name: "오세진", colorIndex: 4),
            .init(id: 3, name: "정다은", colorIndex: 3),
            .init(id: 4, name: "김하늘", colorIndex: 1),
        ],
        breakOptions: [0, 30, 60],
        repeatOptions: ["이번만", "매주 수"],
        initialDraft: .init(staffID: 1, startMinutes: 17 * 60, endMinutes: 22 * 60, breakMinutes: 30, repeatIndex: 0),
        focusedField: .end, // 원문: 퇴근 칸에 파란 테두리
        estimate: .init(title: "박서준 \u{00B7} 이 주 근무", hoursText: "23h \u{2192} 27h 30m",
                        costLabel: "예상 인건비",
                        basis: "기본 49,500 \u{00B7} 소정근로 25h 초과 2.5h 가산 13,750",
                        total: "+63,250원"))
}
