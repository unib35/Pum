// UI-IOS-19h · REQ-030 — 직원 · 휴게를 못 썼을 때. 예정 휴게는 빼고 계산, 사장님이 확인하면 반영.
// 인정 근무 · 예상 급여 · 내역은 서버 값(선택지별 미리보기를 한 번에 받는다) — 화면에서 시간 · 급여를 계산하지 않는다.
// 금액은 정수(원). 이 화면은 출퇴근 기록을 막는 곳이 아니다(신고만).
import Foundation

/// 기록 카드 한 행 — 제목 · 값
nonisolated struct BreakReportRow: Identifiable, Equatable, Sendable {
    let title: String
    let value: String
    var id: String { title }
    var readout: String { "\(title), \(value)" }
}

/// 뒤 화면(출퇴근 기록 하루) — 서버 값
nonisolated struct BreakReportState: Equatable, Sendable {
    static let backTitle = "근무"
    static let badgeText = "✓ 사업장 확인"
    static let subtitle = "출퇴근 기록"
    static let checkInTitle = "출근"
    static let checkOutTitle = "퇴근"
    static let breakTitle = "휴게"
    static let recognizedTitle = "인정 근무"
    static let reportTitle = "휴게 시간이 달랐어요"
    static let reportDetail = "실제로 쉰 시간을 알려주세요"

    /// 「10월 6일 화」
    let dateTitle: String
    let checkIn: String
    let checkOut: String
    /// 「30분 · 예정」
    let breakText: String
    /// 「4시간 30분」
    let recognizedText: String

    var rows: [BreakReportRow] {
        [BreakReportRow(title: Self.checkInTitle, value: checkIn),
         BreakReportRow(title: Self.checkOutTitle, value: checkOut),
         BreakReportRow(title: Self.breakTitle, value: breakText),
         BreakReportRow(title: Self.recognizedTitle, value: recognizedText)]
    }

    var reportReadout: String { "\(Self.reportTitle), \(Self.reportDetail)" }

    static let sample = BreakReportState(dateTitle: "10월 6일 화", checkIn: "16:58", checkOut: "22:04",
                                         breakText: "30분 · 예정", recognizedText: "4시간 30분")
}

/// 실제로 쉰 시간 선택지 — 서버 값(분, 0 = 못 쉼)
nonisolated struct BreakChoice: Identifiable, Equatable, Sendable {
    let id: String
    let minutes: Int
    var title: String { minutes == 0 ? "못 쉼" : "\(minutes)분" }
}

/// 선택마다 서버가 주는 「바뀌면」 값
nonisolated struct BreakPreview: Equatable, Sendable {
    /// 「4h 30m → 5h 00m」
    let recognizedChange: String
    /// 읽기용 「4시간 30분에서 5시간으로」
    let recognizedReadout: String
    /// 「기본 6,000 · 소정근로 초과 가산 3,000」
    let payDetail: String
    /// 예상 급여 차이(원) — 정수
    let payDelta: Int

    var payText: String {
        let sign = payDelta < 0 ? "-" : (payDelta > 0 ? "+" : "")
        return "\(sign)\(PumFormat.amount(abs(payDelta)))원"
    }
}

/// 보낼 값
nonisolated struct BreakReportInput: Equatable, Sendable {
    let choice: BreakChoice
    let reason: String
}

nonisolated struct BreakReportSheetState: Equatable, Sendable {
    static let titlePrefix = "휴게 시간"
    static let choiceHeader = "실제로 쉰 시간"
    static let reasonHeader = "사유 · 사장님에게 보여요"
    static let changeHeader = "바뀌면"
    static let recognizedTitle = "인정 근무"
    static let payTitle = "예상 급여"
    static let sendTitle = "사장님께 보내기"
    static let sendingTitle = "보내는 중"
    static let footerNotice = "사장님이 확인하면 반영돼요 · 그 전까지는 예정 휴게로 계산"
    /// 원문 없음 — 예정과 같은 시간이면 보낼 이유가 없어 비활성(읽기 힌트로만)
    static let samePlannedHint = "예정과 다른 시간을 고르면 보낼 수 있어요"

    /// 「10월 6일 화」
    let dateTitle: String
    /// 예정 휴게(분)
    let plannedMinutes: Int
    let choices: [BreakChoice]
    /// 선택 id → 바뀌면 값. 없으면(예정과 같음) 카드를 보이지 않는다
    let previews: [String: BreakPreview]
    let initialChoiceID: String
    let initialReason: String

    var title: String { "\(Self.titlePrefix) · \(dateTitle)" }
    var plannedText: String { "예정 \(plannedMinutes)분" }

    func choice(_ id: String) -> BreakChoice? { choices.first { $0.id == id } }
    func preview(_ id: String) -> BreakPreview? { previews[id] }

    /// 예정과 같은 시간을 고르면 보낼 것이 없다. 사유는 빈칸이어도 막지 않는다(원문 없음).
    func canSend(choiceID: String) -> Bool {
        guard let c = choice(choiceID) else { return false }
        return c.minutes != plannedMinutes
    }

    func input(choiceID: String, reason: String) -> BreakReportInput? {
        guard canSend(choiceID: choiceID), let c = choice(choiceID) else { return nil }
        return BreakReportInput(choice: c, reason: reason)
    }

    func changeReadout(_ p: BreakPreview) -> String { "\(Self.recognizedTitle), \(p.recognizedReadout)" }
    func payReadout(_ p: BreakPreview) -> String { "\(Self.payTitle), \(p.payDetail), \(p.payText)" }

    static let sample = BreakReportSheetState(
        dateTitle: "10월 6일 화",
        plannedMinutes: 30,
        choices: [.init(id: "30", minutes: 30), .init(id: "15", minutes: 15), .init(id: "none", minutes: 0)],
        previews: [
            "15": BreakPreview(recognizedChange: "4h 30m → 4h 45m", recognizedReadout: "4시간 30분에서 4시간 45분으로",
                               payDetail: "기본 3,000 · 소정근로 초과 가산 1,500", payDelta: 4_500),
            "none": BreakPreview(recognizedChange: "4h 30m → 5h 00m", recognizedReadout: "4시간 30분에서 5시간으로",
                                 payDetail: "기본 6,000 · 소정근로 초과 가산 3,000", payDelta: 9_000),
        ],
        initialChoiceID: "none",
        initialReason: "주문이 몰려서")
}
