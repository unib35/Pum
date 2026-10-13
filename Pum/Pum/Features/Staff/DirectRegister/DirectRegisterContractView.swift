// UI-IOS-20d · REQ-007 · REQ-060 · DEC-001 — 직접 등록 3/3 · 근로계약서 (탭 바 없음)
// 사진 / 나중에 선택 · 사본 체크는 화면 초안. 처리 중 표시는 「등록」 버튼에만, 성공 뒤 잠근 채 둔다.
import SwiftUI

struct DirectRegisterContractView: View {
    let state: DirectRegisterContractState
    @State private var draft: DirectRegisterContractDraft
    /// 손대지 않았을 때만 호출자 새 값을 받는다
    @State private var touchedMethod = false
    @State private var touchedCopy = false
    @State private var isSending = false

    var onBack: () -> Void
    var onAddPhoto: () -> Void
    /// 등록(값) — 실패하면 done 호출(버튼 잠금 해제). 성공하면 호출하지 않아 잠긴 채 둔다
    var onRegister: (DirectRegisterContractValue, @escaping () -> Void) -> Void

    private enum Layout {
        static let cardLine: CGFloat = 1
        static let addLine: CGFloat = 1.5
        /// 원문 썸네일 약 105 × 124 → 폭 대비 높이 비
        static let thumbRatio: CGFloat = 124.0 / 105.0
        static let thumbMin: CGFloat = 88
    }

    init(state: DirectRegisterContractState,
         onBack: @escaping () -> Void = {},
         onAddPhoto: @escaping () -> Void = {},
         onRegister: @escaping (DirectRegisterContractValue, @escaping () -> Void) -> Void = { _, done in done() }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onAddPhoto = onAddPhoto
        self.onRegister = onRegister
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            DirectRegisterStepBar(current: DirectRegisterContractState.currentStep)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(DirectRegisterContractState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityAddTraits(.isHeader)
                    Text(DirectRegisterContractState.subtitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                    card.padding(.top, PumTokens.Space.s12)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.initialDraft) { _, new in
            guard !isSending else { return }
            if !touchedMethod { draft.method = new.method }
            if !touchedCopy { draft.copyGiven = new.copyGiven }
        }
    }

    private var canRegister: Bool { state.canRegister(draft) }

    private func register() {
        guard canRegister, !isSending else { return }
        isSending = true
        onRegister(state.value(draft)) { isSending = false }
    }

    private func choose(_ method: DirectRegisterContractMethod) {
        touchedMethod = true
        draft.method = method
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(DirectRegisterContractState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(DirectRegisterContractState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    // MARK: 카드

    private var isPhoto: Bool { draft.method == .photo }

    private var card: some View {
        VStack(spacing: 0) {
            methodRow(title: DirectRegisterContractState.photoTitle, hint: DirectRegisterContractState.photoHint,
                      readout: DirectRegisterContractState.photoReadout, isOn: isPhoto) { choose(.photo) }
            if isPhoto {
                divider
                thumbnails
                divider
                PumCheckboxRow(title: DirectRegisterContractState.copyTitle, isOn: draft.copyGiven) {
                    touchedCopy = true
                    draft.copyGiven.toggle()
                }
                .padding(.horizontal, PumTokens.Size.rowPadX - PumTokens.Space.s4)
            }
            divider
            methodRow(title: DirectRegisterContractState.laterTitle, hint: DirectRegisterContractState.laterHint,
                      readout: DirectRegisterContractState.laterReadout, isOn: !isPhoto) { choose(.later) }
        }
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous)
                .strokeBorder(PumColor.borderHairline, lineWidth: Layout.cardLine)
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: Layout.cardLine)
    }

    private func methodRow(title: String, hint: String, readout: String, isOn: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(hint).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(readout))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 사진

    private var thumbnails: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.thumbMin), spacing: PumTokens.Space.s8)],
                  spacing: PumTokens.Space.s8) {
            ForEach(state.photos) { photo in
                Color.clear
                    .aspectRatio(1 / Layout.thumbRatio, contentMode: .fit)
                    .overlay {
                        Text(photo.name).pumText(.caption, weight: .semibold)
                            .foregroundStyle(PumColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(PumTokens.Space.s4)
                    }
                    .background(PumColor.surfaceFill, in: thumbShape)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(DirectRegisterContractState.thumbReadout(photo)))
                    .accessibilityAddTraits(.isImage)
            }
            Button(action: onAddPhoto) {
                Color.clear
                    .aspectRatio(1 / Layout.thumbRatio, contentMode: .fit)
                    .overlay {
                        Text(DirectRegisterContractState.addSymbol).pumText(.title3, weight: .regular)
                            .foregroundStyle(PumColor.textTertiary)
                    }
                    .background(PumColor.surfaceCard, in: thumbShape)
                    .overlay { thumbShape.strokeBorder(PumTokens.ColorToken.gray200, lineWidth: Layout.addLine) }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(DirectRegisterContractState.addLabel))
            .accessibilityAddTraits(.isButton)
        }
        .padding(PumTokens.Size.rowPadX)
    }

    private var thumbShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: DirectRegisterContractState.registerTitle, isLoading: isSending, action: register)
                .disabled(!canRegister || isSending)
            Text(DirectRegisterContractState.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("20d 근로계약서") { DirectRegisterContractView(state: .sample) }
#Preview("20d · 나중에") { DirectRegisterContractView(state: .later) }
#Preview("20d · 큰 글자") { DirectRegisterContractView(state: .sample).dynamicTypeSize(.xxxLarge) }
