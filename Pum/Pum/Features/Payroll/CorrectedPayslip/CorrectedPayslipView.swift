// UI-IOS-10h · REQ-075 — 직원 · 정정 명세서 (하위 화면, 탭 바 없음)
// 먹색 머리 카드 모양은 1m 급여명세서와 같다. 직원이 이의를 제기하는 버튼은 원문에 없다.
import SwiftUI

struct CorrectedPayslipView: View {
    var state: CorrectedPayslipState = .sample
    var onBack: () -> Void = {}
    var onShowOriginal: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize

    /// 디자인 10h 「정정본」 배지: 흰색 14% 바탕(먹색 위). 공통 후보
    private let badgeFillOpacity = 0.14
    /// 라벨 색 #3A4150 = gray-800
    private let labelColor = PumTokens.ColorToken.gray800

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: CorrectedPayslipState.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    slip
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        Text(CorrectedPayslipState.recordsSection).pumText(.caption, weight: .bold)
                            .foregroundStyle(PumColor.textSecondary)
                            .padding(.horizontal, PumTokens.Space.s4)
                            .accessibilityAddTraits(.isHeader)
                        recordsCard
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: CorrectedPayslipState.originalTitle, kind: .outline, action: onShowOriginal)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    // MARK: 카드

    private var slip: some View {
        let r = PumTokens.Radius.lg
        return VStack(spacing: 0) { slipHead; slipBody }
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .pumRing(.hairline, cornerRadius: r)
    }

    private var slipHead: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(state.headerCaption).pumText(.caption, weight: .medium)
                        .foregroundStyle(PumColor.textOnInverseSecondary)
                    Text(state.workplaceName).pumText(.title3).foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: PumTokens.Space.s8)
                Text(CorrectedPayslipState.badgeText).pumText(.caption, weight: .semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, PumTokens.Space.s10)
                    .padding(.vertical, PumTokens.Space.s4)
                    .background(Color.white.opacity(badgeFillOpacity),
                                in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            }
            infoCells
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse)
    }

    /// 3칸: 좁으면(큰 글자) 세로로
    private var infoCells: some View {
        let cells: [(String, String)] = [("직원", state.employeeName), ("정정일", state.correctedDateText), ("정정", state.correctionCountText)]
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    ForEach(cells, id: \.0) { infoCell($0.0, $0.1) }
                }
            } else {
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    ForEach(cells, id: \.0) { infoCell($0.0, $0.1) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textOnInverseSecondary)
            Text(value).pumText(.callout).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var slipBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            keyValue(CorrectedPayslipState.netLabel) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { oldAmount; newAmount }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) { oldAmount; newAmount } // 넘치면 아래로
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.netAccessibility))
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            keyValue(CorrectedPayslipState.deltaLabel) {
                Text(state.deltaText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.statusDone)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.deltaAccessibility))
            Text(state.payoutNote).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumTokens.ColorToken.green700)
                .padding(.horizontal, PumTokens.Space.s16)
                .padding(.vertical, PumTokens.Space.s10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        }
        .padding(.horizontal, PumTokens.Space.s20)
        .padding(.vertical, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceCard)
    }

    private func keyValue<V: View>(_ label: String, @ViewBuilder value: () -> V) -> some View {
        let v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                keyLabel(label); Spacer(minLength: PumTokens.Space.s8); v
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { keyLabel(label); v } // 키 – 값 세로
        }
        .padding(.vertical, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    private func keyLabel(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(labelColor)
    }

    private var oldAmount: some View {
        Text(state.beforeText).pumText(.callout, weight: .regular)
            .strikethrough().foregroundStyle(PumColor.textTertiary)
    }

    private var newAmount: some View {
        Text(state.afterText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    // MARK: 바뀐 기록

    private var recordsCard: some View {
        PumCard {
            ForEach(state.records) { r in
                recordRow(r)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            }
            reasonRow
        }
    }

    private func recordRow(_ r: CorrectedRecord) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    title(r); Spacer(minLength: PumTokens.Space.s8); PumBadge(text: r.sourceText, kind: .waiting)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { title(r); PumBadge(text: r.sourceText, kind: .waiting) }
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    change(r); Spacer(minLength: PumTokens.Space.s8); impact(r)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { change(r); impact(r) }
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.accessibilityText))
    }

    private func title(_ r: CorrectedRecord) -> some View {
        Text(r.titleText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private func change(_ r: CorrectedRecord) -> some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(r.beforeTime).pumText(.body, weight: .regular).strikethrough().foregroundStyle(PumColor.textTertiary)
            Image(systemName: "arrow.right").font(.footnote.weight(.semibold))
                .foregroundStyle(PumColor.textPrimary).accessibilityHidden(true)
            Text(r.afterTime).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
    }

    private func impact(_ r: CorrectedRecord) -> some View {
        Text(r.impactText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private var reasonRow: some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.reasonLabel).pumText(.body, weight: .regular).foregroundStyle(labelColor)
            Text(state.reasonNote).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        let reason = Text(state.reasonText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { texts; Spacer(minLength: 0); reason.multilineTextAlignment(.trailing) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; reason }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.reasonAccessibility))
    }
}

#Preview("10h") { CorrectedPayslipView(state: .sample) }
#Preview("10h · 큰 글자") { CorrectedPayslipView(state: .sample).dynamicTypeSize(.accessibility3) }
