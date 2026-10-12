// UI-IOS-10q · REQ-073 — 사장님 · 직원별 연차 현황 (하위 화면, 탭 바 없음)
// 모든 시간 · 금액 · 대상 여부 · 이유는 서버 값. 선택(직원 내역 보기)만 화면 안 상태.
import SwiftUI

struct LeaveBalanceView: View {
    let state: LeaveBalanceState
    var onBack: () -> Void
    /// 직원 행을 눌렀을 때(서버에 내역 요청 등)
    var onSelect: (String) -> Void
    /// 「휴무 요청으로 사용」 행 → 사용 내역
    var onOpenUsage: () -> Void

    @State private var selectedId: String?
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 36

    init(state: LeaveBalanceState = .sample,
         onBack: @escaping () -> Void = {},
         onSelect: @escaping (String) -> Void = { _ in },
         onOpenUsage: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onSelect = onSelect
        self.onOpenUsage = onOpenUsage
        _selectedId = State(initialValue: state.selectedId)
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: LeaveBalanceState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    heading
                    staffCard
                    historySection
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    private var heading: some View {
        let title = Text(state.headingText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
        let caption = Text(LeaveBalanceState.remainingCaption).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { title; Spacer(minLength: 0); caption }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { title; caption }
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: 직원 카드

    private var staffCard: some View {
        PumCard {
            ForEach(Array(state.staff.enumerated()), id: \.element.id) { i, person in
                if i > 0 { divider }
                staffRow(person)
            }
        }
    }

    private func staffRow(_ p: LeaveBalanceStaff) -> some View {
        let isSelected = p.id == selectedId
        let who = HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: p.name, colorIndex: p.colorIndex, size: avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(p.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(p.descriptionText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        let values = VStack(alignment: .trailing, spacing: PumTokens.Space.s2) {
            Text(p.remainingText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
            Text(p.usageText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        let badge = PumBadge(text: LeaveBalanceState.notEligibleText, kind: .waiting)
        return Button {
            selectedId = p.id
            onSelect(p.id)
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    who
                    if p.isEligible { values.fixedSize() } else { badge.fixedSize() }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 넘치면 아래로
                    who
                    if p.isEligible { values } else { badge }
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(p.spoken))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 선택한 직원 내역

    @ViewBuilder private var historySection: some View {
        let entries = state.entries(for: selectedId)
        if let person = state.staffMember(id: selectedId), !entries.isEmpty {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                Text(state.sectionTitle(for: person.name))
                    .pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                PumCard {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                        if i > 0 { divider }
                        entryRow(entry)
                    }
                }
            }
        }
    }

    @ViewBuilder private func entryRow(_ e: LeaveBalanceEntry) -> some View {
        switch e.kind {
        case .plain:
            entryContent(e)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(e.spoken))
        case .usage:
            Button(action: onOpenUsage) { entryContent(e) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(e.spoken))
                .accessibilityAddTraits(.isButton)
        }
    }

    private func entryContent(_ e: LeaveBalanceEntry) -> some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(e.title).pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let detail = e.detail {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        let value = Text(e.valueText).pumText(.body, weight: .semibold)
            .foregroundStyle(e.isAmount ? PumColor.statusDone : PumColor.textPrimary)
        let trailing = HStack(spacing: PumTokens.Space.s8) {
            value
            if e.kind == .usage {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumTokens.ColorToken.gray400).accessibilityHidden(true)
            }
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { texts; Spacer(minLength: 0); trailing.fixedSize() }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; trailing } // 넘치면 아래로
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview("10q 원문") { LeaveBalanceView(state: .sample) }
#Preview("10q · 큰 글자") { LeaveBalanceView(state: .sample).dynamicTypeSize(.accessibility3) }
