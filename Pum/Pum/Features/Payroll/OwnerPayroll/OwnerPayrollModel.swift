// UI-IOS-1u · REQ-107 — 사장님 급여 정산 화면 데이터
// 금액 · 시간 · 일수 · 건수 · 전월 대비는 서버(엔진)가 준 값을 그대로 보여 준다. 화면에서 합산하지 않는다.
import SwiftUI

/// 급여 진행 단계 5개(원문 순서)
nonisolated enum OwnerPayrollStage: Int, CaseIterable, Equatable, Sendable {
    case calculating, needsReview, confirmed, payPending, paid

    var title: String {
        switch self {
        case .calculating: "계산 중"
        case .needsReview: "확인 필요"
        case .confirmed: "확정"
        case .payPending: "지급 대기"
        case .paid: "지급 완료"
        }
    }

    enum Phase: Equatable, Sendable { case done, current, waiting }

    func phase(current: OwnerPayrollStage) -> Phase {
        rawValue < current.rawValue ? .done : (self == current ? .current : .waiting)
    }
}

nonisolated struct OwnerPayrollEmployee: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let colorIndex: Int
    let workMinutes: Int
    let workDays: Int
    /// 「시급」 — 원문은 뒤에 금액이 없다
    let wageKindText: String
    let amount: Int             // 서버가 준 원
    let pendingCount: Int       // 미처리 근무기록(건)
    /// MVP: 「마감 전」 · 「확정」
    var statusTextOverride: String? = nil

    var amountText: String { PumFormat.amount(amount) }
    var durationText: String { OwnerPayrollRecord.durationText(minutes: workMinutes) }
    var detailText: String { "\(durationText) \u{00B7} \(workDays)일 \u{00B7} \(wageKindText)" }
    var hasPending: Bool { pendingCount > 0 }
    var statusText: String { statusTextOverride ?? (hasPending ? "미처리 \(pendingCount)건" : "기록 모두 확정") }

    /// 「이종민, 82시간 30분, 17일, 1,188,000원, 기록 모두 확정」
    var accessibilityText: String { "\(name), \(durationText), \(workDays)일, \(amountText)원, \(statusText)" }
}

