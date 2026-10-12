// UI-IOS-10f · REQ-075 — 마감 후 정정: 원래 기록은 지우지 않고 정정(새 버전)으로
// 원래 시각 · 날짜 · 마감 상태 · 출처는 서버 값. 화면은 전 → 후만 보여 준다.
// 차액 계산 · 지급 시기는 이 화면에서 하지 않는다(REQ-075 미확정 — 차액 지급 시기 노무 검토).
import Foundation

nonisolated enum RecordCorrectionField: Sendable { case start, end }

/// 「다시 계산하기」로 부모에 넘기는 정정 값(서버가 새 버전으로 저장)
nonisolated struct RecordCorrection: Equatable, Sendable {
    var startMinute: Int
    var endMinute: Int
    var reason: String
}

nonisolated struct RecordCorrectionState: Equatable, Sendable {
    static let reasonLimit = 200
    /// 시트 간격 — 1af · 1i와 같은 1분
    static let pickerIntervalMinutes = 1

    // 서버 값
    var dateText: String
    var employeeName: String
    var statusText: String
    var lockText: String
    var sourceTitle: String
    var sourceSubtitle: String
    var originalStartMinute: Int
    var originalEndMinute: Int

    // 고친 값(처음엔 원래 값)
    var startMinute: Int
    var endMinute: Int
    /// 처리 중 — 두 번 보내기 방지
    private(set) var isSending = false

    // MARK: 문구 (원문 그대로)
    static let title = "근무 정정"
    static let contentSection = "정정 내용"
    static let reasonSection = "정정 사유 \u{00B7} 필수"
    static let sourceSection = "요청 출처"
    static let submitTitle = "다시 계산하기"
    static let footnote = "정정 전 기록은 이력으로 남아요"

    init(dateText: String, employeeName: String, statusText: String, lockText: String,
         sourceTitle: String, sourceSubtitle: String,
         originalStartMinute: Int, originalEndMinute: Int,
         startMinute: Int? = nil, endMinute: Int? = nil) {
        self.dateText = dateText
        self.employeeName = employeeName
        self.statusText = statusText
        self.lockText = lockText
        self.sourceTitle = sourceTitle
        self.sourceSubtitle = sourceSubtitle
        self.originalStartMinute = originalStartMinute
        self.originalEndMinute = originalEndMinute
        self.startMinute = startMinute ?? originalStartMinute
        self.endMinute = endMinute ?? originalEndMinute
    }

    var headline: String { "\(dateText) \u{00B7} \(employeeName)" }

    // MARK: 시각

    static func clock(_ minute: Int) -> String {
        let m = min(max(minute, 0), 1439)
        return String(format: "%02d:%02d", m / 60, m % 60)
    }
    var originalStartText: String { Self.clock(originalStartMinute) }
    var originalEndText: String { Self.clock(originalEndMinute) }
    var startText: String { Self.clock(startMinute) }
    var endText: String { Self.clock(endMinute) }

    var startChanged: Bool { startMinute != originalStartMinute }
    var endChanged: Bool { endMinute != originalEndMinute }
    var hasChange: Bool { startChanged || endChanged }
    /// 자정 넘김은 디자인에 없다 — 출근 < 퇴근(같은 날)만 인정
    var isOrderValid: Bool { startMinute < endMinute }

    func rowAccessibility(_ field: RecordCorrectionField) -> String {
        let label = field == .start ? "출근" : "퇴근"
        let original = field == .start ? originalStartMinute : originalEndMinute
        let now = field == .start ? startMinute : endMinute
        if now != original {
            return "\(label), \(PumTimeWheelMath.spokenText(original))에서 \(PumTimeWheelMath.spokenText(now))로"
        }
        return "\(label), \(PumTimeWheelMath.spokenText(now))"
    }
    var lockAccessibility: String { "\(lockText), 잠김" }
    var sourceAccessibility: String { "\(sourceTitle), \(sourceSubtitle)" }

    // MARK: 사유

    static func clampedReason(_ s: String) -> String {
        s.count > reasonLimit ? String(s.prefix(reasonLimit)) : s
    }
    static func hasReason(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: 보내기

    /// 바뀐 시각이 있고 순서가 맞고 사유가 비지 않을 때만
    func canRecalculate(reason: String) -> Bool {
        hasChange && isOrderValid && Self.hasReason(reason)
    }
    func correction(reason: String) -> RecordCorrection {
        RecordCorrection(startMinute: startMinute, endMinute: endMinute,
                         reason: reason.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// 보낼 수 있으면 true를 돌려주고 처리 중으로 바꾼다. 이미 처리 중이면 false.
    mutating func beginSend(reason: String) -> Bool {
        guard canRecalculate(reason: reason), !isSending else { return false }
        isSending = true
        return true
    }
    /// 실패일 때만 호출 — 성공이면 부모가 10g로 넘어가므로 잠긴 채 둔다
    mutating func endSend() { isSending = false }

    // MARK: C13

    /// 시트를 열 때 쓸 값(한 시각 모드 — 출근은 start, 퇴근은 end를 읽는다)
    var pickerValue: PumTimeRangeValue {
        var v = PumTimeRangeValue()
        v.startMinutes = startMinute
        v.endMinutes = endMinute
        v.dateText = dateText
        return v
    }
    func applying(picked: PumTimeRangeValue, field: RecordCorrectionField) -> RecordCorrectionState {
        var s = self
        switch field {
        case .start: s.startMinute = min(max(picked.startMinutes, 0), 1439)
        case .end: s.endMinute = min(max(picked.endMinutes, 0), 1439)
        }
        return s
    }
}

extension RecordCorrectionState {
    /// 디자인 10f 캡처(가짜 데이터) — 퇴근 22:00 → 23:00
    static let sample = RecordCorrectionState(
        dateText: "8월 28일 금", employeeName: "김하늘",
        statusText: "급여 지급 완료 \u{00B7} 명세서 발행됨", lockText: "8월 마감됨",
        sourceTitle: "김하늘 \u{00B7} 근무기록 수정 요청", sourceSubtitle: "10월 1일 \u{00B7} 마감 후 접수",
        originalStartMinute: 16 * 60 + 58, originalEndMinute: 22 * 60, endMinute: 23 * 60)

    static let sampleReason = "김하늘님 수정 요청 확인. 마감 청소로 1시간 더 근무함"
}
