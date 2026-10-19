import SwiftData
import SwiftUI

// MVP 급여 탭(DEC-032 · DEC-033): 1u 그 달 월급 → 20g 근무 마감 → 1m 명세서.
// 마감 전에는 저장된 근무로 바로 계산해 보여 주고, 마감하면 확정 명세서(스냅숏)를 보여 준다.

/// 급여 탭이 보고 있는 달 — 탭 안 화면들이 함께 쓴다
@MainActor @Observable
final class SoloPayrollMonth {
    var year: Int
    var month: Int

    init(today: Int = SeoulDayKey.from(.now)) {
        // 기본은 지난달(지난달을 이번 달 급여일에 준다는 가정 — payroll-rules)
        let y = SeoulDayKey.year(today), m = SeoulDayKey.month(today)
        (year, month) = m == 1 ? (y - 1, 12) : (y, m - 1)
    }

    var title: String { "\(year)년 \(month)월" }

    /// 고를 수 있는 달: 이번 달부터 12개월 전까지
    static func recentMonths(today: Int = SeoulDayKey.from(.now)) -> [(year: Int, month: Int)] {
        var y = SeoulDayKey.year(today), m = SeoulDayKey.month(today)
        var result: [(Int, Int)] = []
        for _ in 0..<12 {
            result.append((y, m))
            (y, m) = m == 1 ? (y - 1, 12) : (y, m - 1)
        }
        return result
    }
}

/// 1u
struct SoloPayrollScreen: View {
    let router: AppRouter
    @Environment(SoloPayrollMonth.self) private var selected
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    @Query private var months: [PayrollMonth]
    @State private var pickingMonth = false

    var body: some View {
        OwnerPayrollView(
            record: record,
            onPickMonth: { pickingMonth = true },
            onEmployee: { e in router.navigate(.solo(.payslip(e.id))) },
            onConfirm: { router.navigate(.solo(.workClosing)) })
        .task(id: "\(selected.year)-\(selected.month)") {
            guard let workplace = workplaces.first else { return }
            try? SoloPayroll.useCase(context).prepare(workplace, year: selected.year, month: selected.month)
        }
        .confirmationDialog("월 고르기", isPresented: $pickingMonth) {
            ForEach(SoloPayrollMonth.recentMonths(), id: \.month) { y, m in
                Button("\(y)년 \(m)월") { selected.year = y; selected.month = m }
            }
        }
    }

    private var record: OwnerPayrollRecord {
        guard let workplace = workplaces.first else { return SoloPayroll.empty(selected) }
        _ = months // 마감 · 명세서가 바뀌면 다시 그린다
        return SoloPayroll.record(workplace, year: selected.year, month: selected.month, context: context)
    }
}

/// 20g
struct SoloWorkClosingScreen: View {
    let router: AppRouter
    @Environment(SoloPayrollMonth.self) private var selected
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    @State private var confirmed: Set<String> = []

    var body: some View {
        if let workplace = workplaces.first {
            WorkClosingDirectView(
                state: SoloPayroll.closingState(workplace, year: selected.year, month: selected.month, confirmed: confirmed),
                onBack: router.back,
                onConfirm: { id, done in confirmed.insert(id); done(true) },
                onOpenDay: { personID, dayID in
                    if let employee = workplace.employees?.first(where: { "\($0.persistentModelID)" == personID }),
                       let key = SoloWorkMonth.dayKey(dayID) {
                        router.navigate(.solo(.staffDay(employee.persistentModelID, key)))
                    }
                },
                onClose: { done in
                    let ok = (try? SoloPayroll.useCase(context).close(workplace, year: selected.year, month: selected.month)) != nil
                    done(ok)
                    if ok { router.backToRoot() }
                })
        }
    }
}

/// 1m
struct SoloPayslipScreen: View {
    let router: AppRouter
    let employeeID: String
    @Environment(SoloPayrollMonth.self) private var selected
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]

    var body: some View {
        if let workplace = workplaces.first,
           let record = SoloPayroll.payslip(workplace, employeeID: employeeID, year: selected.year, month: selected.month, context: context) {
            PayslipView(record: record, onBack: router.back)
        }
    }
}