nonisolated struct OwnerPayrollRecord: Equatable, Sendable {
    var monthTitle: String          // 「2026년 10월」
    var stage: OwnerPayrollStage
    /// 서버가 준 값
    var pendingCount: Int           // 미처리 근무기록 전체 건수
    var totalAmount: Int
    var payDayText: String          // 「11월 10일」
    var employeeCount: Int
    var totalMinutes: Int
    var deltaAmount: Int            // 전월 대비 증감(원)
    var employees: [OwnerPayrollEmployee]
    /// MVP(DEC-033): 진행 단계 · 미처리 경고를 숨기고, 앞 달 기록이 없으면 전월 대비를 숨긴다
    var isSolo = false
    var showsDelta = true

    /// 딱 떨어지면 「74시간」(분 생략 — 원문), 아니면 「82시간 30분」
    static func durationText(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)분" }
        return m == 0 ? "\(h)시간" : "\(h)시간 \(m)분"
    }

    var stageNumber: Int { stage.rawValue + 1 }
    var stageAccessibilityText: String { "급여 진행, \(OwnerPayrollStage.allCases.count)단계 중 \(stageNumber)단계, \(stage.title)" }

    // 경고
    var showsWarning: Bool { !isSolo && pendingCount > 0 }
    var warningTitle: String { "미처리 근무기록 \(pendingCount)건" }
    var warningBody: String { "급여를 확정하려면 먼저 처리해야 해요" }
    var warningActionText: String { "처리" }
    var warningAccessibilityText: String { "\(warningTitle), \(warningBody), \(warningActionText)" }

    // 요약
    var summaryTitle: String { "\(monthTitleShort) 총 지급 예정" }
    /// 「2026년 10월」 → 「10월」
    var monthTitleShort: String { monthTitle.split(separator: " ").last.map(String.init) ?? monthTitle }
    var totalText: String { PumFormat.amount(totalAmount) }
    var payDayLabel: String { "지급일 \(payDayText)" }
    var headcountText: String { "직원 \(employeeCount)명" }
    var totalWorkText: String { "총 근무 \(Self.durationText(minutes: totalMinutes))" }
    /// 부호: + / U+2212 (0은 부호 없음)
    var deltaText: String {
        deltaAmount > 0 ? "+" + PumFormat.amount(deltaAmount)
            : deltaAmount < 0 ? PumFormat.deduction(deltaAmount) : "0"
    }
    var summaryAccessibilityText: String {
        let word = deltaAmount > 0 ? "증가" : deltaAmount < 0 ? "감소" : "변동 없음"
        let delta = deltaAmount == 0 ? word : "\(PumFormat.amount(abs(deltaAmount)))원 \(word)"
        let base = "\(summaryTitle) \(totalText)원, \(payDayLabel), \(headcountText), \(totalWorkText)"
        return showsDelta ? "\(base), 전월 대비 \(delta)" : base
    }

    // 확정 버튼: 미처리가 남으면 확정 불가(REQ-107)
    /// 확정은 「확인 필요」 단계에서 미처리가 0건일 때만. 이미 확정 이후 단계면 다시 확정하지 않는다(1v 재확정 방지)
    var canConfirm: Bool { stage == .needsReview && pendingCount == 0 }
    /// 확정 이후 단계 — 하단 확정 버튼 자리를 무엇으로 채울지는 디자인 없음(지금은 버튼 숨김)
    var showsConfirmButton: Bool { stage.rawValue <= OwnerPayrollStage.needsReview.rawValue }
    var confirmTitle: String { canConfirm ? "급여 확정하기" : "급여 확정하기 \u{00B7} 미처리 \(pendingCount)건 남음" }
    /// VoiceOver 라벨은 「급여 확정하기」만 — 이유는 힌트로 한 번(보이는 문구 · 힌트가 겹쳐 두 번 읽히지 않게)
    var confirmAccessibilityLabel: String { "급여 확정하기" }
    var confirmAccessibilityHint: String { pendingCount > 0 ? "미처리 근무기록 \(pendingCount)건을 먼저 처리해야 해요" : "" }

    static let sample = OwnerPayrollRecord(
        monthTitle: "2026년 10월", stage: .needsReview, pendingCount: 2,
        totalAmount: 4_210_000, payDayText: "11월 10일", employeeCount: 4, totalMinutes: 19_860, deltaAmount: 230_000,
        employees: [
            .init(id: "e1", name: "이종민", colorIndex: 0, workMinutes: 4_950, workDays: 17, wageKindText: "시급", amount: 1_188_000, pendingCount: 0),
            .init(id: "e2", name: "김하늘", colorIndex: 1, workMinutes: 4_440, workDays: 16, wageKindText: "시급", amount: 1_062_000, pendingCount: 1),
            .init(id: "e3", name: "최유나", colorIndex: 2, workMinutes: 5_760, workDays: 20, wageKindText: "시급", amount: 1_080_000, pendingCount: 0),
            .init(id: "e4", name: "박서준", colorIndex: 3, workMinutes: 4_710, workDays: 15, wageKindText: "시급", amount: 880_000, pendingCount: 1),
        ]
    )

    static let sampleClear: OwnerPayrollRecord = {
        var r = sample
        r.stage = .needsReview; r.pendingCount = 0 // 미처리를 모두 처리한 「확인 필요」 단계 — 확정 가능
        r.employees = r.employees.map {
            OwnerPayrollEmployee(id: $0.id, name: $0.name, colorIndex: $0.colorIndex, workMinutes: $0.workMinutes,
                                 workDays: $0.workDays, wageKindText: $0.wageKindText, amount: $0.amount, pendingCount: 0)
        }
        return r
    }()
}
