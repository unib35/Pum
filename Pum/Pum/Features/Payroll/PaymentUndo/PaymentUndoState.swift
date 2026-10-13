// UI-IOS-21a · 21b · REQ-076 · DEC-003 — 지급 완료 취소(시트) · 되돌린 뒤. 기한 없이 되돌릴 수 있고, 직원에게 알림은 가지 않으며 활동 기록에만 남는다.
// 모든 값은 서버가 준 그대로. 금액은 정수(원), 계좌는 서버가 가린 문자열(「국민은행 ••1234」)을 그대로 보여 준다(풀거나 가리지 않음).
import Foundation

nonisolated struct PaymentUndoState: Equatable, Sendable {
    /// 지급 대상 한 명
    nonisolated struct Row: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        let colorIndex: Int      // 서버가 준 아바타 색 번호
        let accountText: String  // 서버가 가린 문자열 예 「국민은행 ••1234」
        let netPay: Int          // 실지급액(원)
        let isPaid: Bool         // 지급 완료면 true, 지급 대기면 false

        var amountText: String { PumFormat.amount(netPay) + "원" }
        var statusText: String { isPaid ? "지급 완료" : "지급 대기" }
        /// 읽기: 「김하늘, 국민은행 ••1234, 1,062,000원, 지급 완료」
        var spokenText: String { "\(name), \(accountText), \(amountText), \(statusText)" }
    }

    /// 21a 시트가 가리키는 되돌릴 대상 — 서버 값
    nonisolated struct UndoTarget: Equatable, Sendable {
        let id: String
        let name: String
        let netPay: Int
        let paidAtText: String   // 서버 값 예 「11월 10일 14:20」

        /// 「김하늘 · 1,062,000원 · 11월 10일 14:20에 지급 완료로 처리했어요」
        var summaryText: String { "\(name) \u{00B7} \(PumFormat.amount(netPay))원 \u{00B7} \(paidAtText)에 지급 완료로 처리했어요" }
    }

    /// 활동 기록 한 줄 — 서버 값
    nonisolated struct Activity: Equatable, Sendable, Identifiable {
        let id: String
        let title: String   // 「14:32 · 김하늘 지급 완료 취소」
        let detail: String  // 「박민수 · 지급 대기로」
        var spokenText: String { "\(title), \(detail)" }
    }

    static let backTitle = "급여"
    static let title = "지급"
    static let activityTitle = "활동 기록"
    static let undoSheetTitle = "지급 대기로 되돌릴까요?"
    static let undoNotes = ["직원에게 알림이 가지 않아요", "활동 기록에 남아요"]
    static let cancelTitle = "취소"
    static let undoTitle = "지급 대기로 되돌리기"
    static let undoingTitle = "되돌리는 중"
    static let undoActionName = "지급 대기로 되돌리기"

    let monthText: String          // 서버 값 예 「10월분 · 지급일 11월 10일」
    let rows: [Row]
    let undoTarget: UndoTarget?    // 있을 때만 시트가 열린다
    let activities: [Activity]     // 되돌린 뒤에만 채워진다
    let toastText: String?         // 되돌린 직후에만 값이 있다

    var countText: String { "직원 \(rows.count)명" }
    var amountHeader: String { "실지급액" }
    func row(_ id: String) -> Row? { rows.first { $0.id == id } }

    private static let baseRows: [Row] = [
        Row(id: "haneul", name: "김하늘", colorIndex: 1, accountText: "국민은행 \u{2022}\u{2022}1234", netPay: 1_062_000, isPaid: true),
        Row(id: "seojun", name: "박서준", colorIndex: 3, accountText: "신한은행 \u{2022}\u{2022}5521", netPay: 880_000, isPaid: false),
        Row(id: "jongmin", name: "이종민", colorIndex: 0, accountText: "KB국민 \u{2022}\u{2022}0512", netPay: 1_118_610, isPaid: true),
    ]

    /// 21a 원문 — 시트 열림(가짜 예시 값)
    static let sample = PaymentUndoState(
        monthText: "10월분 \u{00B7} 지급일 11월 10일", rows: baseRows,
        undoTarget: UndoTarget(id: "haneul", name: "김하늘", netPay: 1_062_000, paidAtText: "11월 10일 14:20"),
        activities: [], toastText: nil)

    /// 21b 원문 — 김하늘이 지급 대기로 돌아옴 · 활동 기록 두 줄 · 토스트
    static let reverted = PaymentUndoState(
        monthText: "10월분 \u{00B7} 지급일 11월 10일",
        rows: baseRows.map { $0.id == "haneul" ? Row(id: $0.id, name: $0.name, colorIndex: $0.colorIndex, accountText: $0.accountText, netPay: $0.netPay, isPaid: false) : $0 },
        undoTarget: nil,
        activities: [
            Activity(id: "undo", title: "14:32 \u{00B7} 김하늘 지급 완료 취소", detail: "박민수 \u{00B7} 지급 대기로"),
            Activity(id: "paid", title: "14:20 \u{00B7} 김하늘 지급 완료 처리", detail: "박민수"),
        ],
        toastText: "지급 대기로 되돌렸어요")
}

/// 되돌리기 잠금 — 한 번만. 보내는 중엔 취소도 막고, 성공이면 잠근 채(실패일 때만 풀림).
nonisolated struct PaymentUndoLock: Equatable, Sendable {
    private(set) var isSending = false
    private(set) var isDone = false

    var isLocked: Bool { isSending || isDone }

    mutating func begin() -> Bool {
        guard !isLocked else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) {
        isSending = false
        if success { isDone = true }
    }
    mutating func reset() { self = PaymentUndoLock() }
}
