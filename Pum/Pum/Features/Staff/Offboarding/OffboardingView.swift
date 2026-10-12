// UI-IOS-10n · REQ-080 — 사장님 · 퇴사 정산 (하위 화면, 탭 바 없음)
// 모든 문구 · 금액 · 기한 · 단계 완료는 서버 값. 단계 행은 누르지 않는다(원문 근거 없음) — 버튼만 onNextStep.
import SwiftUI

struct OffboardingView: View {
    var state: OffboardingState
    var onBack: () -> Void
    /// 다음 할 일(문구는 서버 값)
    var onNextStep: () -> Void

    /// 단계 원 지름 — 원문 약 24
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 36

    init(state: OffboardingState = .sample,
         onBack: @escaping () -> Void = {},
         onNextStep: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onNextStep = onNextStep
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: OffboardingState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    staffCard
                    section(OffboardingState.payTitle) { payCard }
                    section(OffboardingState.stepsTitle) { stepsCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: state.nextStepTitle, kind: .primary, action: onNextStep)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text(title).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    // MARK: 직원 카드 + 지급 기한 띠

    private var staffCard: some View {
        PumCard {
            let info = HStack(spacing: PumTokens.Space.s12) {
                PumAvatar(name: state.name, colorIndex: state.colorIndex, size: avatarSize)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(state.name).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(state.periodText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { info; PumBadge(text: state.statusText, kind: .waiting).fixedSize() }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    info
                    PumBadge(text: state.statusText, kind: .waiting)
                }
            }
            .padding(PumTokens.Space.s16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.headerSpoken))
            divider
            deadlineStrip
        }
    }

    // 주황 = 처리 필요. 기한이 지난 경우의 원문 없음 → 주황 그대로
    private var deadlineStrip: some View {
        let main = Text(state.deadlineText).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.statusAttention)
        let note = Text(state.deadlineNote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { main; Spacer(minLength: 0); note }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { main; note }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .background(PumColor.statusAttentionSoft)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.deadlineSpoken))
    }

    // MARK: 지급할 것

    private var payCard: some View {
        PumCard {
            ForEach(Array(state.payItems.enumerated()), id: \.element.id) { i, item in
                if i > 0 { divider }
                payRow(item)
            }
        }
    }

    private func payRow(_ item: OffboardingPayItem) -> some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(item.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            Text(item.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        let amount = Text(item.amountText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { texts; Spacer(minLength: 0); amount.fixedSize() }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; amount } // 넘치면 아래로
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.spoken))
    }

    // MARK: 처리 순서

    private var stepsCard: some View {
        PumCard {
            ForEach(Array(state.steps.enumerated()), id: \.element.id) { i, step in
                if i > 0 { divider }
                stepRow(step)
            }
        }
    }

    private func stepRow(_ s: OffboardingStep) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            stepCircle(done: s.isDone)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                // 완료 단계는 제목이 회색(원문 #6B7280)
                Text(s.title).pumText(.body, weight: .semibold)
                    .foregroundStyle(s.isDone ? PumColor.textSecondary : PumColor.textPrimary)
                if let detail = s.detail {
                    Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.stepSpoken(s)))
    }

    /// 미완료 = 빈 원, 완료(서버 값) = 회색 원 + 먹색 체크(색 규칙). 공통 후보: 10b와 같은 단계 원
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
}

#Preview("10n 원문") { OffboardingView(state: .sample) }
#Preview("10n · 큰 글자") { OffboardingView(state: .sample).dynamicTypeSize(.accessibility3) }
