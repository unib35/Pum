// UI-IOS-1au — 확정 · 근무 없는 날: 하단 버튼 없음(출근하기 없음), 탭 바만 하단 고정
// UI-IOS-6u 업데이트 권장 시트 · UI-IOS-6v 점검 예고 한 줄(REQ-094) — 둘 다 호출자가 준 값이 있을 때만
// 순서: 칩 → 주간 스트립 → 오늘(근무 없음 · 다음 근무) → 그다음 근무 → 이번 달
import SwiftUI

struct EmployeeHomeNoShiftView: View {
    var state: NoShiftHomeState = .sample
    var onUnplannedClockIn: () -> Void = {}
    var onLater: () -> Void = {}
    var onUpdate: () -> Void = {}
    var onDismissMaintenanceNotice: () -> Void = {}
    @State private var tab = "home"
    @State private var updateSheetOpen = true       // 시트 열림(화면 상태) — 서버 값은 state에서 직접 읽는다
    @State private var maintenanceHidden = false    // 「닫기」 직후 바로 숨김(화면 상태)

    @ViewBuilder
    var body: some View {
        if let update = state.updateNotice {
            screen.pumBottomSheet(isPresented: $updateSheetOpen, onDismiss: onLater) {
                UpdateNoticeSheetContent(notice: update, onLater: later, onUpdate: onUpdate)
            }
        } else {
            screen
        }
    }

    private func later() {
        updateSheetOpen = false
        onLater()
    }

    private var screen: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                if let notice = state.maintenanceNotice, !maintenanceHidden {
                    MaintenanceNoticeRow(notice: notice) {
                        maintenanceHidden = true
                        onDismissMaintenanceNotice()
                    }
                }
                WeekStripCard(title: state.weekTitle, summary: state.weekSummary, days: state.week)
                NoShiftTodayCard(state: state, onUnplannedClockIn: onUnplannedClockIn)
                UpcomingShiftsCard(shifts: state.upcoming)
                MonthSummaryCard(state: state.monthCardState)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    private var header: some View {
        HStack {
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification) {}
        }
    }
}

struct NoShiftTodayCard: View {
    let state: NoShiftHomeState
    var onUnplannedClockIn: () -> Void = {}

    var body: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                // 큰 글자에서 제목과 배지가 한 줄에 안 들어가면 위아래로
                ViewThatFits(in: .horizontal) {
                    HStack {
                        title
                        Spacer(minLength: PumTokens.Space.s8)
                        PumBadge(text: "근무 없음", kind: .waiting)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        title
                        PumBadge(text: "근무 없음", kind: .waiting)
                    }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(state.nextShiftCaption).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    // 목업 26px → 토큰 title2(24)·title1(28)이 같은 거리. 좁은 폭에서 안 잘리도록 title2 (DEC-005)
                    Text(state.nextShiftRange).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                }
                .accessibilityElement(children: .combine)
                Text(state.plannedSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            // 디자인 1au: 구분선은 카드 끝에서 끝까지, 이동 행은 카드 바닥(C5 이동 행)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            Button(action: onUnplannedClockIn) {
                HStack {
                    Text("예정에 없는 출근")
                        .pumText(.footnote, weight: .semibold)
                        .foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Image(systemName: "chevron.right")
                        .pumText(.caption2)
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Space.s20)
                .frame(minHeight: PumTokens.Size.tapMin + PumTokens.Space.s8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("예정에 없는 출근"))
        }
    }

    private var title: some View {
        Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }
}

// MARK: - 6v 점검 예고 한 줄

struct MaintenanceNoticeRow: View {
    let notice: MaintenanceNotice
    let onDismiss: () -> Void
    @ScaledMetric private var iconSize = PumTokens.Size.tapMin - PumTokens.Space.s8 // 원문 회색 원 약 36

    var body: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                HStack(spacing: PumTokens.Space.s12) {
                    Image(systemName: "clock")
                        .pumText(.callout, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                        .frame(width: iconSize, height: iconSize)
                        .background(PumColor.surfaceFill, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(notice.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(MaintenanceNotice.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(notice.spoken))
                Button(action: onDismiss) {
                    Text(MaintenanceNotice.dismissTitle)
                        .pumText(.footnote, weight: .semibold)
                        .foregroundStyle(PumColor.textSecondary)
                        .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, PumTokens.Space.s16)
            .padding(.trailing, PumTokens.Space.s8)
            .padding(.vertical, PumTokens.Space.s12)
        }
    }
}

// MARK: - 6u 업데이트 권장 시트 내용

private struct UpdateNoticeSheetContent: View {
    let notice: AppUpdateNotice
    let onLater: () -> Void
    let onUpdate: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer(minLength: PumTokens.Space.s8)
                    meta
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    title
                    meta
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(notice.spokenTitle))
            .accessibilityAddTraits(.isHeader)
            PumCard {
                VStack(spacing: 0) {
                    ForEach(Array(notice.highlights.enumerated()), id: \.offset) { index, line in
                        if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                        Text(line)
                            .pumText(.body, weight: .semibold)
                            .foregroundStyle(PumColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, PumTokens.Space.s16)
                            .padding(.horizontal, PumTokens.Space.s16) // 구분선은 카드 끝까지(원문)
                    }
                }
            }
            // 버튼 둘: 받은 폭을 1 : 1.5로 나눈다. 큰 글자에서는 위아래로
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s8) {
                    PumButton(title: AppUpdateNotice.updateTitle, action: onUpdate)
                    PumButton(title: AppUpdateNotice.laterTitle, kind: .outline, action: onLater)
                }
            } else {
                RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) {
                    PumButton(title: AppUpdateNotice.laterTitle, kind: .outline, action: onLater)
                    PumButton(title: AppUpdateNotice.updateTitle, action: onUpdate)
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s12)
    }

    private var title: some View {
        Text(AppUpdateNotice.title).pumText(.title3).foregroundStyle(PumColor.textPrimary)
    }

    private var meta: some View {
        Text(notice.meta).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 한쪽이 다른 쪽에 밀려 찌그러지지 않는다.
private struct RatioPairLayout: Layout {
    var ratio: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let widths = columnWidths(total: width)
        let height = zip(subviews, widths)
            .map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width)
        var x = bounds.minX
        for (view, width) in zip(subviews, widths) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func columnWidths(total: CGFloat) -> [CGFloat] {
        let unit = max(0, total - spacing) / (1 + ratio)
        return [unit, unit * ratio]
    }
}

#Preview("1au") { EmployeeHomeNoShiftView() }
#Preview("6u 업데이트 권장") { EmployeeHomeNoShiftView(state: .updateAvailable) }
#Preview("6u · 큰 글자") { EmployeeHomeNoShiftView(state: .updateAvailable).dynamicTypeSize(.xxxLarge) }
#Preview("6v 점검 예고") { EmployeeHomeNoShiftView(state: .maintenanceNotice) }
#Preview("6v · 큰 글자") { EmployeeHomeNoShiftView(state: .maintenanceNotice).dynamicTypeSize(.xxxLarge) }
#Preview("1au · 큰 글자") { EmployeeHomeNoShiftView().dynamicTypeSize(.xxxLarge) }
