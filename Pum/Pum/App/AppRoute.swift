import SwiftUI

/// 앱의 모든 목적지. 기능마다 Route를 나누고(Features/*/…Route.swift) 여기서 묶는다.
enum AppRoute: Hashable, Identifiable {
    case attendance(AttendanceRoute)
    case auth(AuthRoute)
    case employee(EmployeeRoute)
    case home(HomeRoute)
    case notice(NoticeRoute)
    case payroll(PayrollRoute)
    case schedule(ScheduleRoute)
    case settings(SettingsRoute)
    case workplace(WorkplaceRoute)
    /// MVP 앱(저장소 값). 디자인 화면 목록 · 실행 인자에는 넣지 않는다.
    case solo(SoloRoute)

    static let all: [AppRoute] =
        AttendanceRoute.allCases.map { .attendance($0) }
        + AuthRoute.allCases.map { .auth($0) }
        + EmployeeRoute.allCases.map { .employee($0) }
        + HomeRoute.allCases.map { .home($0) }
        + NoticeRoute.allCases.map { .notice($0) }
        + PayrollRoute.allCases.map { .payroll($0) }
        + ScheduleRoute.allCases.map { .schedule($0) }
        + SettingsRoute.allCases.map { .settings($0) }
        + WorkplaceRoute.allCases.map { .workplace($0) }

    /// 디자인 화면 ID(screen-index)로 찾는다 — 비교 캡처 · 확인용 실행 인자
    init?(screenID: String) {
        if let r = AttendanceRoute(rawValue: screenID) { self = .attendance(r); return }
        if let r = AuthRoute(rawValue: screenID) { self = .auth(r); return }
        if let r = EmployeeRoute(rawValue: screenID) { self = .employee(r); return }
        if let r = HomeRoute(rawValue: screenID) { self = .home(r); return }
        if let r = NoticeRoute(rawValue: screenID) { self = .notice(r); return }
        if let r = PayrollRoute(rawValue: screenID) { self = .payroll(r); return }
        if let r = ScheduleRoute(rawValue: screenID) { self = .schedule(r); return }
        if let r = SettingsRoute(rawValue: screenID) { self = .settings(r); return }
        if let r = WorkplaceRoute(rawValue: screenID) { self = .workplace(r); return }
        return nil
    }

    var id: String { screenID }

    var screenID: String {
        switch self {
        case .attendance(let r): r.rawValue
        case .auth(let r): r.rawValue
        case .employee(let r): r.rawValue
        case .home(let r): r.rawValue
        case .notice(let r): r.rawValue
        case .payroll(let r): r.rawValue
        case .schedule(let r): r.rawValue
        case .settings(let r): r.rawValue
        case .workplace(let r): r.rawValue
        case .solo(let r): r.screenID
        }
    }

    var title: String {
        switch self {
        case .attendance(let r): r.title
        case .auth(let r): r.title
        case .employee(let r): r.title
        case .home(let r): r.title
        case .notice(let r): r.title
        case .payroll(let r): r.title
        case .schedule(let r): r.title
        case .settings(let r): r.title
        case .workplace(let r): r.title
        case .solo(let r): r.title
        }
    }

    var isConnected: Bool {
        switch self {
        case .attendance(let r): AttendanceRoute.connected.contains(r)
        case .auth(let r): AuthRoute.connected.contains(r)
        case .employee(let r): EmployeeRoute.connected.contains(r)
        case .home(let r): HomeRoute.connected.contains(r)
        case .notice(let r): NoticeRoute.connected.contains(r)
        case .payroll(let r): PayrollRoute.connected.contains(r)
        case .schedule(let r): ScheduleRoute.connected.contains(r)
        case .settings(let r): SettingsRoute.connected.contains(r)
        case .workplace(let r): WorkplaceRoute.connected.contains(r)
        case .solo: true
        }
    }

    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .attendance(let r): r.view(router)
        case .auth(let r): r.view(router)
        case .employee(let r): r.view(router)
        case .home(let r): r.view(router)
        case .notice(let r): r.view(router)
        case .payroll(let r): r.view(router)
        case .schedule(let r): r.view(router)
        case .settings(let r): r.view(router)
        case .workplace(let r): r.view(router)
        case .solo(let r): r.view(router)
        }
    }
}
