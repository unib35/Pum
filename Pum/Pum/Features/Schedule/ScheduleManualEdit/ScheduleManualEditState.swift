// UI-IOS-9d · REQ-051 — 사장님 · 직접 조정(금요일 스케줄 편집). 시간을 바꾸면 엔진이 즉시 재계산한다.
// 금액 · 내역 문구 · 인정 시간 · 필요 인원 줄은 서버(엔진) 값 그대로 — 화면에서 곱하거나 더하지 않는다.
// 막대 비율은 9시–23시 범위에 맞춰 그리기 위한 계산일 뿐이다.
// REQ-051: 수당을 피하라는 문구 · 강조를 만들지 않는다. 「소정근로 초과 가산」은 엔진 내역 문구다.
// 시각은 Asia/Seoul 벽시계 「하루 중 분」.
import Foundation

/// 한 직원의 한 날 근무(분). 결과의 계산 조건(basis)이 되는 값이기도 하다
nonisolated struct ManualEditShiftValue: Equatable, Sendable {
    var employeeId: Int
    var startMinutes: Int
    var endMinutes: Int
}

/// 타임라인 한 행
nonisolated struct ManualEditShift: Equatable, Sendable, Identifiable {
    var id: Int { employeeId }
    var employeeId: Int
    var name: String
    /// 아바타 색 고정 키(사람 ID 순환)
    var colorIndex: Int
    var startMinutes: Int
    var endMinutes: Int
    /// 편집 전 — 서버가 준 원래 근무. 되돌리기 기준
    var originalStart: Int
    var originalEnd: Int

    var value: ManualEditShiftValue { .init(employeeId: employeeId, startMinutes: startMinutes, endMinutes: endMinutes) }
    var isChanged: Bool { startMinutes != originalStart || endMinutes != originalEnd }

    /// 원래 근무보다 늘어난 구간들(연한 막대). 줄어든 구간은 막대 자체가 줄어든다
    var addedRanges: [Range<Int>] {
        var r: [Range<Int>] = []
        if startMinutes < originalStart { r.append(startMinutes ..< min(originalStart, endMinutes)) }
        if endMinutes > originalEnd { r.append(max(originalEnd, startMinutes) ..< endMinutes) }
        return r.filter { !$0.isEmpty }
    }

    /// VoiceOver — 「박서준, 오후 12시부터 오후 10시까지, 오후 7시부터 오후 10시 추가됨」
    var spoken: String {
        var s = "\(name), \(PumTimeWheelMath.spokenText(startMinutes))부터 \(PumTimeWheelMath.spokenText(endMinutes))까지"
        for a in addedRanges {
            s += ", \(PumTimeWheelMath.spokenText(a.lowerBound))부터 \(PumTimeWheelMath.spokenText(a.upperBound)) 추가됨"
        }
        return s
    }
}

/// 엔진이 준 재계산 결과 — 계산 조건(basis)과 함께 온다
nonisolated struct ScheduleManualEditResult: Equatable, Sendable {
    struct Line: Equatable, Sendable {
        var title: String
        /// 「인정 +2.5h」 · 「27,500원」 — 서버 문자열
        var valueText: String
    }

    /// 이 결과를 계산한 근무 상태(바뀐 사람 포함 전체)
    var basis: [ManualEditShiftValue]
    /// 「박서준 · 금 +3시간」
    var title: String
    /// 「12–19 → 12–22」
    var rangeText: String
    /// 정수 원 — 서버 값
    var beforeWon: Int
    var afterWon: Int
    var deltaWon: Int
    var lines: [Line]
    /// 「오전 1」 「오후 2」 「저녁 3 ✓」
    var needs: [String]

    var beforeText: String { PumFormat.amount(beforeWon) }
    var afterText: String { "\(PumFormat.amount(afterWon))원" }
    /// 부호는 서버가 준 증감 값의 부호
    var deltaText: String { (deltaWon >= 0 ? "+" : "\u{2212}") + PumFormat.amount(abs(deltaWon)) }
    /// VoiceOver — 「1,241,000원에서 1,287,000원, 46,000원 늘어남」
    var spoken: String {
        let change = deltaWon >= 0 ? "늘어남" : "줄어듦"
        return "\(beforeText)원에서 \(afterText), \(PumFormat.amount(abs(deltaWon)))원 \(change)"
    }
}