// MARK: - 저장소 값 → 화면 값

enum SoloPayroll {
    static func useCase(_ context: ModelContext) -> MonthlyPayrollUseCase {
        MonthlyPayrollUseCase(employees: SwiftDataEmployeeRepository(context: context),
                              workDays: SwiftDataWorkDayRepository(context: context),
                              payroll: SwiftDataPayrollRepository(context: context))
    }

    static func closedMonth(_ workplace: Workplace, year: Int, month: Int, context: ModelContext) -> PayrollMonth? {
        guard let found = try? SwiftDataPayrollRepository(context: context).findMonth(of: workplace, year: year, month: month),
              found.isClosed else { return nil }
        return found
    }

    /// 한 사람 한 줄: 이름 · 색 · 근무 · 금액
    struct Row {
        let id: String
        let name: String
        let colorIndex: Int
        let workMinutes: Int
        let workDays: Int
        let wageKindText: String
        let netPay: Int
    }

    static func rows(_ workplace: Workplace, year: Int, month: Int, context: ModelContext) -> (rows: [Row], closed: Bool) {
        if let closed = closedMonth(workplace, year: year, month: month, context: context) {
            let rows = (closed.payslips ?? []).sorted { $0.createdAt < $1.createdAt }.map { slip in
                Row(id: slip.employee.map { "\($0.persistentModelID)" } ?? slip.employeeName, name: slip.employeeName,
                    colorIndex: slip.employee?.colorIndex ?? 0, workMinutes: slip.workedMinutes, workDays: slip.workDays,
                    wageKindText: slip.employee?.terms(on: .max)?.wageType == .monthly ? "월급" : "시급", netPay: slip.netPay)
            }
            return (rows, true)
        }
        let pays = (try? useCase(context).calculate(workplace, year: year, month: month, fill: false)) ?? []
        let rows = pays.map { pay in
            Row(id: "\(pay.employee.persistentModelID)", name: pay.employee.name, colorIndex: pay.employee.colorIndex,
                workMinutes: pay.result.workedMinutes, workDays: pay.result.workDays,
                wageKindText: pay.wageType == .monthly ? "월급" : "시급", netPay: pay.result.netPay)
        }
        return (rows, false)
    }

    static func record(_ workplace: Workplace, year: Int, month: Int, context: ModelContext) -> OwnerPayrollRecord {
        let (rows, closed) = Self.rows(workplace, year: year, month: month, context: context)
        let previous = month == 1 ? (year - 1, 12) : (year, month - 1)
        let before = Self.rows(workplace, year: previous.0, month: previous.1, context: context).rows
        let total = rows.reduce(0) { $0 + $1.netPay }
        let next = month == 12 ? 1 : month + 1
        let payday = min(workplace.payday, SeoulDayKey.daysInMonth(year: month == 12 ? year + 1 : year, month: next))
        return OwnerPayrollRecord(
            monthTitle: "\(year)년 \(month)월", stage: closed ? .confirmed : .needsReview, pendingCount: 0,
            totalAmount: total, payDayText: "\(next)월 \(payday)일", employeeCount: rows.count,
            totalMinutes: rows.reduce(0) { $0 + $1.workMinutes },
            deltaAmount: total - before.reduce(0) { $0 + $1.netPay },
            employees: rows.map { row in
                OwnerPayrollEmployee(id: row.id, name: row.name, colorIndex: row.colorIndex, workMinutes: row.workMinutes,
                                     workDays: row.workDays, wageKindText: row.wageKindText,
                                     amount: row.netPay, pendingCount: 0, statusTextOverride: closed ? "확정" : "마감 전")
            },
            isSolo: true, showsDelta: !before.isEmpty)
    }

    static func empty(_ selected: SoloPayrollMonth) -> OwnerPayrollRecord {
        OwnerPayrollRecord(monthTitle: selected.title, stage: .needsReview, pendingCount: 0, totalAmount: 0, payDayText: "",
                           employeeCount: 0, totalMinutes: 0, deltaAmount: 0, employees: [], isSolo: true, showsDelta: false)
    }

