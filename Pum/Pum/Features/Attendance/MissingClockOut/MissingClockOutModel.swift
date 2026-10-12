// UI-IOS-1al · REQ-025 · DEC-004 · DEC-005 — 퇴근 미확정: 다음날 아침 실제 퇴근시간을 입력해 사장님께 확인 요청
// 인정 시간 · 금액은 서버(엔진)가 준 값을 그대로 보여 준다 — 화면에서 계산하지 않는다.
// 여기서 하는 것: 입력 시각 − 예정 퇴근(분), 세션 종료 시각(예정 퇴근 + 6시간), 알림 시각 문구뿐.
import Foundation

nonisolated enum MissingClockOutReason: CaseIterable, Sendable {
    case forgot, appUnavailable, other

    var title: String {
        switch self {
        case .forgot: "퇴근 기록을 깜빡했어요"
        case .appUnavailable: "앱을 사용할 수 없었어요"
        case .other: "기타 (직접 입력)"
        }
    }
}

nonisolated enum MissingClockOutField: Sendable { case hour, minute }

nonisolated struct MissingClockOutState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    /// 「어제 · 10월 3일 토」 — 날짜 문구는 서버/모델 값
    var dateText: String
    /// 하루 안의 분
    var clockInMinute: Int
    var plannedEndMinute: Int
    /// 직원이 입력한 실제 퇴근(하루 안의 분)
    var inputMinute: Int
    var selectedField: MissingClockOutField = .hour
    /// 서버가 준 인정 문구 값 — 아직 못 받았으면 nil(화면에서 계산하지 않음)
    var recognizedText: String?
    var recognizedPay: Int?
    var selected: MissingClockOutReason?

    /// DEC-004: 예정 퇴근 후 6시간 무응답이면 세션만 종료
    static let sessionEndAfterMinutes = 6 * 60
    /// 알림 간격(분) — 예정 퇴근 · +30 · +60
    static let reminderOffsets = [0, 30, 60]
    /// 입력 − 예정을 이 범위 안(±12시간)으로 맞춘다 — 자정을 넘긴 퇴근도 이어서 센다
    private static let halfDay = 12 * 60

    var hour: Int { inputMinute / 60 }
    var minute: Int { inputMinute % 60 }

    /// 입력 − 예정 퇴근(분). 양수 = 늦게, 음수 = 일찍
    var offsetMinutes: Int {
        let d = ((inputMinute - plannedEndMinute) % 1440 + 1440) % 1440
        return d > Self.halfDay ? d - 1440 : d
    }

    /// 32 → 「예정보다 32분 늦게 퇴근」, -90 → 「예정보다 1시간 30분 일찍 퇴근」, 0 → 「예정대로 퇴근」(후자 둘은 디자인에 없는 문구)
    var offsetText: String {
        let o = offsetMinutes
        if o == 0 { return "예정대로 퇴근" }
        return "예정보다 \(HomeFormat.hours(abs(o))) \(o > 0 ? "늦게" : "일찍") 퇴근"
    }

    var recognizedLine: String? {
        guard let recognizedText, let recognizedPay else { return nil }
        return "인정 예상 \(recognizedText) \u{00B7} \(PumFormat.amount(recognizedPay))원"
    }

    /// REQ-025: 실제 시간 + 사유. 사유가 없으면 요청할 수 없다
    var canRequest: Bool { selected != nil }

    mutating func step(_ field: MissingClockOutField, by delta: Int) {
        switch field {
        case .hour: inputMinute = (((hour + delta) % 24 + 24) % 24) * 60 + minute
        case .minute: inputMinute = hour * 60 + ((minute + delta) % 60 + 60) % 60
        }
        // 시각이 바뀌면 이전 시각 기준의 서버 인정 값은 버린다(새 값은 서버 재조회 후 — 연결 후속)
        recognizedText = nil
        recognizedPay = nil
    }

    /// 시간 선택 시트 설정 — 분 단위 입력(원문 1al은 20:32라 5 · 10분 간격으로도 못 맞춘다)
    static let pickerIntervalMinutes = 1
    /// 시트 제목 · 행 이름은 1al 화면의 기존 문구
    static let pickerTitle = "실제 몇 시에 퇴근했나요?"
    static let pickerRowLabel = "퇴근"

    /// C13 시트에서 고른 퇴근 시각 반영(순수). 하루 밖이면 하루 안으로 붙이고, 값이 바뀌면 이전 서버 인정 값은 버린다(step과 같은 규칙)
    func applying(pickedMinute minutes: Int) -> MissingClockOutState {
        var s = self
        s.inputMinute = min(max(minutes, 0), 24 * 60 - 1)
        if s.inputMinute != inputMinute { s.recognizedText = nil; s.recognizedPay = nil }
        return s
    }

    var plannedEndText: String { MissingClockOutFormat.clock(plannedEndMinute) }
    var clockInText: String { MissingClockOutFormat.clock(clockInMinute) }
    var inputText: String { MissingClockOutFormat.clock(inputMinute) }

    /// 「20:00·20:30·21:00」
    var reminderTimesText: String {
        Self.reminderOffsets.map { MissingClockOutFormat.clock(plannedEndMinute + $0) }.joined(separator: "\u{00B7}")
    }
    /// 세션 종료 시각(예정 퇴근 + 6시간) 문구 — 20:00 → 「새벽 2시」
    var sessionEndText: String { MissingClockOutFormat.dayPart(plannedEndMinute + Self.sessionEndAfterMinutes) }

    var noticeLead: String { "\(reminderTimesText) 알림에 응답이 없어 \(sessionEndText)에 근무 상태만 종료했어요. " }
    var noticeStrong: String { "\(plannedEndText) 퇴근으로 자동 처리하지 않았고," }
    static let noticeTail = " 급여에는 아직 반영되지 않았어요."
}

nonisolated enum MissingClockOutFormat {
    static func clock(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    /// 120 → 「새벽 2시」, 150 → 「새벽 2시 30분」, 8시 → 「오전 8시」, 13시 → 「오후 1시」, 19시 → 「저녁 7시」, 22시 → 「밤 10시」
    /// 원문은 「새벽 2시」만 있다 — 나머지 구간 이름은 구현 기준
    static func dayPart(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        let h = m / 60, mm = m % 60
        let part: String
        switch h {
        case 0..<6: part = "새벽"
        case 6..<12: part = "오전"
        case 12..<18: part = "오후"
        case 18..<21: part = "저녁"
        default: part = "밤"
        }
        let h12 = h % 12 == 0 ? 12 : h % 12
        return mm == 0 ? "\(part) \(h12)시" : "\(part) \(h12)시 \(mm)분"
    }
}

extension MissingClockOutState {
    /// 화면 기본 진입값: 입력 시각 = 예정 퇴근, 사유 선택 없음, 서버 인정 값은 아직 없음
    static let initial = MissingClockOutState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종",
        dateText: "어제 \u{00B7} 10월 3일 토",
        clockInMinute: 16 * 60 + 58, plannedEndMinute: 20 * 60,
        inputMinute: 20 * 60,
        recognizedText: nil, recognizedPay: nil, selected: nil
    )

    /// 디자인 1al 캡처 상태(가짜 데이터) — 비교 캡처용: 20:32 입력 · 첫 사유 선택
    static let sample = MissingClockOutState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종",
        dateText: "어제 \u{00B7} 10월 3일 토",
        clockInMinute: 16 * 60 + 58, plannedEndMinute: 20 * 60,
        inputMinute: 20 * 60 + 32,
        recognizedText: "3시간 04분", recognizedPay: 36_800, selected: .forgot
    )
}
