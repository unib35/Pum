// UI-IOS-19f · REQ-062 — 직원 · 발급된 재직증명서 (하위 화면, 탭 바 없음)
// 복사 · 공유 · PDF 저장은 클로저만 부른다(클립보드 · 시트 · 파일 처리는 호출하는 쪽 몫). 복사 뒤 안내는 원문 없음.
import SwiftUI

struct EmploymentCertIssuedView: View {
    let state: EmploymentCertIssuedState
    var onBack: () -> Void
    var onCopy: () -> Void
    var onShare: () -> Void
    var onSavePDF: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// 표 이름 칸 폭(원문 약 88)
    @ScaledMetric(relativeTo: .footnote) private var labelWidth: CGFloat = 88

    init(state: EmploymentCertIssuedState,
         onBack: @escaping () -> Void = {},
         onCopy: @escaping () -> Void = {},
         onShare: @escaping () -> Void = {},
         onSavePDF: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onCopy = onCopy
        self.onShare = onShare
        self.onSavePDF = onSavePDF
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    header
                    documentCard
                    codeCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(EmploymentCertIssuedState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(EmploymentCertIssuedState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { issuedBadge; issuedLine }
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) { issuedBadge; issuedLine }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.issuedSpoken))
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var issuedBadge: some View {
        PumBadge(text: EmploymentCertIssuedState.issuedTitle, kind: .done)
    }

    private var issuedLine: some View {
        Text(state.issuedLineText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 문서

    private var documentCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) { // 원문 gap 9 → 가까운 10
                Text(EmploymentCertIssuedState.documentTitle).tracking(PumTokens.Space.s4) // 원문 넓은 자간 — pumText보다 안쪽에
                    .pumText(.title3, weight: .bold) // 원문 19px — 가장 가까운 단계 20
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, PumTokens.Space.s8) // 원문 제목 아래 8
                    .accessibilityAddTraits(.isHeader)
                table(state.personRows)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.vertical, PumTokens.Space.s4) // 원문 구분선 위아래 4
                table(state.shopRows)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.top, PumTokens.Space.s2) // 원문 구분선 위 2
                closing
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.closingSpoken))
            }
            .padding(.top, PumTokens.Space.s24) // 원문 padding 22 22 18 → 가까운 24 24 18
            .padding(.horizontal, PumTokens.Space.s24)
            .padding(.bottom, PumTokens.Space.s18)
        }
    }

    private func table(_ rows: [EmploymentCertIssuedRow]) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                docRow(label: row.label, value: row.value)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(row.spoken))
            }
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
            Text(EmploymentCertIssuedState.attestation).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
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
        Text(EmploymentCertIssuedState.signatureChip).pumText(.caption, weight: .semibold)
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.horizontal, PumTokens.Space.s10)
            .padding(.vertical, PumTokens.Space.s4) // 원문 padding 4 9
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
    }

    // MARK: 확인 번호

    private var codeCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) { codeTexts; copyButton }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { codeTexts; copyButton }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var codeTexts: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.codeText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(EmploymentCertIssuedState.verifyHint).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        // 번호만 한 글자씩 — 안내 문구는 보통 읽기
        .accessibilityLabel(Text("\(Text("\(EmploymentCertIssuedState.codeTitle), "))\(Text(state.verifyCode).speechSpellsOutCharacters())\(Text(", \(EmploymentCertIssuedState.verifyHint)"))"))
    }

    private var copyButton: some View {
        Button(action: onCopy) {
            Text(EmploymentCertIssuedState.copyTitle).pumText(.caption, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s12)
                .padding(.vertical, PumTokens.Space.s6) // 원문 작은 칩(약 42 × 27)
                .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)) // 원문 모서리 9 → 가까운 8
                // 누름 영역만 44 이상으로 키우고, 배치에는 원문 칩 크기만 쓴다(카드 높이가 늘지 않게)
                .padding(.vertical, PumTokens.Space.s12)
                .padding(.horizontal, PumTokens.Space.s4)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
                .padding(.horizontal, -PumTokens.Space.s4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(EmploymentCertIssuedState.codeTitle) \(EmploymentCertIssuedState.copyTitle)"))
    }

    // MARK: 하단

    private var footer: some View {
        buttons
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12)
            .padding(.bottom, PumTokens.Space.s10) // 원문 하단 44 − 홈 막대 안전 영역 34
            .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let share = PumButton(title: EmploymentCertIssuedState.shareTitle, kind: .outline, action: onShare)
        let save = PumButton(title: EmploymentCertIssuedState.savePDFTitle, action: onSavePDF)
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { save; share }
        } else {
            RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { share; save } // 원문 약 1 : 1.5
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 19c · 19e와 같은 값 — 공통 후보.
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

#Preview("19f 원문") { EmploymentCertIssuedView(state: .sample) }
#Preview("19f XXXL") { EmploymentCertIssuedView(state: .sample).dynamicTypeSize(.accessibility3) }
