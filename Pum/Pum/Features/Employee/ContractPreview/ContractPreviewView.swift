// UI-IOS-10b · REQ-060 — 계약서 미리보기 → 사업주 서명 후 보내기(2/2, 탭 바 없음). 1z · 1aa와 이어진다.
// 휴대폰 본인확인 · 서명 패드(1aa)로 가는 흐름은 부모 몫 — onSignAndSend(done)만 부른다.
import SwiftUI

struct ContractPreviewView: View {
    var state: ContractPreviewState
    var onBack: () -> Void
    var onShowFull: () -> Void
    /// 서명하고 보내기. 끝나면 done(성공 여부). 연결 전 기본값은 done(false).
    var onSignAndSend: (_ done: @escaping (Bool) -> Void) -> Void

    @State private var lock = ContractPreviewLock()

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 값)
    /// 단계 원 지름 — 원문 약 24
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    /// 본문 글자 색 #3A4150 = 토큰 gray800
    private let bodyColor = PumTokens.ColorToken.gray800

    init(state: ContractPreviewState = .sample,
         onBack: @escaping () -> Void = {},
         onShowFull: @escaping () -> Void = {},
         onSignAndSend: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onShowFull = onShowFull
        self.onSignAndSend = onSignAndSend
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: ContractPreviewState.screenTitle, onBack: onBack) {
                Text(ContractPreviewState.stepText).pumText(.footnote, weight: .semibold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.trailing, PumTokens.Space.s8)
                    .accessibilityLabel(Text(ContractPreviewState.stepSpoken))
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(spacing: PumTokens.Space.s12) {
                    contractCard
                    stepsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    // MARK: 계약서 카드

    private var contractCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                Text(state.docTitle).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                // 원문 본문은 명조 계열 — 토큰에 없어 본문 글꼴(Pretendard)로 근사
                Text(state.intro).pumText(.caption).foregroundStyle(bodyColor)
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    ForEach(state.clauses) { clause in clauseRow(clause) }
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                footerRow
            }
            .padding(PumTokens.Space.s16)
        }
    }

    private func clauseRow(_ c: ContractPreviewClause) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
            Text(c.number).pumText(.caption).foregroundStyle(bodyColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(c.text).pumText(.caption).foregroundStyle(bodyColor)
                if let note = c.note { Text(note).pumText(.caption).foregroundStyle(bodyColor) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(c.spoken))
    }

    private var footerRow: some View {
        let page = Text(state.pageText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        let link = Button(action: onShowFull) {
            Text(ContractPreviewState.fullTextTitle).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumColor.accent)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        return ViewThatFits(in: .horizontal) {
            HStack { page; Spacer(minLength: PumTokens.Space.s8); link }
            VStack(alignment: .leading, spacing: 0) { page; link }
        }
    }

    // MARK: 단계 카드

    private var stepsCard: some View {
        PumCard {
            ForEach(Array(state.steps.enumerated()), id: \.element.id) { i, step in
                stepRow(step)
                if i < state.steps.count - 1 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                }
            }
        }
    }

    private func stepRow(_ s: ContractPreviewStep) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            stepCircle(done: s.isDone)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(s.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(s.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(s.spoken))
    }

    /// 미완료 = 빈 원, 완료(서버 값) = 회색 원 + 먹색 체크(색 규칙)
    @ViewBuilder private func stepCircle(done: Bool) -> some View {
        if done {
            Image(systemName: "checkmark")
                .font(.system(size: circleSize * 0.5, weight: .bold))
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.surfaceFill, in: Circle())
        } else {
            Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1.5)
                .frame(width: circleSize, height: circleSize)
        }
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: ContractPreviewState.signTitle, kind: .primary, isLoading: lock.isSending,
                      loadingTitle: ContractPreviewState.sendingTitle, action: send)
            Text(ContractPreviewState.footnote).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func send() {
        guard lock.begin() else { return }
        onSignAndSend { success in lock.finish(success: success) }
    }
}

#Preview("10b 원문") { ContractPreviewView(state: .sample) }
#Preview("10b · 큰 글자") { ContractPreviewView(state: .sample).dynamicTypeSize(.xxxLarge) }
