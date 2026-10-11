// UI-IOS-1t · REQ-042 · DEC-005 — 사업장 스케줄(사장님 근무 탭): 주간 스트립 · 일별 근무 · 대타 승인
// 색: 빨강 = 인원 부족 · 일요일, 주황 = 대타 요청, 파랑 = 다음 동작(근무 추가 · 승인). 버튼은 클로저만 받는다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만 이름을 붙인다(DEC-005). 사용처에서 @ScaledMetric으로 키운다.
private enum OwnerScheduleLayout {
    /// 시간대 왼쪽 열 폭(목업 약 56 → 글자와 함께 커진다)
    static let timeColumn: CGFloat = 64
    /// 사람 칸 아바타(목업 약 28)
    static let personAvatar: CGFloat = 28
    /// 대타 줄 아바타(목업 약 24 → 가까운 storeTileSmall 24)
    static let swapAvatar: CGFloat = PumLayout.storeTileSmall
    /// 주간 스트립 칸 최소 폭(접근성 글자 크기에서 가로 스크롤할 때)
    static let stripCellMin: CGFloat = 56
}

struct OwnerScheduleView: View {
    @State private var state: OwnerScheduleState
    private let onPreviousWeek: () -> Void
    private let onNextWeek: () -> Void
    private let onAddShift: (ScheduleDay) -> Void
    private let onReject: () -> Void
    private let onApprove: () -> Void
    private let onChangeWorkplace: () -> Void
    @State private var tab = "work"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: OwnerScheduleState = .sample,
         onPreviousWeek: @escaping () -> Void = {}, onNextWeek: @escaping () -> Void = {},
         onAddShift: @escaping (ScheduleDay) -> Void = { _ in },
         onReject: @escaping () -> Void = {}, onApprove: @escaping () -> Void = {},
         onChangeWorkplace: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        self.onPreviousWeek = onPreviousWeek
        self.onNextWeek = onNextWeek
        self.onAddShift = onAddShift
        self.onReject = onReject
        self.onApprove = onApprove
        self.onChangeWorkplace = onChangeWorkplace
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                weekCard
                if let day = state.selectedDay {
                    dayLine(day)
                    if !day.groups.isEmpty { groupsCard(day.groups) }
                }
                if let swap = state.swap { SwapRequestCard(swap: swap, onReject: onReject, onApprove: onApprove) }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: state.workTabBadge), selection: $tab)
        }
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                chip
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                chip
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }

    private var title: some View {
        // 목업 28px 700 → title1(28)
        Text("스케줄").pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var chip: some View {
        PumInverseWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial, action: onChangeWorkplace)
    }

    // MARK: 주간 카드

    private var weekCard: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s4) {
                HStack(spacing: 0) {
                    chevronButton("chevron.left", label: "지난주", action: onPreviousWeek)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(state.weekTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 목업 15px 700
                    Spacer(minLength: PumTokens.Space.s8)
                    chevronButton("chevron.right", label: "다음주", action: onNextWeek)
                }
                WeekStrip(days: state.days, selectedID: state.selectedID) { id in
                    withAnimation(PumMotion.respecting(reduceMotion, PumMotion.fast)) { state.select(id) } // M22
                }
            }
            .padding(.horizontal, PumTokens.Space.s8)
            .padding(.vertical, PumTokens.Space.s8)
        }
    }

    private func chevronButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PumColor.textSecondary)
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    // MARK: 선택한 날 줄

    private func dayLine(_ day: ScheduleDay) -> some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(day.title).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 목업 15px 700
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button { onAddShift(day) } label: {
                Text("+ 근무 추가").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent) // 목업 13px 600
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(day.spoken) 근무 추가"))
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 시간대 그룹

    private func groupsCard(_ groups: [ScheduleGroup]) -> some View {
        PumCard {
            ForEach(Array(groups.enumerated()), id: \.element.id) { i, g in
                if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 그룹 사이 전폭 hairline
                GroupRow(group: g)
            }
        }
    }
}

// MARK: - 먹색 사업장 칩

/// 1t 원문은 먹색 캡슐(DEC-007의 사장님 홈 칩은 흰색) — 공통 PumWorkplaceChip에 먹색 변형이 없어 화면 전용

// MARK: - 주간 스트립

private struct WeekStrip: View {
    let days: [ScheduleDay]
    let selectedID: Int
    let onSelect: (Int) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric private var cellMin = OwnerScheduleLayout.stripCellMin