    /// 20g — 고친 날이 있는 직원만 한 번 확인한다
    static func closingState(_ workplace: Workplace, year: Int, month: Int, confirmed: Set<String>) -> WorkClosingDirectState {
        let range = SeoulDayKey.monthRange(year: year, month: month)
        let people: [WorkClosingDirectState.Person] = (workplace.employees ?? [])
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { employee in
                let id = "\(employee.persistentModelID)"
                let days = (employee.workDays ?? []).filter { range.contains($0.dayKey) }.sorted { $0.dayKey > $1.dayKey }
                let edited = days.filter { $0.status != .scheduled }
                guard !edited.isEmpty, !confirmed.contains(id) else { return nil }
                let terms = employee.terms(on: range.upperBound) ?? employee.terms(on: .max)
                return .init(
                    id: id, name: employee.name, scheduledDayCount: days.count - edited.count,
                    scheduledPattern: terms.map { "\(SoloFormat.weekdays($0.workWeekdays)) \(SoloFormat.hours(start: $0.startMinute, end: $0.endMinute))" } ?? "",
                    editedDayCount: edited.count,
                    editedDays: edited.map { day in
                        let row = SoloWorkMonth.row(day, employee: employee, today: .max)
                        return .init(id: SoloWorkMonth.dayID(day.dayKey), dateText: row.dateText,
                                     detailText: [row.timeText, row.extraText ?? row.noteText].compactMap { $0 }.joined(separator: " \u{00B7} "))
                    },
                    isSolo: true)
            }
        let last = SeoulDayKey.daysInMonth(year: year, month: month)
        return WorkClosingDirectState(
            month: month, periodText: "\(month)월 1일 \u{2013} \(last)일", appStaffCount: 0, appPendingCount: 0,
            people: people, remainingCount: people.count, canClose: people.isEmpty, isSolo: true)
    }

    /// 1m — 마감했으면 확정 명세서, 아니면 지금 계산
    static func payslip(_ workplace: Workplace, employeeID: String, year: Int, month: Int, context: ModelContext) -> PayslipRecord? {
        let draft: (name: String, draft: PayslipDraft)?
        let closed = closedMonth(workplace, year: year, month: month, context: context)
        if let closed {
            draft = (closed.payslips ?? [])
                .first { ($0.employee.map { "\($0.persistentModelID)" } ?? $0.employeeName) == employeeID }
                .map { slip in
                    (slip.employeeName, PayslipDraft(payItems: slip.payItems, deductionItems: slip.deductionItems,
                                                     grossPay: slip.grossPay, totalDeduction: slip.totalDeduction,
                                                     netPay: slip.netPay, traceLines: slip.traceLines,
                                                     workDays: slip.workDays, workedMinutes: slip.workedMinutes))
                }
        } else {
            draft = ((try? useCase(context).calculate(workplace, year: year, month: month, fill: false)) ?? [])
                .first { "\($0.employee.persistentModelID)" == employeeID }
                .map { ($0.employee.name, MonthlyPayrollUseCase.draft($0)) }
        }
        guard let draft else { return nil }
        let next = month == 12 ? (year + 1, 1) : (year, month + 1)
        let payday = min(workplace.payday, SeoulDayKey.daysInMonth(year: next.0, month: next.1))
        let d = draft.draft
        return PayslipRecord(
            monthTitle: "\(year)년 \(month)월", workplaceName: workplace.name, employeeName: draft.name,
            payDateText: String(format: "%d.%02d.%02d", next.0, next.1, payday),
            workSummary: "\(d.workDays)일 \u{00B7} \(hoursText(d.workedMinutes))",
            statusText: closed == nil ? "마감 전" : "확정",
            earnings: d.payItems.enumerated().map { PayslipLine(id: "p\($0.offset)", label: $0.element.name, amount: $0.element.amount) },
            deductions: d.deductionItems.enumerated().map { PayslipLine(id: "d\($0.offset)", label: $0.element.name, amount: $0.element.amount) },
            grossTotal: d.grossPay, deductionTotal: d.totalDeduction, netPay: d.netPay, isSolo: true)
    }

    /// 4950 → 「82h 30m」(원문 표기)
    static func hoursText(_ minutes: Int) -> String {
        minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)m"
    }
}
