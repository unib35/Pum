// UI-IOS-20l · REQ-007 · DEC-001 — 초대 수락 후 직원 앱. 앱 연결 전 기록은 「사업주 입력」으로 이어받고, 다르면 이의 제기.
// 모든 값은 서버 값 — 화면에서 계산하지 않는다.
import Foundation

/// 앱 연결 전 월 한 줄 — 서버 값
nonisolated struct InheritedMonth: Identifiable, Equatable, Sendable {
    /// 월 id(예: "2026-09") — onOpenMonth로 넘긴다
    let id: String
    /// 「9월」
    let title: String
    /// 「12일 · 55시간 10분 · 명세서 받음」
    let detail: String

    /// 「9월, 12일 · 55시간 10분 · 명세서 받음, 사업주 입력」
    var readout: String { "\(title), \(detail), \(InheritedRecordsState.ownerInputText)" }
}

nonisolated struct InheritedRecordsState: Equatable, Sendable {
    static let backTitle = "근무기록"
    static let ownerInputText = "사업주 입력"
    static let appRecordsBadge = "✓ 사업장 확인"
    static let appRecordsDetail = "앱으로 출퇴근한 기록"
    static let disputeTitle = "기록이 실제와 다르면"
    static let disputeDetail = "날짜를 골라 실제 시간과 사유를 보내요 · 사장님이 확인해요"
    static let disputeButton = "이의 제기"

    let workplaceName: String
    let title: String
    let subtitle: String
    let months: [InheritedMonth]
    /// 「10월 12일 월 부터」
    let appRecordsTitle: String

    /// 월 목록이 비면 월 카드를 그리지 않는다(원문 없음)
    var showsMonthCard: Bool { !months.isEmpty }

    /// 「10월 12일 월 부터, 앱으로 출퇴근한 기록, 사업장 확인」
    var appRecordsReadout: String { "\(appRecordsTitle), \(Self.appRecordsDetail), 사업장 확인" }
    var disputeReadout: String { "\(Self.disputeTitle), \(Self.disputeDetail), \(Self.disputeButton)" }

    static let sample = InheritedRecordsState(
        workplaceName: "종민김밥 본점",
        title: "지난 근무기록",
        subtitle: "앱 연결 전 · 사장님이 입력한 기록이에요.",
        months: [
            InheritedMonth(id: "2026-09", title: "9월", detail: "12일 · 55시간 10분 · 명세서 받음"),
            InheritedMonth(id: "2026-08", title: "8월", detail: "13일 · 58시간 30분 · 명세서 받음"),
            InheritedMonth(id: "2026-07", title: "7월", detail: "14일 · 63시간 · 명세서 받음"),
        ],
        appRecordsTitle: "10월 12일 월 부터")
}
