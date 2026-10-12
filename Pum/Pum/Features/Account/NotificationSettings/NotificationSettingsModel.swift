// UI-IOS-4b · REQ-092 — 직원 「알림 설정」 값. 문구 · 시각 · 사업장 정책은 서버 값 그대로.

/// 출근 전 알림 시점(없음 · 10분 · 30분)
enum NotificationLeadTime: String, CaseIterable, Equatable {
    case none, tenMinutes, thirtyMinutes

    var title: String {
        switch self {
        case .none: "없음"
        case .tenMinutes: "10분"
        case .thirtyMinutes: "30분"
        }
    }
}

nonisolated struct NotificationSettingsState: Equatable {
    // 근무
    var leadTime: NotificationLeadTime
    /// 퇴근 리마인드 — 사업장 정책이라 직원이 바꿀 수 없다(서버 값)
    let offReminderOn: Bool
    let offReminderDetail: String
    let offReminderPolicyTag: String
    var recordChanges: Bool
    // 요청 · 공지
    var notices: Bool
    // 급여
    var payslip: Bool
    var payday: Bool
    // 방해 금지
    let quietHoursOn: Bool
    let quietHoursText: String

    static let screenTitle = "알림"
    static let workSection = "근무"
    static let alwaysSectionLead = "요청 · 공지"
    static let alwaysSectionTail = " · 항상 받아요"
    static let paySection = "급여"
    static let quietSection = "방해 금지"

    static let leadTitle = "출근 전 알림"
    static let leadSubtitle = "예정 출근 전에"
    static let offReminderTitle = "퇴근 리마인드"
    static let recordChangesTitle = "근무기록 확정·변경"
    static let recordChangesSubtitle = "사장님이 기록을 확인·수정했을 때"
    static let alwaysTitle = "근무 요청 · 대타 · 계약 서명"
    static let alwaysSubtitle = "결정이 필요한 요청은 끌 수 없어요"
    static let noticesTitle = "사업장 공지"
    static let noticesSubtitle = "새 공지 · 미확인 재알림"
    static let payslipTitle = "급여 확정 · 명세서 도착"
    static let paydayTitle = "급여일 알림"
    static let paydaySubtitle = "지급일 아침 9시"
    static let quietTitle = "조용한 시간"

    var offReminderSubtitle: String { "\(offReminderDetail) · \(offReminderPolicyTag)" }
    var quietStatusText: String { quietHoursOn ? "켜짐" : "꺼짐" }

    /// 원문 4b
    static let sample = NotificationSettingsState(
        leadTime: .tenMinutes,
        offReminderOn: true,
        offReminderDetail: "예정 퇴근 시각 · +30분 · +1시간",
        offReminderPolicyTag: "사업장 정책",
        recordChanges: true,
        notices: true,
        payslip: true,
        payday: true,
        quietHoursOn: true,
        quietHoursText: "23:00 – 08:00 · 요청·공지는 아침에 모아서"
    )
}