nonisolated struct ScheduleManualEditState: Equatable, Sendable {
    static let timeTicks = [9, 12, 15, 18, 21, 23]
    static let needLabel = "필요"
    static let revertTitle = "되돌리기"
    /// 타임라인이 그리는 하루 범위(분)
    static let axisStart = 9 * 60
    static let axisEnd = 23 * 60

    var days: [StaffingDay]
    var selectedDay: Int
    var shifts: [ManualEditShift]
    /// 서버가 준 기본 필요 인원 줄(편집 전 스케줄 기준). 결과가 현재일 때는 결과의 줄을 쓴다
    var needs: [String]
    /// 마지막으로 받은 엔진 결과
    var result: ScheduleManualEditResult?
    private(set) var isApplying = false

    // MARK: 문구

    var title: String { "\(selectedDayInfo?.long ?? "") 스케줄 편집" }
    var selectedDayInfo: StaffingDay? { days.first { $0.id == selectedDay } }

    // MARK: 바뀐 사람 · 결과 보임 규칙

    /// 바뀐 사람(여럿이면 첫 사람)
    var changedShift: ManualEditShift? { shifts.first { $0.isChanged } }
    var hasChange: Bool { changedShift != nil }
    var currentBasis: [ManualEditShiftValue] { shifts.map(\.value) }
    /// 결과가 있고 계산 조건이 지금 편집 상태와 같을 때만 true
    var resultIsCurrent: Bool { result?.basis == currentBasis }
    var visibleResult: ScheduleManualEditResult? { resultIsCurrent ? result : nil }
    var displayedNeeds: [String] { visibleResult?.needs ?? needs }

    /// 카드 이름 줄 — 결과가 현재면 서버 문구, 아니면 이름만
    var cardTitle: String? {
        guard let c = changedShift else { return nil }
        return visibleResult?.title ?? "\(c.name) \u{00B7} \(selectedDayInfo?.short ?? "")"
    }

    var canRevert: Bool { hasChange && !isApplying }
    var canApply: Bool { hasChange && resultIsCurrent && !isApplying }
    /// 「적용 · 박서준에게 요청」 — 이름은 바뀐 사람
    var applyTitle: String {
        guard let c = changedShift else { return "적용" }
        return "적용 \u{00B7} \(c.name)에게 요청"
    }

    // MARK: 변경

    /// 근무를 바꾼다. 시작 < 끝일 때만. 바뀌면 true
    @discardableResult
    mutating func setRange(employeeId: Int, start: Int, end: Int) -> Bool {
        guard start < end, let i = shifts.firstIndex(where: { $0.employeeId == employeeId }) else { return false }
        guard shifts[i].startMinutes != start || shifts[i].endMinutes != end else { return false }
        shifts[i].startMinutes = start
        shifts[i].endMinutes = end
        return true
    }

    /// 편집 전으로. 바뀐 게 있었으면 true
    @discardableResult
    mutating func revert() -> Bool {
        guard hasChange else { return false }
        for i in shifts.indices {
            shifts[i].startMinutes = shifts[i].originalStart
            shifts[i].endMinutes = shifts[i].originalEnd
        }
        return true
    }

    mutating func select(day id: Int) {
        guard days.contains(where: { $0.id == id }) else { return }
        selectedDay = id
    }

    /// 적용은 한 번만 — 처리 중이면 false
    mutating func beginApply() -> Bool {
        guard canApply else { return false }
        isApplying = true
        return true
    }
    mutating func endApply() { isApplying = false }

    // MARK: 막대 그리기 (9시–23시 범위 비율)

    /// 시작 · 끝(분)을 0…1 비율로. 범위 밖은 잘라내고, 비면 nil
    static func barFraction(start: Int, end: Int) -> ClosedRange<Double>? {
        let lo = min(max(start, axisStart), axisEnd), hi = min(max(end, axisStart), axisEnd)
        guard lo < hi else { return nil }
        let span = Double(axisEnd - axisStart)
        return (Double(lo - axisStart) / span) ... (Double(hi - axisStart) / span)
    }

    /// 눈금(시) 위치 비율
    static func tickFraction(hour: Int) -> Double {
        Double(min(max(hour * 60, axisStart), axisEnd) - axisStart) / Double(axisEnd - axisStart)
    }

    // MARK: 원문 값

    private static let weekdayNames: [(String, String)] = [
        ("월", "월요일"), ("화", "화요일"), ("수", "수요일"), ("목", "목요일"),
        ("금", "금요일"), ("토", "토요일"), ("일", "일요일"),
    ]

    static let sampleDays: [StaffingDay] = weekdayNames.enumerated().map {
        StaffingDay(id: $0.offset, month: 10, date: 12 + $0.offset, short: $0.element.0, long: $0.element.1)
    }

    /// 원문 캡처 값 — 금(16) 선택, 박서준 12–19 → 12–22로 바뀐 상태 · 결과 basis 일치
    static let sample: ScheduleManualEditState = {
        func shift(_ id: Int, _ name: String, _ s: Int, _ e: Int, orig: Int? = nil) -> ManualEditShift {
            ManualEditShift(employeeId: id, name: name, colorIndex: id, startMinutes: s * 60, endMinutes: e * 60,
                            originalStart: s * 60, originalEnd: (orig ?? e) * 60)
        }
        // 막대 위치는 원문 캡처 실측(최유나 9–15 · 이종민 김하늘 17–22)
        let shifts = [
            shift(1, "최유나", 9, 15), shift(2, "박서준", 12, 22, orig: 19),
            shift(3, "이종민", 17, 22), shift(4, "김하늘", 17, 22),
        ]
        let needs = ["오전 1", "오후 2", "저녁 3 \u{2713}"]
        let result = ScheduleManualEditResult(
            basis: shifts.map(\.value), title: "박서준 \u{00B7} 금 +3시간", rangeText: "12\u{2013}19 \u{2192} 12\u{2013}22",
            beforeWon: 1_241_000, afterWon: 1_287_000, deltaWon: 46_000,
            lines: [
                .init(title: "근무 +3h \u{00B7} 휴게 30분 \u{2192} 1시간(8h 이상)", valueText: "인정 +2.5h"),
                .init(title: "기본급 2.5h \u{00D7} 11,000", valueText: "27,500원"),
                .init(title: "소정근로 초과 가산 \u{00B7} 2.5h \u{00D7} 5,500", valueText: "13,750원"),
                .init(title: "사업주 부담 4대보험 \u{00B7} 약", valueText: "4,750원"),
            ],
            needs: needs)
        return ScheduleManualEditState(days: sampleDays, selectedDay: 4, shifts: shifts, needs: needs, result: result)
    }()
}
