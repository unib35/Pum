// UI-IOS-1ah · REQ-027 · DEC-005 — 근무기록 삭제 액션 시트(사장님) 데이터
// 확정 전 기록은 사유를 남기고 삭제할 수 있고, 확정 후는 삭제 대신 정정 내역으로 남는다(REQ-027).
// 금액 · 시간 · 확정 여부는 서버가 준 값 그대로 — 화면에서 계산하지 않는다.
import Foundation

/// 시트 메뉴 항목 종류
nonisolated enum OwnerRecordAction: Equatable, Sendable {
    case editTime, markAbsent, delete

    var title: String {
        switch self {
        case .editTime: "시간 수정"
        case .markAbsent: "결근 처리"
        case .delete: "기록 삭제"
        }
    }

    /// 삭제만 빨강, 나머지 일반 동작은 파랑
    var isDestructive: Bool { self == .delete }

    /// VoiceOver 힌트 — 디자인 문구만(삭제 규칙 카드의 「사유를 남기고 삭제」)
    var accessibilityHint: String? { self == .delete ? "사유를 남기고 삭제해요" : nil }
}

nonisolated struct OwnerRecordActionsState: Equatable, Sendable {
    var employeeName: String
    /// 아바타 색 고정 키
    var colorIndex: Int
    var month: Int
    var day: Int
    /// 「목」 한 글자
    var weekday: String
    /// 하루 안의 분
    var startMinute: Int
    var endMinute: Int
    /// 서버 값: 근무 분 · 기본급(원) · 기록 방식 · 급여 반영 문구
    var workMinutes: Int
    var basePay: Int
    var recordMethod: String
    var payrollStatusText: String
    /// 서버 확정 플래그 — true면 「기록 삭제」를 숨긴다(확정 후는 정정으로, REQ-027)
    var isPayrollConfirmed: Bool

    static let screenTitle = "근무 상세"
    static let moreLabel = "더보기"
    static let unplannedBadgeText = "예정 없는 근무"
    static let recordMethodLabel = "기록 방식"
    static let payrollLabel = "급여 반영"
    static let cancelText = "취소"
    static let guideRuleTitle = "삭제 규칙"
    static let guideBefore = " \u{2014} 급여 확정 전 기록은 사유를 남기고 삭제할 수 있어요(직원에게 알림). 이미 확정\u{00B7}지급된 급여에 포함된 기록은 삭제 대신 "
    static let guideCorrection = "정정 내역"
    static let guideAfter = "으로 남고 다음 급여에서 조정돼요."

    var nameInitial: String { PumAvatar.initial(for: employeeName) }
    var dateText: String { "\(month)월 \(day)일 \(weekday)" }
    var personTitle: String { "\(employeeName) \u{00B7} \(dateText)" }
    var subtitleText: String {
        "\(PumFormat.timeRange(HomeFormat.clock(startMinute), HomeFormat.clock(endMinute))) \u{00B7} \(HomeFormat.hours(workMinutes)) \u{00B7} \(PumFormat.amount(basePay))원"
    }
    var personAccessibilityText: String { "\(personTitle), \(subtitleText), \(Self.unplannedBadgeText)" }

    /// 시트 맨 위 안내
    var sheetTitle: String { "\(employeeName) \u{00B7} \(month)월 \(day)일 근무기록" }
    var guideText: String { Self.guideRuleTitle + Self.guideBefore + Self.guideCorrection + Self.guideAfter }

    /// 확정 전: 시간 수정 · 결근 처리 · 기록 삭제 / 확정 후: 삭제 숨김(대체 문구는 디자인 없음)
    /// 확정 후 「시간 수정」 · 「결근 처리」를 정정(10f)으로 바꿀지는 미결정 — 충돌표 #33
    var menu: [OwnerRecordAction] {
        isPayrollConfirmed ? [.editTime, .markAbsent] : [.editTime, .markAbsent, .delete]
    }

    /// 디자인 1ah 예시 값(가짜 데이터)
    static let sample = OwnerRecordActionsState(
        employeeName: "정우진", colorIndex: 4, month: 10, day: 1, weekday: "목",
        startMinute: 13 * 60, endMinute: 17 * 60, workMinutes: 240, basePay: 48_000,
        recordMethod: "매장 QR", payrollStatusText: "아직 확정 전", isPayrollConfirmed: false
    )
}