    var body: some View {
        // 접근성 글자 크기에서는 칸이 좁아져 글자가 잘리므로 가로 스크롤
        if typeSize.isAccessibilitySize {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PumTokens.Space.s4) {
                    ForEach(days) { cell($0).frame(minWidth: cellMin) }
                }
            }
        } else {
            HStack(spacing: PumTokens.Space.s4) {
                ForEach(days) { cell($0) }
            }
        }
    }

    private func cell(_ day: ScheduleDay) -> some View {
        let selected = day.id == selectedID
        return Button { onSelect(day.id) } label: {
            VStack(spacing: PumTokens.Space.s2) {
                Text(day.weekday).pumText(.caption2, weight: .regular)
                    .foregroundStyle(selected ? PumColor.textOnInverseSecondary : (day.isSunday ? PumColor.statusDanger : PumColor.textSecondary))
                // 목업 16px → headline(17): 15·17 중 가까운 쪽이 같아 1at 주간 스트립과 같은 단계
                Text("\(day.id)").pumText(.headline, weight: selected ? .bold : .semibold)
                    .foregroundStyle(selected ? .white : (day.isSunday ? PumColor.statusDanger : PumColor.textPrimary))
                Text(day.countText).pumText(.caption2, weight: .semibold) // 목업 10px 600 → caption2(11)
                    .foregroundStyle(countColor(day, selected: selected))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PumTokens.Space.s8)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(selected ? PumColor.surfaceInverse : .clear,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.accessibilityLabel(selected: selected)))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func countColor(_ day: ScheduleDay, selected: Bool) -> Color {
        if selected { return PumColor.accentOnInverse } // #9DB4F7 = blue-300
        if day.isShort && !day.isClosed { return PumColor.statusDanger } // 서버가 「부족」으로 표시한 날
        return PumColor.textSecondary
    }
}

// MARK: - 시간대 그룹

private struct GroupRow: View {
    let group: ScheduleGroup
    @ScaledMetric private var timeColumn = OwnerScheduleLayout.timeColumn

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                times.frame(width: timeColumn, alignment: .leading)
                people
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                times
                people
            }
        }
        .padding(PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var times: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(group.start).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary) // 14px 700
            Text(group.end).pumText(.caption).foregroundStyle(PumColor.textTertiary)                  // 12px #8A919E
            Text(group.periodText).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(group.start)부터 \(group.end), \(group.period) \(OwnerScheduleFormat.spokenDuration(group.hours))"))
    }

    private var people: some View {
        VStack(spacing: PumTokens.Space.s8) {
            ForEach(group.people) { PersonCell(person: $0) }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PersonCell: View {
    let person: SchedulePerson
    @ScaledMetric private var avatar = OwnerScheduleLayout.personAvatar

    var body: some View {
        HStack(spacing: PumTokens.Space.s8) {
            PumAvatar(name: person.name, colorIndex: person.colorIndex, size: avatar)
            Text(person.name).pumText(.callout).foregroundStyle(PumColor.textPrimary) // 14px 600
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(person.breakLabel).pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px
        }
        .padding(.vertical, PumTokens.Space.s8)
        .padding(.horizontal, PumTokens.Space.s10)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(person.name), \(person.breakSpoken)"))
    }
}

// MARK: - 대타 요청

private struct SwapRequestCard: View {
    let swap: ScheduleSwapRequest
    let onReject: () -> Void
    let onApprove: () -> Void
    @ScaledMetric private var avatar = OwnerScheduleLayout.swapAvatar

    var body: some View {
        PumCard(attention: true) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(swap.title).pumText(.callout, weight: .bold).foregroundStyle(PumColor.statusAttention) // 주황 = 요청
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(swap.requestedAgo).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    Text(swap.whenText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                    people
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(swap.accessibilityText))
                buttons
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 이종민(취소선) → 박서준 · 그 주 시간. 좁으면 시간 문구를 아래로
    private var people: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                transfer
                Spacer(minLength: PumTokens.Space.s8)
                hours
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                transfer
                hours
            }
        }
    }

    private var transfer: some View {
        HStack(spacing: PumTokens.Space.s8) {
            PumAvatar(name: swap.fromName, colorIndex: swap.fromColorIndex, size: avatar)
            Text(swap.fromName).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textTertiary).strikethrough() // 흐린 회색 + 취소선
            Image(systemName: "arrow.right").font(.caption.weight(.semibold)).foregroundStyle(PumColor.textSecondary)
            PumAvatar(name: swap.toName, colorIndex: swap.toColorIndex, size: avatar)
            Text(swap.toName).pumText(.callout).foregroundStyle(PumColor.textPrimary)
        }
    }

    private var hours: some View {
        Text(swap.weekHoursText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    /// 같은 폭 2개. 「거절」은 원문에서 먹색 OUTLINE(1s의 빨강과 다름). 큰 글자에서는 세로
    private var buttons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { rejectButton; approveButton }
            VStack(spacing: PumTokens.Space.s8) { approveButton; rejectButton }
        }
    }

    private var rejectButton: some View {
        PumButton(title: "거절", kind: .outline, size: .small, action: onReject)
            .accessibilityLabel(Text("\(swap.toName) 대타 요청 거절"))
    }

    private var approveButton: some View {
        PumButton(title: "승인 \u{00B7} 담당자 변경", kind: .primary, size: .small, action: onApprove)
            .accessibilityLabel(Text("승인 · 담당자 변경, \(swap.toName)으로"))
    }
}

#Preview("1t") { OwnerScheduleView() }
#Preview("1t · 큰 글자") { OwnerScheduleView().dynamicTypeSize(.xxxLarge) }
#Preview("1t · 접근성") { OwnerScheduleView().dynamicTypeSize(.accessibility2) }
