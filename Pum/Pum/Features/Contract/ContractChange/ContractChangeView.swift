// UI-IOS-10c · REQ-060 — 근로조건 변경 → 변경 계약서(하위 화면, 탭 바 없음).
// 시급 수정은 10a와 같게 클로저만, 날짜 선택은 #192 미정이라 onPickDate 클로저만 부른다.
// 영향 값은 계산 조건이 지금 선택과 같을 때만 보인다. 보내기는 한 번만(성공이면 잠근 채).
import SwiftUI

struct ContractChangeView: View {
    var state: ContractChangeState
    var onBack: () -> Void
    var onEditWage: () -> Void
    var onShowUnchanged: () -> Void
    var onPickDate: () -> Void
    /// 선택이 바뀔 때마다 — 부모가 엔진에 다시 계산을 요청한다
    var onStartChanged: (ContractChangeStart) -> Void
    /// 보내기. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSend: (_ done: @escaping (Bool) -> Void) -> Void

    @State private var start: ContractChangeStart
    @State private var lock = ContractChangeSendLock()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: ContractChangeState = .sample,
         onBack: @escaping () -> Void = {},
         onEditWage: @escaping () -> Void = {},
         onShowUnchanged: @escaping () -> Void = {},
         onPickDate: @escaping () -> Void = {},
         onStartChanged: @escaping (ContractChangeStart) -> Void = { _ in },
         onSend: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onEditWage = onEditWage
        self.onShowUnchanged = onShowUnchanged
        self.onPickDate = onPickDate
        self.onStartChanged = onStartChanged
        self.onSend = onSend
        _start = State(initialValue: state.basis.start)
    }

    private var isSending: Bool { lock.isSending }
    private var impact: ContractChangeImpact? { state.visibleImpact(for: start) }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: ContractChangeState.headerTitle, onBack: isSending ? nil : onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    employeeCard
                    section(ContractChangeState.changedHeading) { changedCard }
                    section(ContractChangeState.whenHeading) { whenCard }
                    section(ContractChangeState.impactHeading) { impactCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: start)
    }

    // MARK: 바닥

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: ContractChangeState.sendTitle, kind: .primary, isLoading: isSending, action: send)
                .disabled(!state.hasChanges)
            if let notice = impact?.noticeText {
                Text(notice).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: title)
            content()
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    // MARK: 직원 카드

    private var employeeCard: some View {
        PumCard {
            let avatar = PumAvatar(name: state.employeeName, colorIndex: 1)
            let names = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.employeeName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(state.subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            let badge = PumBadge(text: state.badgeText, kind: .waiting)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    avatar
                    names.frame(maxWidth: .infinity, alignment: .leading)
                    badge
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    HStack(spacing: PumTokens.Space.s12) { avatar; names }
                    badge
                }
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: 바뀌는 조건

    private var changedCard: some View {
        PumCard {
            wageRow
            divider
            unchangedRow
        }
    }

    /// 시급 전 → 후. 넘치면 값이 키 아래로 내려간다
    private var wageRow: some View {
        let key = Text(ContractChangeState.wageTitle).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        let change = HStack(spacing: PumTokens.Space.s8) {
            Text(state.oldWageText).pumText(.body).foregroundStyle(PumColor.textTertiary).strikethrough()
            Image(systemName: "arrow.right").font(.footnote.weight(.semibold))
                .foregroundStyle(PumColor.textSecondary).accessibilityHidden(true)
            // 목업 17px 700 → headline bold
            Text(state.newWageText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.accent)
                .padding(.horizontal, PumTokens.Space.s12)
                .padding(.vertical, PumTokens.Space.s4)
                .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
        }
        return Button(action: onEditWage) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    key
                    Spacer(minLength: PumTokens.Space.s12)
                    change
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { key; change }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSending)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.wageSpoken))
        .accessibilityAddTraits(.isButton)
    }

    private var unchangedRow: some View {
        let key = Text(state.unchangedTitle).pumText(.body).foregroundStyle(PumColor.textSecondary)
        let summary = Text(state.unchangedSummary).pumText(.body, weight: .semibold)
            .foregroundStyle(PumColor.textPrimary).lineLimit(1)
        let chev = Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
        return Button(action: onShowUnchanged) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    key.fixedSize()
                    summary.frame(maxWidth: .infinity, alignment: .trailing)
                    chev
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    key
                    HStack(spacing: PumTokens.Space.s8) { summary; Spacer(minLength: 0); chev }
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.unchangedSpoken))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 언제부터

    private var whenCard: some View {
        PumCard {
            startRow(.nextPeriod, title: state.nextPeriodTitle, detail: state.nextPeriodDetail)
            divider
            startRow(.custom, title: ContractChangeState.customDateTitle, detail: nil)
        }
    }

    /// 공통 후보: 제목 + 설명 두 줄 라디오 행(10i와 같은 모양, PumRadioRow는 한 줄)
    private func startRow(_ option: ContractChangeStart, title: String, detail: String?) -> some View {
        let isOn = start == option
        return Button {
            guard !isSending else { return }
            if start != option {
                start = option
                onStartChanged(option)
            }
            if option == .custom { onPickDate() }
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let detail { Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSending)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ContractChangeState.startSpoken(title: title, detail: detail, isOn: isOn)))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 영향 · 예상 — 값은 서버, 조건이 다르면 값만 숨김

    private var impactCard: some View {
        PumCard {
            estimateRow
            divider
            fixedRow
        }
    }

    private var estimateRow: some View {
        let left = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.impactTitle).pumText(.body).foregroundStyle(PumColor.textSecondary)
            if let detail = impact?.detailText {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        let value = impact.map {
            Text(ContractChangeState.differenceText($0.differenceWon)).pumText(.body, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary).multilineTextAlignment(.trailing)
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                left.frame(maxWidth: .infinity, alignment: .leading)
                value
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { left; value }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var fixedRow: some View {
        let key = Text(ContractChangeState.beforeSignTitle).pumText(.body).foregroundStyle(PumColor.textSecondary)
        let value = Text(ContractChangeState.beforeSignValue).pumText(.body, weight: .semibold)
            .foregroundStyle(PumColor.textPrimary).multilineTextAlignment(.trailing)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key
                Spacer(minLength: PumTokens.Space.s12)
                value
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { key; value }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: 동작

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func send() {
        guard state.hasChanges, lock.begin() else { return }
        onSend { success in lock.finish(success: success) }
    }
}

#Preview("10c") { ContractChangeView(state: .sample) }
#Preview("10c · 큰 글자") { ContractChangeView(state: .sample).dynamicTypeSize(.xxxLarge) }
