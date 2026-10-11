// UI-IOS-1af · REQ-027 · DEC-005 — 근무기록 직접 추가: 사장님이 수기로 입력
// 직접 입력은 「사업주 입력」으로 표시되고 직원에게 알림이 간다. 사유 필수, 확정 전 삭제 가능(REQ-027).
// 「인정 근무 · 기본급 · 예정 없는 근무」는 서버(급여 엔진) 미리보기 값을 그대로 보여 준다 — 화면에서 계산하지 않는다.
// 입력(직원 · 날짜 · 시간 · 휴게)이 바뀌면 이전 미리보기는 버린다(새 값은 서버 재조회 후 — 연결 후속).
import Foundation

nonisolated enum OwnerManualEntryField: Sendable { case start, end }

nonisolated enum OwnerManualEntryBreak: CaseIterable, Sendable {
    case none, thirty, sixty

    var title: String {
        switch self {
        case .none: "없음"
        case .thirty: "30분"
        case .sixty: "1시간"
        }
    }
    var minutes: Int {
        switch self {
        case .none: 0
        case .thirty: 30
        case .sixty: 60
        }
    }
}

nonisolated enum OwnerManualEntryReason: CaseIterable, Sendable {
    case missingRecord, appError, urgentCall, other

    var title: String {
        switch self {
        case .missingRecord: "출퇴근 기록 누락"
        case .appError: "앱 오류"
        case .urgentCall: "급한 호출"
        case .other: "기타"
        }
    }
}

/// 서버(엔진)가 준 미리보기 — 값이 없으면 nil(화면에서 계산하지 않음)
nonisolated struct OwnerManualEntryPreview: Equatable, Sendable {
    /// 예: 「4시간 30분」
    var workText: String
    /// 기본급(원, 정수)
    var basePay: Int
    /// 예: 「예정 없는 근무」
    var note: String
}

