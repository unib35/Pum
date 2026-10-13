// UI-IOS-20c · REQ-007 · DEC-001 — 직접 등록 2/3 · 근로조건 (탭 바 없음)
// 시급 · 요일은 화면 초안, 근무 시간 · 급여일 · 공제 · 계좌는 행을 누르면 호출자가 고르기를 연다.
// 시급이 최저 미만이면 이유(19b와 같은 문구)를 칸 아래에 보이고 「다음」을 잠근다.
import SwiftUI

struct DirectRegisterTermsView: View {
    let state: DirectRegisterTermsState
    @State private var draft: DirectRegisterTermsDraft
    /// 칸별 손댐 — 손대지 않은 칸만 호출자 새 값을 받는다
    @State private var touchedWage = false
    @State private var touchedDays = false
    @State private var isSending = false
    @FocusState private var wageFocused: Bool
    /// 요일 칩 높이 기준 — 원문 30(10a와 같은 값)
    @ScaledMetric(relativeTo: .caption) private var chipSize = PumTimePickerStyle.weekdayChip

    var onBack: () -> Void
    var onEditHours: () -> Void
    var onPickPayday: () -> Void
    var onPickDeduction: () -> Void
    var onAddAccount: () -> Void
    /// 다음(값, done) — 끝나면 done 호출(버튼 잠금 해제)
    var onNext: (DirectRegisterTermsValue, @escaping () -> Void) -> Void

    private enum Layout {
        static let restLine: CGFloat = 1
        static let focusLine: CGFloat = 2
    }

