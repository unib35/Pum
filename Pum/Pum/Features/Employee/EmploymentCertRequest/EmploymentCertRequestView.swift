// UI-IOS-19d · REQ-062 — 직원 · 재직증명서 요청 (하위 화면, 탭 바 없음)
// 처리 중 표시는 요청 버튼에만, 성공 뒤에는 잠근 채 둔다. 「기타」는 원문에 입력칸이 없어 선택만(원문 없음).
import SwiftUI

struct EmploymentCertRequestView: View {
    let state: EmploymentCertRequestState
    @State private var draft: EmploymentCertRequestDraft
    /// 손대지 않았을 때만 서버 새 값을 받는다
    @State private var touched = false
    @State private var isSending = false
    @State private var isSent = false

    var onBack: () -> Void
    /// 사장님께 요청(선택 값) — 끝나면 done(성공 여부). 실패면 버튼이 풀리고, 성공이면 잠근 채 둔다
    var onRequest: (EmploymentCertRequestValue, @escaping (Bool) -> Void) -> Void

    init(state: EmploymentCertRequestState,
         onBack: @escaping () -> Void = {},
         onRequest: @escaping (EmploymentCertRequestValue, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onRequest = onRequest
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    Text(EmploymentCertRequestState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityAddTraits(.isHeader)
                    contentCard
                    chooseCard
                    purposeSection
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.initialDraft) { _, new in
            if !touched && !locked { draft = new } // 보낸 뒤에는 보낸 값 그대로
        }
    }

    private var locked: Bool { isSending || isSent }

    private func send() {
        guard !isSending, !isSent else { return }
        isSending = true
        onRequest(state.value(draft)) { ok in
            isSending = false
            if ok { isSent = true }
        }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(EmploymentCertRequestState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(EmploymentCertRequestState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private func cardHeader(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.top, PumTokens.Size.rowPadY)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    // MARK: 들어가는 내용

    private var contentCard: some View {
        PumCard {
            cardHeader(EmploymentCertRequestState.contentHeader)
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 { divider }
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) {
                    Text(row.title).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(row.value).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Size.rowPadY)
                .frame(minHeight: PumTokens.Size.tapMin)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.infoReadout(row)))
            }
        }
    }

    // MARK: 넣을지 고르기

    private var chooseCard: some View {
        PumCard {
            cardHeader(EmploymentCertRequestState.chooseHeader)
            toggleRow(EmploymentCertRequestState.birthDateTitle, $draft.includesBirthDate)
            divider
            toggleRow(EmploymentCertRequestState.addressTitle, $draft.includesAddress)
        }
        .disabled(locked) // VoiceOver · 스위치 제어도 막는다
    }

    private func toggleRow(_ title: String, _ isOn: Binding<Bool>) -> some View {
        let binding = Binding(get: { isOn.wrappedValue }, set: { touched = true; isOn.wrappedValue = $0 })
        return Toggle(isOn: binding) {
            Text(title).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isOn.wrappedValue ? "켬" : "끔"))
    }

    // MARK: 용도

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text(EmploymentCertRequestState.purposeHeader).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            segments
                .disabled(locked)
        }
    }

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(EmploymentCertPurpose.allCases) { p in
                let selected = draft.purpose == p
                Button {
                    touched = true
                    draft.purpose = p
                } label: {
                    Text(p.title)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(p.title)) // 「선택됨」은 .isSelected가 읽는다
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: EmploymentCertRequestState.sendTitle, isLoading: isSending,
                      loadingTitle: EmploymentCertRequestState.sendingTitle, action: send)
                .disabled(isSent)
            Text(EmploymentCertRequestState.footerNotice)
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("19d 재직증명서 요청") { EmploymentCertRequestView(state: .sample) }
#Preview("19d · 큰 글자") { EmploymentCertRequestView(state: .sample).dynamicTypeSize(.xxxLarge) }