nonisolated struct OwnerManualEntryDraft: Equatable, Sendable {
    static let reasonLimit = 200
    /// 시간 칸 조절(접근성 증가·감소) 한 번에 움직이는 분 — 디자인 없음
    static let stepMinutes = 10

    /// 직원 이름 · 아바타 색 번호. nil이면 아직 안 고른 것
    var employeeName: String?
    var employeeColorIndex = 0
    /// 「10월 4일 (일)」 — 날짜 문구는 서버/모델 값. nil이면 아직 안 고른 것
    var dateText: String?
    /// 하루 안의 분
    var startMinute: Int
    var endMinute: Int
    var selectedField: OwnerManualEntryField = .start
    var breakOption: OwnerManualEntryBreak = .none
    var reasonChip: OwnerManualEntryReason?
    var reasonText = ""
    var preview: OwnerManualEntryPreview?
    /// 보내는 중 — 두 번 보내기 방지
    private(set) var isSending = false

    // MARK: 문구 (원문 그대로)

    static let title = "근무기록 추가"
    static let notice = (lead: "직접 추가한 기록은 ", strong: "\"사업주 입력\"",
                         tail: "으로 표시되고 직원에게 알림이 가요. 직원이 이의를 제기하면 수정 요청으로 이어져요.")
    static let submitTitle = "기록 추가 \u{00B7} 직원에게 알림"

    var startText: String { OwnerManualEntryFormat.clock(startMinute) }
    var endText: String { OwnerManualEntryFormat.clock(endMinute) }
    /// 퇴근이 출근보다 이르면 다음 날 퇴근으로 본다는 디자인은 없다 — 표시는 원문대로 두고 플래그만 둔다
    var endsNextDay: Bool { endMinute < startMinute }

    var previewWorkLine: String? { preview.map { "인정 근무 \($0.workText)" } }
    var previewPayText: String? { preview.map { "기본급 \(PumFormat.amount($0.basePay))원" } }
    var previewNoteText: String? { preview.map { " \u{00B7} \($0.note)" } }

    // MARK: 사유

    var reasonCount: Int { reasonText.count }
    var hasReasonText: Bool { !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    /// 사유 필수(REQ-027) — 칩 또는 문장 중 하나
    var hasReason: Bool { reasonChip != nil || hasReasonText }

    /// 비활성 이유 문구는 디자인에 없다(충돌 #30)
    var canSubmit: Bool { employeeName != nil && dateText != nil && hasReason }

    static func clampedReason(_ s: String) -> String {
        s.count > reasonLimit ? String(s.prefix(reasonLimit)) : s
    }

    // MARK: 접근성 문구

    func timeAccessibility(_ field: OwnerManualEntryField) -> String {
        let on = selectedField == field
        let label = field == .start ? "출근" : "퇴근"
        let value = field == .start ? startText : endText
        return "\(label), \(value)" + (on ? ", 선택됨" : "")
    }
    var employeeAccessibility: String { "직원, \(employeeName ?? "선택 안 됨")" }
    var dateAccessibility: String { "날짜, \(dateText ?? "선택 안 됨")" }
    var previewAccessibility: String? {
        guard let preview else { return nil }
        return "인정 근무 \(preview.workText), 기본급 \(PumFormat.amount(preview.basePay))원, \(preview.note)"
    }

    // MARK: 바꾸기 — 입력이 바뀌면 미리보기를 비운다

    mutating func setEmployee(name: String, colorIndex: Int) {
        employeeName = name; employeeColorIndex = colorIndex; preview = nil
    }
    mutating func setDate(_ text: String) { dateText = text; preview = nil }
    mutating func setBreak(_ option: OwnerManualEntryBreak) {
        guard option != breakOption else { return }
        breakOption = option; preview = nil
    }
    mutating func select(_ field: OwnerManualEntryField) { selectedField = field }
    mutating func setTime(_ field: OwnerManualEntryField, minute: Int) {
        let m = ((minute % 1440) + 1440) % 1440
        switch field {
        case .start: startMinute = m
        case .end: endMinute = m
        }
        preview = nil
    }
    mutating func step(_ field: OwnerManualEntryField, by delta: Int) {
        setTime(field, minute: (field == .start ? startMinute : endMinute) + delta)
    }
    /// 사유 칩은 누르면 고르고, 다시 누르면 푼다(문장만으로도 보낼 수 있다)
    mutating func toggleReason(_ reason: OwnerManualEntryReason) {
        reasonChip = reasonChip == reason ? nil : reason
    }

    // MARK: 보내기 — 처리 중에는 다시 못 보낸다

    /// 보낼 수 있으면 true를 돌려주고 처리 중으로 바꾼다. 이미 처리 중이면 false.
    mutating func beginSend() -> Bool {
        guard canSubmit, !isSending else { return false }
        isSending = true
        return true
    }
    mutating func endSend() { isSending = false }
}

nonisolated enum OwnerManualEntryFormat {
    static func clock(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }
}

extension OwnerManualEntryDraft {
    /// 실제 진입 기본값: 직원 · 날짜 비어 있음, 사유 없음, 휴게 「없음」. 시간은 디자인에 없어 09:00–18:00(임시)
    static let initial = OwnerManualEntryDraft(startMinute: 9 * 60, endMinute: 18 * 60)

    /// 디자인 1af 캡처(가짜 데이터) — 출근 칸 선택 강조
    static let sample = OwnerManualEntryDraft(
        employeeName: "이종민", employeeColorIndex: 0, dateText: "10월 4일 (일)",
        startMinute: 13 * 60, endMinute: 18 * 60, selectedField: .start, breakOption: .thirty,
        reasonChip: .missingRecord,
        reasonText: "일요일 단체 주문 때문에 급하게 불렀어요. 종민이가 폰을 두고 와서 기록 못 함.",
        preview: OwnerManualEntryPreview(workText: "4시간 30분", basePay: 54_000, note: "예정 없는 근무")
    )
}
