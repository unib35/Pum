import SwiftUI

/// 앱의 모든 목적지. 기능마다 Route를 나누고(Features/*/…Route.swift) 여기서 묶는다.
enum AppRoute: Hashable, Identifiable {
    case account(AccountRoute)
    case attendance(AttendanceRoute)
    case comms(CommsRoute)
    case contract(ContractRoute)
    case home(HomeRoute)
    case onboarding(OnboardingRoute)
    case payroll(PayrollRoute)
    case schedule(ScheduleRoute)
    case staff(StaffRoute)
    case workplace(WorkplaceRoute)

    static let all: [AppRoute] =
        AccountRoute.allCases.map { .account($0) }
        + AttendanceRoute.allCases.map { .attendance($0) }
        + CommsRoute.allCases.map { .comms($0) }
        + ContractRoute.allCases.map { .contract($0) }
        + HomeRoute.allCases.map { .home($0) }
        + OnboardingRoute.allCases.map { .onboarding($0) }
        + PayrollRoute.allCases.map { .payroll($0) }
        + ScheduleRoute.allCases.map { .schedule($0) }
        + StaffRoute.allCases.map { .staff($0) }
        + WorkplaceRoute.allCases.map { .workplace($0) }

    /// 디자인 화면 ID(screen-index)로 찾는다 — 비교 캡처 · 확인용 실행 인자
    init?(screenID: String) {
        if let r = AccountRoute(rawValue: screenID) { self = .account(r); return }
        if let r = AttendanceRoute(rawValue: screenID) { self = .attendance(r); return }
        if let r = CommsRoute(rawValue: screenID) { self = .comms(r); return }
        if let r = ContractRoute(rawValue: screenID) { self = .contract(r); return }
        if let r = HomeRoute(rawValue: screenID) { self = .home(r); return }
        if let r = OnboardingRoute(rawValue: screenID) { self = .onboarding(r); return }
        if let r = PayrollRoute(rawValue: screenID) { self = .payroll(r); return }
        if let r = ScheduleRoute(rawValue: screenID) { self = .schedule(r); return }
        if let r = StaffRoute(rawValue: screenID) { self = .staff(r); return }
        if let r = WorkplaceRoute(rawValue: screenID) { self = .workplace(r); return }
        return nil
    }

    var id: String { screenID }

    var screenID: String {
        switch self {
        case .account(let r): r.rawValue
        case .attendance(let r): r.rawValue
        case .comms(let r): r.rawValue
        case .contract(let r): r.rawValue
        case .home(let r): r.rawValue
        case .onboarding(let r): r.rawValue
        case .payroll(let r): r.rawValue
        case .schedule(let r): r.rawValue
        case .staff(let r): r.rawValue
        case .workplace(let r): r.rawValue
        }
    }

    var title: String {
        switch self {
        case .account(let r): r.title
        case .attendance(let r): r.title
        case .comms(let r): r.title
        case .contract(let r): r.title
        case .home(let r): r.title
        case .onboarding(let r): r.title
        case .payroll(let r): r.title
        case .schedule(let r): r.title
        case .staff(let r): r.title
        case .workplace(let r): r.title
        }
    }

    var isConnected: Bool {
        switch self {
        case .account(let r): AccountRoute.connected.contains(r)
        case .attendance(let r): AttendanceRoute.connected.contains(r)
        case .comms(let r): CommsRoute.connected.contains(r)
        case .contract(let r): ContractRoute.connected.contains(r)
        case .home(let r): HomeRoute.connected.contains(r)
        case .onboarding(let r): OnboardingRoute.connected.contains(r)
        case .payroll(let r): PayrollRoute.connected.contains(r)
        case .schedule(let r): ScheduleRoute.connected.contains(r)
        case .staff(let r): StaffRoute.connected.contains(r)
        case .workplace(let r): WorkplaceRoute.connected.contains(r)
        }
    }

    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .account(let r): r.view(router)
        case .attendance(let r): r.view(router)
        case .comms(let r): r.view(router)
        case .contract(let r): r.view(router)
        case .home(let r): r.view(router)
        case .onboarding(let r): r.view(router)
        case .payroll(let r): r.view(router)
        case .schedule(let r): r.view(router)
        case .staff(let r): r.view(router)
        case .workplace(let r): r.view(router)
        }
    }
}