    init(state: DirectRegisterTermsState,
         onBack: @escaping () -> Void = {},
         onEditHours: @escaping () -> Void = {},
         onPickPayday: @escaping () -> Void = {},
         onPickDeduction: @escaping () -> Void = {},
         onAddAccount: @escaping () -> Void = {},
         onNext: @escaping (DirectRegisterTermsValue, @escaping () -> Void) -> Void = { _, done in done() }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onEditHours = onEditHours
        self.onPickPayday = onPickPayday
        self.onPickDeduction = onPickDeduction
        self.onAddAccount = onAddAccount
        self.onNext = onNext
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            DirectRegisterStepBar(current: DirectRegisterTermsState.currentStep)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    Text(DirectRegisterTermsState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityAddTraits(.isHeader)
                    wageField
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        fieldLabel(DirectRegisterTermsState.workTitle)
                        weekdayChips
                        hoursCard
                    }
                    optionsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.initialDraft) { _, new in
            guard !isSending else { return }
            if !touchedWage { draft.hourlyWage = new.hourlyWage }
            if !touchedDays { draft.weekdays = new.weekdays }
        }
    }

    private var canProceed: Bool { state.canProceed(draft) }
    private var below: Bool { state.isBelowMinimum(draft) }

    private func next() {
        guard canProceed, !isSending else { return }
        wageFocused = false
        isSending = true
        onNext(state.value(draft)) { isSending = false }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(DirectRegisterTermsState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(DirectRegisterTermsState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
            .accessibilityHidden(true)
    }

    // MARK: 시급

    private var wageField: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    fieldLabel(DirectRegisterTermsState.wageTitle)
                    Spacer(minLength: PumTokens.Space.s8)
                    minimumNote.multilineTextAlignment(.trailing)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    fieldLabel(DirectRegisterTermsState.wageTitle)
                    minimumNote
                }
            }
            HStack(spacing: 0) {
                TextField("", text: Binding(
                    get: { draft.hourlyWage == 0 ? "" : PumFormat.amount(draft.hourlyWage) },
                    set: { touchedWage = true; draft.hourlyWage = DirectRegisterTermsState.wage(fromInput: $0) }))
                    .keyboardType(.numberPad)
                    .focused($wageFocused)
                    .tint(PumColor.accent)
                    .accessibilityLabel(Text(state.wageReadout()))
                    .accessibilityValue(Text(DirectRegisterTermsState.won(draft.hourlyWage)))
                    .accessibilityHint(Text(below ? DirectRegisterTermsState.belowMinimumHint : ""))
                    .toolbar { // 숫자 키패드에는 return 키가 없어 「완료」로 내린다
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("완료") { wageFocused = false }
                        }
                    }
                Text("원").accessibilityHidden(true)
            }
            .pumText(.body, weight: .regular) // 원문 16px 400 → body(15) 근사
            .foregroundStyle(PumColor.textPrimary)
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.vertical, PumTokens.Space.s14)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous)
                    .strokeBorder(wageFocused ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: wageFocused ? Layout.focusLine : Layout.restLine)
            }
            .contentShape(Rectangle())
            .onTapGesture { wageFocused = true }
            if below {
                Text(DirectRegisterTermsState.belowMinimumHint).pumText(.caption)
                    .foregroundStyle(PumColor.statusAttention)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, PumTokens.Space.s4)
                    .accessibilityHidden(true)
            }
        }
    }

    private var minimumNote: some View {
        Text(state.minimumWageText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 요일 · 시간

    private var weekdayChips: some View {
        let days = PumTimePickerStyle.weekdays
        return ViewThatFits(in: .horizontal) {
            chipRow(days)
            VStack(alignment: .leading, spacing: 0) { // 넘치면 4 + 3 두 줄
                chipRow(Array(days.prefix(4)))
                chipRow(Array(days.dropFirst(4)))
            }
        }
    }

    private func chipRow(_ days: [(id: Int, short: String, long: String)]) -> some View {
        HStack(spacing: PumTokens.Space.s8) {
            ForEach(days, id: \.id) { day in
                let on = draft.weekdays.contains(day.id)
                Button {
                    touchedDays = true
                    if on { draft.weekdays.remove(day.id) } else { draft.weekdays.insert(day.id) }
                } label: {
                    Text(day.short).pumText(.callout, weight: .semibold) // 원문 15
                        .foregroundStyle(on ? Color.white : PumColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: chipSize + PumTokens.Space.s16)
                        .background(on ? PumColor.surfaceInverse : PumColor.surfaceCard,
                                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .overlay {
                            if !on {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                                    .strokeBorder(PumColor.borderHairline, lineWidth: Layout.restLine)
                            }
                        }
                        .frame(minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day.long)) // 선택 상태는 특성으로
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private var hoursCard: some View {
        PumCard {
            Button {
                wageFocused = false
                onEditHours()
            } label: {
                HStack(spacing: PumTokens.Space.s8) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.timeRangeText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.breakAndDurationText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: PumTokens.Space.s8)
                    chevron
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.timeReadout()))
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: 급여일 · 공제 · 계좌

    private var optionsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                optionRow(DirectRegisterTermsState.paydayTitle, value: state.paydayText,
                          spoken: state.paydayReadout(), action: onPickPayday)
                divider
                optionRow(DirectRegisterTermsState.deductionTitle, value: state.deductionText,
                          spoken: state.deductionReadout(), action: onPickDeduction)
                divider
                optionRow(DirectRegisterTermsState.accountTitle, subtitle: DirectRegisterTermsState.accountHint,
                          value: state.accountValueText, valueMuted: true,
                          spoken: state.accountReadout(), action: onAddAccount)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: Layout.restLine)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    private func optionRow(_ title: String, subtitle: String? = nil, value: String, valueMuted: Bool = false,
                           spoken: String, action: @escaping () -> Void) -> some View {
        Button {
            wageFocused = false
            action()
        } label: {
            HStack(spacing: PumTokens.Space.s8) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let subtitle { Text(subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary) }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: PumTokens.Space.s8)
                Text(value).pumText(.body, weight: .semibold)
                    .foregroundStyle(valueMuted ? PumColor.textSecondary : PumColor.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                chevron
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 하단

    private var footer: some View {
        PumButton(title: DirectRegisterTermsState.nextTitle, isLoading: isSending, action: next)
            .disabled(!canProceed || isSending)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }
}

#Preview("20c 근로조건") { DirectRegisterTermsView(state: .sample) }
#Preview("20c · 큰 글자") { DirectRegisterTermsView(state: .sample).dynamicTypeSize(.xxxLarge) }
