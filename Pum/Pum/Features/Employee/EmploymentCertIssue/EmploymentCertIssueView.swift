// UI-IOS-19e · REQ-062 — 사장님 · 재직증명서 요청 확인 · 발급 (하위 화면, 탭 바 없음)
// 거절 확인 창 · 「다음부터 바로 발급」 동작은 원문 없음 — 클로저 · 값만 넘긴다.
import SwiftUI

struct EmploymentCertIssueView: View {
    let state: EmploymentCertIssueState
    var onBack: () -> Void
    var onDecline: () -> Void
    /// 선택 값과 끝났다고 알리는 클로저. done(true)면 성공(잠근 채), done(false)면 다시 누를 수 있다.
    var onIssue: (EmploymentCertIssueChoice, @escaping (Bool) -> Void) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var useSignature: Bool
    @State private var issueNext: Bool
    @State private var touchedSignature = false
    @State private var touchedNext = false
    @State private var isIssuing = false
    @State private var isIssued = false

    /// 표 이름 칸 폭(원문 약 88)
    @ScaledMetric(relativeTo: .footnote) private var labelWidth: CGFloat = 88

    init(state: EmploymentCertIssueState,
         onBack: @escaping () -> Void = {},
         onDecline: @escaping () -> Void = {},
         onIssue: @escaping (EmploymentCertIssueChoice, @escaping (Bool) -> Void) -> Void = { _, _ in }) {
        self.state = state
        self.onBack = onBack
        self.onDecline = onDecline
        self.onIssue = onIssue
        _useSignature = State(initialValue: state.useRegisteredSignature)
        _issueNext = State(initialValue: state.issueNextTime)
    }

    private var locked: Bool { isIssuing || isIssued }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    documentCard
                    choiceCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.useRegisteredSignature) { _, new in if !touchedSignature { useSignature = new } }
        .onChange(of: state.issueNextTime) { _, new in if !touchedNext { issueNext = new } }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(EmploymentCertIssueState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(EmploymentCertIssueState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { needsDecision; sender }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { needsDecision; sender }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.senderSpoken))
            Text(EmploymentCertIssueState.headerTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var needsDecision: some View {
        PumBadge(text: EmploymentCertIssueState.needsDecisionTitle, kind: .attention)
    }

    private var sender: some View {
        Text(state.senderText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 문서

    private var documentCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                Text(EmploymentCertIssueState.documentTitle).tracking(PumTokens.Space.s4) // 원문 넓은 자간 — pumText보다 안쪽에
                    .pumText(.headline, weight: .bold)
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    ForEach(Array(state.rows.enumerated()), id: \.offset) { _, row in
                        docRow(label: row.label, value: row.value)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(row.spoken))
                    }
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                closing
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.closingSpoken))
            }
            .padding(PumTokens.Size.rowPadX + PumTokens.Space.s4)
        }
    }

    /// 넘치면 이름 아래로 값이 내려간다
    private func docRow(label: String, value: String) -> some View {
        let l = Text(label).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        let v = Text(value).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                l.frame(width: labelWidth, alignment: .leading)
                v.frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { l; v }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var closing: some View {
        VStack(spacing: PumTokens.Space.s8) {
            Text(EmploymentCertIssueState.attestation).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s4) { signLine; signChip }
                VStack(spacing: PumTokens.Space.s4) { signLine; signChip }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var signLine: some View {
        Text(state.signLineText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var signChip: some View {
        Text(EmploymentCertIssueState.signatureChip).pumText(.caption, weight: .semibold)
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.horizontal, PumTokens.Space.s10)
            .padding(.vertical, PumTokens.Space.s6)
            .background(PumColor.surfaceFill, in: Capsule())
    }

    // MARK: 선택

    private var choiceCard: some View {
        PumCard {
            choiceRow(title: EmploymentCertIssueState.useSignatureTitle, subtitle: state.signatureSubtitle,
                      isOn: useSignature, spoken: state.signatureSpoken(isOn: useSignature)) {
                touchedSignature = true
                useSignature.toggle()
            }
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            choiceRow(title: EmploymentCertIssueState.issueNextTimeTitle, subtitle: EmploymentCertIssueState.issueNextTimeSubtitle,
                      isOn: issueNext, spoken: state.issueNextTimeSpoken(isOn: issueNext)) {
                touchedNext = true
                issueNext.toggle()
            }
        }
    }

    private func choiceRow(title: String, subtitle: String, isOn: Bool, spoken: String,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                CertCheckMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
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
        .disabled(locked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            buttons
            Text(state.footerNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let decline = PumButton(title: EmploymentCertIssueState.declineTitle, kind: .outline, action: onDecline)
            .disabled(locked)
        let issue = PumButton(title: EmploymentCertIssueState.issueTitle, isLoading: isIssuing, action: issueTapped)
            .disabled(isIssued || !EmploymentCertIssueState.canIssue(useRegisteredSignature: useSignature))
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { issue; decline }
        } else {
            RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { decline; issue } // 원문 약 1 : 1.5
        }
    }

    private func issueTapped() {
        guard !locked, EmploymentCertIssueState.canIssue(useRegisteredSignature: useSignature) else { return }
        isIssuing = true
        let choice = EmploymentCertIssueChoice(useRegisteredSignature: useSignature, issueNextTime: issueNext)
        onIssue(choice) { ok in
            isIssuing = false
            isIssued = ok
        }
    }
}

/// 체크 표시 — 원문: 켜짐은 회색 원 + 체크, 꺼짐은 둥근 네모 테두리(두 행이 서로 다른 모양으로 그려져 있어 켜짐 · 꺼짐으로 나눴다)
private struct CertCheckMark: View {
    let isOn: Bool
    @ScaledMetric(relativeTo: .footnote) private var size = PumSelectionStyle.markSize + PumTokens.Space.s4

    var body: some View {
        ZStack {
            if isOn {
                Circle().fill(PumColor.surfaceFill)
                Image(systemName: "checkmark").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textPrimary)
            } else {
                RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                    .strokeBorder(PumTokens.ColorToken.gray300, lineWidth: PumSelectionStyle.ringWidth)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 19c와 같은 값 — 공통 후보.
private struct RatioPairLayout: Layout {
    var ratio: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let widths = columnWidths(total: width)
        let height = zip(subviews, widths)
            .map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width)
        var x = bounds.minX
        for (view, width) in zip(subviews, widths) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func columnWidths(total: CGFloat) -> [CGFloat] {
        let unit = max(0, total - spacing) / (1 + ratio)
        return [unit, unit * ratio]
    }
}

#Preview("19e 원문") { EmploymentCertIssueView(state: .sample) }
#Preview("19e XXXL") { EmploymentCertIssueView(state: .sample).dynamicTypeSize(.accessibility3) }
