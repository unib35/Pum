// UI-IOS-20b · REQ-007 · DEC-001 — 직접 등록 1/3 · 기본 정보 (탭 바 없음)
// 이름 · 휴대폰은 입력, 생년월일 · 입사일은 행을 누르면 호출자가 고르기를 연다(날짜 선택 방식 원문 없음).
// 처리 중 표시는 「다음」 버튼에만.
import SwiftUI

struct DirectRegisterBasicView: View {
    let state: DirectRegisterBasicState
    @State private var draft: DirectRegisterBasicDraft
    /// 손대지 않았을 때만 호출자 새 값을 받는다
    /// 칸별 손댐 — 한 칸을 고쳐도 다른 칸은 호출자 새 값을 받는다
    @State private var touchedName = false
    @State private var touchedPhone = false
    @State private var isSending = false
    @FocusState private var focus: DirectRegisterBasicField?

    var onBack: () -> Void
    var onPickBirthDate: () -> Void
    var onPickStartDate: () -> Void
    /// 다음(값) — 끝나면 done 호출(버튼 잠금 해제)
    var onNext: (DirectRegisterBasicValue, @escaping () -> Void) -> Void

    private enum Layout {
        static let restLine: CGFloat = 1
        static let focusLine: CGFloat = 2
    }

    init(state: DirectRegisterBasicState,
         onBack: @escaping () -> Void = {},
         onPickBirthDate: @escaping () -> Void = {},
         onPickStartDate: @escaping () -> Void = {},
         onNext: @escaping (DirectRegisterBasicValue, @escaping () -> Void) -> Void = { _, done in done() }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onPickBirthDate = onPickBirthDate
        self.onPickStartDate = onPickStartDate
        self.onNext = onNext
    }

    var body: some View {
        VStack(spacing: PumTokens.Space.s14) {
            backRow
            stepBar
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    Text(DirectRegisterBasicState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .padding(.top, PumTokens.Space.s6) // 원문 padding-top 2 + margin-top 4
                        .accessibilityAddTraits(.isHeader)
                    nameField
                    phoneField
                    dateRow(.birthDate, title: DirectRegisterBasicState.birthDateTitle,
                            hint: DirectRegisterBasicState.birthDateHint,
                            value: state.birthDate, action: onPickBirthDate)
                    dateRow(.startDate, title: DirectRegisterBasicState.startDateTitle,
                            hint: nil, value: state.startDate, action: onPickStartDate)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.bottom, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.initialDraft) { _, new in
            guard !isSending else { return }
            if !touchedName { draft.name = new.name }
            if !touchedPhone { draft.phone = new.phone }
        }
    }

    private var canProceed: Bool { DirectRegisterBasicState.canProceed(draft) }

    private func next() {
        guard canProceed, !isSending else { return }
        focus = nil
        isSending = true
        onNext(state.value(draft)) { isSending = false }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(DirectRegisterBasicState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(DirectRegisterBasicState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var stepBar: some View {
        DirectRegisterStepBar(current: DirectRegisterBasicState.currentStep)
    }

    // MARK: 입력

    private func fieldLabel(_ title: String) -> some View {
        Text(title).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
            .padding(.horizontal, PumTokens.Space.s2)
            .accessibilityHidden(true)
    }

    private func hintText(_ text: String) -> some View {
        Text(text).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, PumTokens.Space.s2)
            .accessibilityHidden(true)
    }

    private func box<C: View>(_ field: DirectRegisterBasicField, @ViewBuilder content: () -> C) -> some View {
        let active = focus == field || (focus == nil && state.highlighted == field)
        return content()
            .pumText(.body, weight: .regular) // 원문 16px 400 → body(15) 근사
            .foregroundStyle(PumColor.textPrimary)
            .tint(PumColor.accent)
            .padding(.horizontal, PumTokens.Space.s14)
            .padding(.vertical, PumTokens.Space.s14)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous)
                    .strokeBorder(active ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: active ? Layout.focusLine : Layout.restLine)
            }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            fieldLabel(DirectRegisterBasicState.nameTitle)
            box(.name) {
                TextField("", text: Binding(get: { draft.name }, set: { touchedName = true; draft.name = $0 }))
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focus = .phone }
                    .focused($focus, equals: .name)
                    .accessibilityLabel(Text(DirectRegisterBasicState.nameTitle))
            }
            .contentShape(Rectangle())
            .onTapGesture { focus = .name }
        }
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            fieldLabel(DirectRegisterBasicState.phoneTitle)
            box(.phone) {
                TextField("", text: Binding(get: { draft.phone }, set: {
                    touchedPhone = true
                    draft.phone = DirectRegisterBasicState.filterPhone($0)
                }))
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .toolbar { // 숫자 키패드에는 return 키가 없어 「완료」로 내린다
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("완료") { focus = nil }
                    }
                }
                .focused($focus, equals: .phone)
                .accessibilityLabel(Text(DirectRegisterBasicState.phoneLabel))
            }
            .contentShape(Rectangle())
            .onTapGesture { focus = .phone }
            hintText(DirectRegisterBasicState.phoneHint)
        }
    }

    private func dateRow(_ field: DirectRegisterBasicField, title: String, hint: String?,
                         value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            fieldLabel(title)
            Button {
                focus = nil
                action()
            } label: {
                box(field) {
                    Text(value.isEmpty ? DirectRegisterBasicState.datePlaceholder : value)
                        .foregroundStyle(value.isEmpty ? PumColor.textTertiary : PumColor.textPrimary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.dateReadout(title, hint: hint, value: value)))
            .accessibilityAddTraits(.isButton)
            if let hint { hintText(hint) }
        }
    }

    // MARK: 하단

    private var footer: some View {
        PumButton(title: DirectRegisterBasicState.nextTitle, isLoading: isSending, action: next)
            .disabled(!canProceed || isSending)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }
}

#Preview("20b 기본 정보") { DirectRegisterBasicView(state: .sample) }
#Preview("20b · 비어 있음") { DirectRegisterBasicView(state: .empty) }
#Preview("20b · 큰 글자") { DirectRegisterBasicView(state: .sample).dynamicTypeSize(.xxxLarge) }
