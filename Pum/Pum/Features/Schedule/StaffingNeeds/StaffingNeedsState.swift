// UI-IOS-9a · REQ-051 — 사장님 · 필요 인력 입력(시간대별로 몇 명).
// 조건 칩 · 경고 문구 · 미입력 직원 이름은 서버 값 그대로 — 화면이 만들거나 바꾸지 않는다.
// REQ-051: 수당을 피하라는 추천 · 문구 · 강조를 만들지 않는다. 시각은 Asia/Seoul 벽시계 「하루 중 분」.
import Foundation

/// 주간 스트립의 하루 한 칸
nonisolated struct StaffingDay: Equatable, Sendable, Identifiable {
    /// 월 0 … 일 6
    var id: Int
    var month: Int
    var date: Int
    var short: String
    var long: String

    /// 「10월 17일 토요일」
    var spoken: String { "\(month)월 \(date)일 \(long)" }
}

/// 한 시간대의 필요 인원
nonisolated struct StaffingSlot: Equatable, Sendable, Identifiable {
    var id: Int
    /// StaffingDay.id
    var day: Int
    /// 하루 중 분
    var startMinutes: Int
    var endMinutes: Int
    var count: Int

    /// 「11:00 – 14:00」
    var rangeText: String {
        "\(PumTimeWheelMath.clockText(startMinutes)) \u{2013} \(PumTimeWheelMath.clockText(endMinutes))"
    }
    /// 「11:00부터 14:00까지」
    var spokenRange: String {
        "\(PumTimeWheelMath.clockText(startMinutes))부터 \(PumTimeWheelMath.clockText(endMinutes))까지"
    }
}

nonisolated struct StaffingNeedsState: Equatable, Sendable {
    static let title = "스케줄 추천"
    static let nextWeekTitle = "다음 주"
    static let addSlotTitle = "+ 시간대 추가"
    static let conditionsHeading = "계산에 반영하는 조건"
    static let requestTitle = "요청"
    static let recommendTitle = "스케줄 추천 받기"
    static let defaultMaxPerSlot = 10

    var weekText: String
    var days: [StaffingDay]
    var selectedDay: Int
    /// 모든 요일의 시간대
    var slots: [StaffingSlot]
    /// 한 시간대 인원 상한 — 서버가 준 값(원문엔 없음)
    var maxPerSlot: Int
    /// 서버가 준 조건 칩 글자(읽기 전용)
    var conditions: [String]
    /// 서버가 준 경고 머리 · 이름 · 설명. 머리가 없으면 카드를 그리지 않는다
    var missingTitle: String?
    var missingNames: String?
    var missingDetail: String?
    private(set) var isRecommending = false

    var selectedDayInfo: StaffingDay? { days.first { $0.id == selectedDay } }
    var selectedSlots: [StaffingSlot] { slots.filter { $0.day == selectedDay } }
    /// 「토요일 · 필요 인력」
    var sectionTitle: String { "\(selectedDayInfo?.long ?? "") \u{00B7} 필요 인력" }
    var canRecommend: Bool { !isRecommending }

    /// 경고 카드 둘째 줄 「김하늘 · 정우진 — 입력 전엔 기존 스케줄만 써요」
    var missingSubtitle: String? {
        guard let names = missingNames, let detail = missingDetail else { return missingDetail ?? missingNames }
        return "\(names) \u{2014} \(detail)"
    }

    func canDecrement(_ slot: StaffingSlot) -> Bool { slot.count > 0 }
    func canIncrement(_ slot: StaffingSlot) -> Bool { slot.count < maxPerSlot }

    mutating func select(day id: Int) {
        guard days.contains(where: { $0.id == id }) else { return }
        selectedDay = id
    }

    /// 인원을 바꾼다(0 ~ maxPerSlot 안으로). 바뀌면 true
    @discardableResult
    mutating func step(slot id: Int, by delta: Int) -> Bool {
        guard let i = slots.firstIndex(where: { $0.id == id }) else { return false }
        let next = min(max(slots[i].count + delta, 0), max(maxPerSlot, 0))
        guard next != slots[i].count else { return false }
        slots[i].count = next
        return true
    }

    /// 추천 요청은 한 번만 — 처리 중이면 false
    mutating func beginRecommend() -> Bool {
        guard canRecommend else { return false }
        isRecommending = true
        return true
    }
    mutating func endRecommend() { isRecommending = false }

    private static let weekdayNames: [(String, String)] = [
        ("월", "월요일"), ("화", "화요일"), ("수", "수요일"), ("목", "목요일"),
        ("금", "금요일"), ("토", "토요일"), ("일", "일요일"),
    ]

    /// 원문 캡처 값 — 토요일(17) 선택, 11–14 2명 · 14–18 3명 · 18–22 4명
    static let sample = StaffingNeedsState(
        weekText: "10월 12일 \u{2013} 18일",
        days: weekdayNames.enumerated().map {
            StaffingDay(id: $0.offset, month: 10, date: 12 + $0.offset, short: $0.element.0, long: $0.element.1)
        },
        selectedDay: 5,
        slots: [
            StaffingSlot(id: 1, day: 5, startMinutes: 11 * 60, endMinutes: 14 * 60, count: 2),
            StaffingSlot(id: 2, day: 5, startMinutes: 14 * 60, endMinutes: 18 * 60, count: 3),
            StaffingSlot(id: 3, day: 5, startMinutes: 18 * 60, endMinutes: 22 * 60, count: 4),
        ],
        maxPerSlot: defaultMaxPerSlot,
        conditions: ["근로계약", "소정근로시간", "기존 스케줄", "이번 주 누적", "근무 가능 시간",
                     "시급", "휴게", "연장\u{00B7}야간\u{00B7}휴일 가산", "사업장 5인 이상"],
        missingTitle: "근무 가능 시간 미입력 2명",
        missingNames: "김하늘 \u{00B7} 정우진",
        missingDetail: "입력 전엔 기존 스케줄만 써요"
    )
}
