// UI-IOS-17e · REQ-050 — 직원 · 스케줄 게시 후: 다음 주가 바로 · 예상 급여 함께 · 휴일은 칸 안 라벨만
// 탭 바 있음(근무 선택). 값은 모두 서버 값 — 화면은 계산하지 않는다.
import SwiftUI

struct PublishedScheduleView: View {
    var state: PublishedScheduleState = .sample
    var onOpenThisWeek: () -> Void = {}
    var onRequestCover: () -> Void = {}
    @State private var tab = "work"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 카드 사이 14
                header
                NextWeekCard(state: state)
                SummaryCard(state: state)
                LinkCard(title: state.thisWeekTitle, caption: state.thisWeekSummary,
                         spoken: state.thisWeekAccessibility, action: onOpenThisWeek)
                LinkCard(title: PublishedScheduleState.coverTitle, caption: PublishedScheduleState.coverCaption,
                         spoken: state.coverAccessibility, action: onRequestCover)
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
    }

    private var title: some View {
        Text(PublishedScheduleState.screenTitle).pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var chip: some View {
        PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
    }
}

// MARK: - 다음 주 카드

private struct NextWeekCard: View {
    let state: PublishedScheduleState

    var body: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack {
                    title
                    Spacer(minLength: PumTokens.Space.s8)
                    badge
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    title
                    badge
                }
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.top, PumTokens.Space.s14) // 원문 머리 14 16 4
            .padding(.bottom, PumTokens.Space.s4)
            ForEach(Array(state.shifts.enumerated()), id: \.element.id) { index, shift in
                ShiftRow(shift: shift, showsDivider: index > 0)
            }
        }
    }

    private var title: some View {
        Text(state.nextWeekTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var badge: some View {
        if state.isNewlyPublished {
            PumBadge(text: PublishedScheduleState.newlyPublishedBadge, kind: .active)
        }
    }
}

private struct ShiftRow: View {
    let shift: PublishedShift
    let showsDivider: Bool
    // 날짜 칸 고정 폭 — 토큰에 없는 값(DEC-005). 큰 글자에서는 글자와 함께 커진다
    @ScaledMetric private var dateWidth: CGFloat = 48 // 원문 날짜 칸 48

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                date.frame(width: dateWidth, alignment: .leading)
                time
                Spacer(minLength: PumTokens.Space.s8)
                trailing
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                HStack {
                    date
                    Spacer(minLength: PumTokens.Space.s8)
                    hours
                }
                time
                holiday
            }
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 행 11 → 토큰 12
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: showsDivider ? 1 : 0) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(shift.accessibilityText))
    }

    private var date: some View {
        Text(shift.dateText).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    private var time: some View {
        Text(shift.rangeText).pumText(.headline).foregroundStyle(PumColor.textPrimary)
    }

    private var hours: some View {
        Text(shift.hoursText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    @ViewBuilder private var holiday: some View {
        if shift.isHolidayPremium { PumBadge(text: PublishedScheduleState.holidayBadge, kind: .waiting) }
    }

    private var trailing: some View {
        HStack(spacing: PumTokens.Space.s12) { // 원문 칸 사이 12
            holiday
            hours
        }
    }
}

// MARK: - 두 칸 요약

private struct SummaryCard: View {
    let state: PublishedScheduleState

    var body: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    hoursCell
                    Rectangle().fill(PumColor.borderHairline).frame(width: 1)
                    payCell
                }
                .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 0) {
                    hoursCell
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    payCell
                }
            }
        }
    }

    private var hoursCell: some View {
        cell(label: "다음 주 근무", value: state.nextWeekHoursText, footer: state.workDaysText)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.hoursAccessibility))
    }

    private var payCell: some View {
        cell(label: "예상 급여", value: state.expectedPayText, footer: state.payCaption)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.payAccessibility))
    }

    private func cell(label: String, value: String, footer: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(value).pumText(.title3).foregroundStyle(PumColor.textPrimary).minimumScaleFactor(0.8).lineLimit(1)
                .padding(.top, PumTokens.Space.s4) // 원문 값 위 4
            if let footer {
                Text(footer).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .padding(.top, PumTokens.Space.s2) // 원문 아래 글 위 2
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s14) // 원문 칸 14 16
    }
}

// MARK: - 이동 카드 (이번 주 · 대타 요청 보내기)

private struct LinkCard: View {
    let title: String
    let caption: String
    let spoken: String
    let action: () -> Void

    var body: some View {
        PumCard {
            Button(action: action) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(caption).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .pumText(.footnote, weight: .semibold)
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Space.s16)
                .padding(.vertical, PumTokens.Space.s12)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(spoken))
        }
    }
}

#Preview("17e") { PublishedScheduleView() }
#Preview("17e · 큰 글자") { PublishedScheduleView().dynamicTypeSize(.xxxLarge) }
