// UI-IOS-17b · REQ-050 — 근무 추가 시트(17a 위 · C9 바텀시트 안 내용)
// 직원 · 출근/퇴근 · 휴게 · 반복은 시트 초안(@State). 바꿀 때마다 onDraftChange로 알리고,
// 「이 주 근무」 시간 · 예상 인건비 · 가산 근거는 서버(엔진)가 새로 보낸 값을 그대로 보여준다(화면 계산 없음).
// 서버 새 값이 오면 손대지 않았을 때만 초안을 다시 받는다(6h 방식).
import SwiftUI

struct AddShiftSheet: View {
    private let state: AddShiftSheetState
    @State private var draft: AddShiftDraft
    @State private var focus: DraftTimeField
    @State private var isWheelOpen = false
    private let onDraftChange: (AddShiftDraft) -> Void
    private let onAddToDraft: (AddShiftDraft) -> Void
    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .footnote) private var chipAvatar: CGFloat = 22

    init(state: AddShiftSheetState,
         onDraftChange: @escaping (AddShiftDraft) -> Void = { _ in },
         onAddToDraft: @escaping (AddShiftDraft) -> Void = { _ in }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        _focus = State(initialValue: state.focusedField)
        self.onDraftChange = onDraftChange
        self.onAddToDraft = onAddToDraft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            header
            staffBlock
            timeBlock
            optionsCard
            estimateCard
            PumButton(title: AddShiftSheetState.addTitle) { onAddToDraft(draft) }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
        .onChange(of: state) { old, new in
            // 손대지 않았거나 새 서버 값과 같아졌을 때만 다시 받는다 — 입력 중인 값을 말없이 지우지 않게
            if !old.hasChanges(draft) || !new.hasChanges(draft) { draft = new.initialDraft }
        }
        .onChange(of: draft) { _, new in onDraftChange(new) }
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                title
                Spacer(minLength: PumTokens.Space.s8)
                PumBadge(text: state.badge, kind: .waiting)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                PumBadge(text: state.badge, kind: .waiting)
            }
        }
    }

    private var title: some View {
        Text(state.title).pumText(.title3).foregroundStyle(PumColor.textPrimary) // 20px 700
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: 직원

    private var staffBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            label(AddShiftSheetState.staffLabel)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { staffChips }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PumTokens.Space.s8) { staffChips }
                }
            }
        }
    }

    private var staffChips: some View {
        ForEach(Array(state.staff.enumerated()), id: \.element.id) { i, person in
            let on = person.id == draft.staffID
            Button { draft.staffID = person.id } label: {
                HStack(spacing: PumTokens.Space.s6) {
                    PumAvatar(name: person.name, colorIndex: person.colorIndex, size: chipAvatar)
                    Text(person.name).pumText(.footnote, weight: .semibold) // 13px 600
                        .foregroundStyle(on ? Color.white : PumColor.textPrimary)
                        .lineLimit(1)
                }
                .padding(.leading, PumTokens.Space.s4)
                .padding(.trailing, PumTokens.Space.s10)
                .padding(.vertical, PumTokens.Space.s4)
                .background(on ? PumColor.surfaceInverse : PumColor.surfaceCard, in: Capsule())
                .overlay { if !on { Capsule().stroke(PumColor.borderHairline, lineWidth: 1) } }
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(person.name), \(state.staff.count)개 중 \(i + 1)번째"))
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
        }
    }

    // MARK: 출근 · 퇴근

    private var timeBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PumTokens.Space.s12) { startField; endField }
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) { startField; endField }
            }
            if isWheelOpen {
                PumTimeWheel(title: focus == .start ? AddShiftSheetState.startLabel : AddShiftSheetState.endLabel,
                             minutes: focus == .start ? $draft.startMinutes : $draft.endMinutes)
            }
        }
    }

    private var startField: some View {
        timeField(AddShiftSheetState.startLabel, minutes: draft.startMinutes, field: .start)
    }

    private var endField: some View {
        timeField(AddShiftSheetState.endLabel, minutes: draft.endMinutes, field: .end)
    }

    private func timeField(_ title: String, minutes: Int, field: DraftTimeField) -> some View {
        let focused = focus == field
        return VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            label(title)
            Button {
                if focus == field { isWheelOpen.toggle() } else { focus = field; isWheelOpen = true }
            } label: {
                Text(state.clock(minutes)).pumText(.headline, weight: .medium) // 16px 500 → headline(17)
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.buttonH, alignment: .leading)
                    .padding(.horizontal, PumTokens.Space.s16)
                    .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                            .stroke(focused ? PumColor.accent : PumColor.borderHairline, lineWidth: focused ? PumTokens.Shadow.outline.spread : PumTokens.Shadow.hairline.spread)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(PumTimeWheelMath.spokenText(minutes)))
            .accessibilityHint(Text("눌러서 시간을 바꿔요"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(_ text: String) -> some View {
        Text(text).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary) // 13px 600
    }

    // MARK: 휴게 · 반복

    private var optionsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s8) {
                    Text(AddShiftSheetState.breakLabel).pumText(.callout, weight: .regular) // 14px 400
                        .foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    breakMenu
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(minHeight: PumTokens.Size.tapMin)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(AddShiftSheetState.repeatLabel).pumText(.callout, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                    segments
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var breakMenu: some View {
        Menu {
            ForEach(state.breakOptions, id: \.self) { minutes in
                Button(state.breakText(minutes)) { draft.breakMinutes = minutes }
            }
        } label: {
            HStack(spacing: PumTokens.Space.s4) {
                Text(state.breakText(draft.breakMinutes)).pumText(.callout, weight: .bold) // 14px 700
                    .foregroundStyle(PumColor.textPrimary)
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(PumColor.textSecondary)
            }
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(AddShiftSheetState.breakLabel))
        .accessibilityValue(Text(state.breakText(draft.breakMinutes)))
    }

    /// 세그먼트 — 공통에 없어 화면 전용(6h와 같은 값)
    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(Array(state.repeatOptions.enumerated()), id: \.offset) { i, option in
                let selected = i == draft.repeatIndex
                Button { draft.repeatIndex = i } label: {
                    Text(option)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: max(segmentHeight, PumTokens.Size.tapMin))
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(option))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 이 주 근무 · 예상 인건비(서버 값)

    private var estimateCard: some View {
        let e = state.estimate
        return PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s8) {
                        Text(e.title).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(e.hoursText).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(e.title).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(e.hoursText).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    }
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                        costText(e)
                        Spacer(minLength: PumTokens.Space.s8)
                        totalText(e)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                        costText(e)
                        totalText(e)
                    }
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(e.accessibilityText))
        }
    }

    private func costText(_ e: DraftEstimate) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(e.costLabel).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary)
            Text(e.basis).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
    }

    private func totalText(_ e: DraftEstimate) -> some View {
        Text(e.total).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }
}

#Preview("17b 시트") {
    AddShiftSheet(state: .sample).background(PumColor.bgApp)
}
