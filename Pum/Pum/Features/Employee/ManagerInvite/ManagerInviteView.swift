// UI-IOS-17h · REQ-014 — 사장님 · 관리자 초대 (하위 화면, 탭 바 없음)
// 미인증 사업장 · 이름/번호 빈 상태 원문이 없어 보내기를 비활성으로 두고 이유를 VoiceOver 힌트로 읽는다(결정 필요).
import SwiftUI

struct ManagerInviteView: View {
    let state: ManagerInviteState
    @State private var draft: ManagerInviteDraft
    @State private var isSending = false
    /// 입력 중 칸 — 원문 캡처는 휴대폰 번호 칸이 파란 테두리
    @FocusState private var focus: Field?

    private enum Field { case name, phone }

    var onBack: () -> Void
    /// 보내기 — 끝나면 done(성공 여부). 실패면 버튼이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onSend: (ManagerInviteRole, String, String, ManagerInviteMethod, @escaping (Bool) -> Void) -> Void

    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 36

    init(state: ManagerInviteState,
         onBack: @escaping () -> Void = {},
         onSend: @escaping (ManagerInviteRole, String, String, ManagerInviteMethod, @escaping (Bool) -> Void) -> Void = { _, _, _, _, done in done(false) }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onSend = onSend
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    roleCard
                    inputCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private func send() {
        guard state.canSend(draft), !isSending else { return }
        isSending = true
        onSend(draft.role, draft.name, draft.phone, draft.method) { ok in
            if !ok { isSending = false }
        }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(ManagerInviteState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(ManagerInviteState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(ManagerInviteState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if state.isVerified {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s8) { badge; business }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) { badge; business }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.verifiedReadout))
            } else {
                business
            }
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var badge: some View { PumBadge(text: ManagerInviteState.verifiedBadge, kind: .done) }

    private var business: some View {
        Text(state.businessText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 역할

    private var roleCard: some View {
        PumCard {
            Text(ManagerInviteState.roleHeader).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Size.rowPadY)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            ForEach(ManagerInviteRole.allCases) { role in
                if role != ManagerInviteRole.allCases.first { Divider().overlay(PumColor.borderHairline) }
                roleRow(role)
            }
        }
    }

    private func roleRow(_ role: ManagerInviteRole) -> some View {
        let on = draft.role == role
        return Button { draft.role = role } label: {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: on).padding(.top, PumTokens.Space.s2)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(role.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.description(of: role)).pumText(.caption, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.roleReadout(role)))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 입력

    private var inputCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                field(ManagerInviteState.nameLabel, text: $draft.name, field: .name)
                field(ManagerInviteState.phoneLabel, text: $draft.phone, field: .phone)
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    label(ManagerInviteState.methodLabel)
                    segments
                }
            }
            .padding(PumTokens.Size.rowPadX)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.horizontal, PumTokens.Space.s2)
    }

    private func field(_ title: String, text: Binding<String>, field: Field) -> some View {
        let focused = focus == field
        return VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            label(title)
            TextField("", text: text)
                .focused($focus, equals: field)
                .keyboardType(field == .phone ? .numberPad : .default)
                .pumText(.headline, weight: .medium)
                .foregroundStyle(PumColor.textPrimary)
                .autocorrectionDisabled()
                .frame(minHeight: PumTokens.Size.buttonH)
                .padding(.horizontal, PumTokens.Space.s16)
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                        .stroke(focused ? PumColor.accent : PumColor.borderHairline,
                                lineWidth: focused ? PumTokens.Shadow.outline.spread : PumTokens.Shadow.hairline.spread)
                }
                .contentShape(Rectangle())
                .accessibilityLabel(Text(title))
        }
    }

    /// 세그먼트 — 6h와 같은 값(공통에 없어 화면 전용)
    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(ManagerInviteMethod.allCases) { method in
                let selected = method == draft.method
                Button { draft.method = method } label: {
                    Text(method.title)
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
                .accessibilityLabel(Text(method.title))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: ManagerInviteState.sendTitle, isLoading: isSending, loadingTitle: ManagerInviteState.sendingTitle, action: send)
                .disabled(!state.canSend(draft))
                .accessibilityHint(Text(state.disabledReason(draft) ?? ""))
            Text(state.footerNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("17h 관리자 초대") {
    ManagerInviteView(state: .sample)
}
