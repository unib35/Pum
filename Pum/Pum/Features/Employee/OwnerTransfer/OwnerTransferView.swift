// UI-IOS-17j · REQ-014 — 사장님 · 대표 변경 (하위 화면, 탭 바 없음)
// 되돌리기 어려운 처리 — 본인인증은 호출자 몫. 처리 중 표시는 보내기 버튼에만, 성공 뒤에는 잠근 채 둔다.
// 원문 없음: 받을 수 있는 관리자가 없으면 보내기 비활성 + 이유 힌트. 「사업장 떠나기」 확인 창은 호출자 몫.
import SwiftUI

struct OwnerTransferView: View {
    let state: OwnerTransferState
    @State private var draft: OwnerTransferDraft
    /// 손대지 않았을 때만 서버 새 값을 받는다
    @State private var touched = false
    @State private var isSending = false
    @State private var isSent = false

    var onBack: () -> Void
    /// 본인인증 후 보내기(받을 사람 id, 나는) — 끝나면 done(성공 여부). 실패면 버튼이 풀리고, 성공이면 잠근 채 둔다
    var onSendWithVerification: (String, OwnerTransferMyRole, @escaping (Bool) -> Void) -> Void

    /// 아바타 지름 — 원문 약 30
    @ScaledMetric(relativeTo: .callout) private var avatarSize: CGFloat = 30
    /// 회색 체크 원 지름 — 6t와 같은 값
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    private let checkRatio: CGFloat = 0.45

    init(state: OwnerTransferState,
         onBack: @escaping () -> Void = {},
         onSendWithVerification: @escaping (String, OwnerTransferMyRole, @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }) {
        self.state = state
        _draft = State(initialValue: state.initialDraft)
        self.onBack = onBack
        self.onSendWithVerification = onSendWithVerification
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    Text(OwnerTransferState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityAddTraits(.isHeader)
                    currentCard
                    Group {
                        recipientCard
                        myRoleCard
                    }
                    .allowsHitTesting(!(isSending || isSent)) // 보내는 중 · 보낸 뒤엔 받을 사람 · 나는을 바꿀 수 없음
                    if state.recipient(draft) != nil { delegateCard } // 받을 사람이 없으면 빈 이름 안내를 보이지 않음
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.initialDraft) { _, new in
            if !touched { draft = new }
        }
    }

    private func send() {
        guard let recipient = state.recipient(draft), !isSending, !isSent else { return }
        isSending = true
        onSendWithVerification(recipient.id, draft.myRole) { ok in
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
                    Text(OwnerTransferState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(OwnerTransferState.backTitle))
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

    // MARK: 지금

    private var currentCard: some View {
        PumCard {
            cardHeader(OwnerTransferState.currentHeader)
            HStack(spacing: PumTokens.Space.s12) {
                // 원문: 회색 원 — 공통 아바타 팔레트에 회색이 없어 화면 전용
                Text(state.currentOwnerInitial)
                    .font(PumFont.font(size: avatarSize * 0.38, weight: .bold, relativeTo: .callout))
                    .foregroundStyle(PumTokens.ColorToken.gray700)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(PumColor.surfaceFill, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(state.currentOwnerName).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.currentOwnerDetail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(state.currentOwnerName), \(state.currentOwnerDetail)"))
        }
    }

    // MARK: 받을 사람

    private var recipientCard: some View {
        PumCard {
            cardHeader(OwnerTransferState.recipientHeader)
            ForEach(Array(state.candidates.enumerated()), id: \.element.id) { i, c in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                recipientRow(c)
            }
        }
    }

    private func recipientRow(_ c: OwnerTransferCandidate) -> some View {
        let on = c.isSelectable && draft.recipientID == c.id
        return Button {
            touched = true
            draft.recipientID = c.id
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: on)
                PumAvatar(name: c.name, colorIndex: c.colorIndex, size: avatarSize)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(c.name).pumText(.callout, weight: .semibold)
                        .foregroundStyle(c.isSelectable ? PumColor.textPrimary : PumTokens.ColorToken.gray500)
                    Text(c.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        .multilineTextAlignment(.leading)
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
        .disabled(!c.isSelectable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.recipientReadout(c)))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 나는

    private var myRoleCard: some View {
        PumCard {
            cardHeader(OwnerTransferState.myRoleHeader)
            let roles = OwnerTransferMyRole.allCases
            ForEach(Array(roles.enumerated()), id: \.element.id) { i, role in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                PumRadioRow(title: role.title, isOn: draft.myRole == role, index: i, count: roles.count) {
                    touched = true
                    draft.myRole = role
                }
            }
        }
    }

    // MARK: 위임 안내

    private var delegateCard: some View {
        PumCard {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                Circle().fill(PumColor.surfaceFill)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: circleSize * checkRatio, weight: .bold))
                            .foregroundStyle(PumColor.textPrimary)
                    }
                    .frame(width: circleSize, height: circleSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(state.delegateTitle(draft)).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.delegateDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(state.delegateTitle(draft)). \(state.delegateDetail)"))
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: OwnerTransferState.sendTitle, isLoading: isSending, loadingTitle: OwnerTransferState.sendingTitle, action: send)
                .disabled(!state.canSend(draft) || isSent)
                .accessibilityHint(Text(state.disabledReason(draft) ?? ""))
            Text(state.canSend(draft) ? state.footerNotice(draft) : (state.disabledReason(draft) ?? ""))
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("17j 대표 변경") { OwnerTransferView(state: .sample) }
#Preview("17j · 큰 글자") { OwnerTransferView(state: .sample).dynamicTypeSize(.xxxLarge) }
