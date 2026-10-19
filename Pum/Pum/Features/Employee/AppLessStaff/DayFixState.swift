// UI-IOS-20f · REQ-007 · DEC-001 — 하루 고치기 시트. 근무함 / 결근 / 쉬는 날 · 인정 시간 바로 계산 · 사업주 입력으로 남음.
// 인정 근무 · 가산 문구는 서버(엔진) 값 — 화면에서 시간 · 가산을 계산하지 않는다.
// 시간은 "HH:mm" 문자열, 휴게는 분 Int. 돈은 이 시트에 나오지 않는다.
import Foundation

nonisolated enum DayFixKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case worked, absent, dayOff
    var id: String { rawValue }
    var title: String {
        switch self {
        case .worked: "근무함"
        case .absent: "결근"
        case .dayOff: "쉬는 날"
        }
    }
}

/// 화면 초안(시트에서 사장님이 고치는 값)
nonisolated struct DayFixDraft: Equatable, Sendable {
    var kind: DayFixKind
    /// 하루 중 분(0 ..< 1440)
    var startMinutes: Int
    var endMinutes: Int
    var breakMinutes: Int
    var reason: String
}

/// 서버로 보낼 값 · 미리보기를 요청할 값
nonisolated struct DayFixInput: Equatable, Sendable {
    let dayID: String
    let kind: DayFixKind
    /// "16:00" — 근무함이 아니면 nil
    let start: String?
    let end: String?
    /// 휴게(분) — 근무함이 아니면 nil
    let breakMinutes: Int?
    let reason: String

    /// 인정 시간 · 가산에 영향을 주는 값만. 사유는 계산과 무관하므로 빼서, 사유를 쓰는 동안 미리보기가 사라지지 않게 한다.
    var calcKey: DayFixInput { DayFixInput(dayID: dayID, kind: kind, start: start, end: end, breakMinutes: breakMinutes, reason: "") }
}

/// 서버(엔진)가 입력에 대해 돌려준 미리보기 — `input`은 어떤 입력에 대한 값인지
nonisolated struct DayFixPreview: Equatable, Sendable {
    let input: DayFixInput
    /// 「5시간 30분」
    let recognizedText: String
    /// 읽기용 「5시간 30분」
    let recognizedReadout: String
    /// 「소정근로 초과 · 50% 가산」 — 없으면 nil
    let deltaDetail: String?
    /// 「+1시간」
    let deltaText: String
    /// 읽기용 「1시간 더」
    let deltaReadout: String
}

nonisolated struct DayFixState: Equatable, Sendable {
    static let startTitle = "출근"
    static let endTitle = "퇴근"
    static let breakTitle = "휴게"
    static let recognizedTitle = "인정 근무"
    static let deltaTitle = "예정보다"
    static let reasonTitle = "사유 · 선택"
    static let cancelTitle = "취소"
    static let saveTitle = "저장"
    /// 원문 없음 — 처리 중 버튼 문구
    static let savingTitle = "저장하는 중"
    static let footerNotice = "「사업주 입력」으로 남고, 초대하면 직원도 볼 수 있어요"
    /// 원문 없음 — 시간 고르기 시트 제목
    static let startPickerTitle = "출근 시각"
    static let endPickerTitle = "퇴근 시각"

    let dayID: String
    /// 「10월 7일 수」
    let dateTitle: String
    /// 「예정 17:00 – 22:00 · 휴게 30분」
    let plannedText: String
    let initialKind: DayFixKind
    /// "16:00"
    let initialStart: String
    let initialEnd: String
    let initialBreakMinutes: Int
    let initialReason: String
    /// 서버 미리보기 — 현재 입력과 같은 입력에 대한 것일 때만 보인다
    let preview: DayFixPreview?
    var isSolo = false

    var initialDraft: DayFixDraft {
        DayFixDraft(kind: initialKind,
                    startMinutes: Self.minutes(from: initialStart) ?? 0,
                    endMinutes: Self.minutes(from: initialEnd) ?? 0,
                    breakMinutes: initialBreakMinutes, reason: initialReason)
    }

    /// 근무함일 때만 시간 · 휴게 행이 있다
    static func showsTimes(_ draft: DayFixDraft) -> Bool { draft.kind == .worked }

    func input(_ draft: DayFixDraft) -> DayFixInput {
        let worked = Self.showsTimes(draft)
        return DayFixInput(dayID: dayID, kind: draft.kind,
                           start: worked ? Self.clock(draft.startMinutes) : nil,
                           end: worked ? Self.clock(draft.endMinutes) : nil,
                           breakMinutes: worked ? draft.breakMinutes : nil,
                           reason: draft.reason.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// 미리보기가 현재 입력에 대한 것일 때만(다르면 숨김 — 10a와 같은 원칙)
    func visiblePreview(for draft: DayFixDraft) -> DayFixPreview? {
        guard let preview, preview.input.calcKey == input(draft).calcKey else { return nil }
        return preview
    }

    func recognizedReadout(_ p: DayFixPreview) -> String { "\(Self.recognizedTitle), \(p.recognizedReadout)" }
    func deltaReadout(_ p: DayFixPreview) -> String {
        [Self.deltaTitle, p.deltaDetail, p.deltaReadout].compactMap { $0 }.joined(separator: ", ")
    }

    // MARK: 시각 · 휴게 글자

    static func clock(_ minutes: Int) -> String { PumTimeWheelMath.clockText(minutes) }

    /// "16:00" → 960. 형식이 다르면 nil
    static func minutes(from text: String) -> Int? {
        let parts = text.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]),
              (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        return h * 60 + m
    }

    /// 0 → 「없음」, 30 → 「30분」, 60 → 「1시간」 (시간 고르기 글자와 같다)
    static func breakText(_ minutes: Int) -> String {
        PumTimePickerStyle.breakChoices.first { $0.minutes == minutes }?.title ?? PumFormat.duration(minutes: minutes)
    }

    static func timeReadout(title: String, minutes: Int) -> String { "\(title), \(PumTimeWheelMath.spokenText(minutes))" }

    static let sample = DayFixState(
        dayID: "2026-10-07", dateTitle: "10월 7일 수",
        plannedText: "예정 \(PumFormat.timeRange("17:00", "22:00")) · 휴게 30분",
        initialKind: .worked, initialStart: "16:00", initialEnd: "22:00", initialBreakMinutes: 30,
        initialReason: "단체 예약으로 일찍 나옴",
        preview: DayFixPreview(
            input: DayFixInput(dayID: "2026-10-07", kind: .worked, start: "16:00", end: "22:00", breakMinutes: 30, reason: ""),
            recognizedText: "5시간 30분", recognizedReadout: "5시간 30분",
            deltaDetail: "소정근로 초과 · 50% 가산", deltaText: "+1시간", deltaReadout: "1시간 더"))
}
