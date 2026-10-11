// UI-IOS-1v · REQ-107 — 급여 확정 확인 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
enum PayrollConfirmLocal {
    /// 점 목록 점 지름(목업 약 4) — space-4
    static let bulletDot: CGFloat = PumTokens.Space.s4
}

struct PayrollConfirmSheet: View {
    @Binding var state: PayrollConfirmState
    var onConfirm: () -> Void = {}
    var onCancel: () -> Void = {}

    @ScaledMetric(relativeTo: .footnote) private var dot = PayrollConfirmLocal.bulletDot

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(state.sheetTitle).pumText(.title2, weight: .bold) // 24px 700
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            summary
            notes
            toggles
            VStack(spacing: PumTokens.Space.s4) {
                PumButton(title: "급여 확정", kind: .primary, isLoading: state.isConfirming, action: onConfirm)
                PumButton(title: "취소", kind: .text, action: onCancel)
                    .disabled(state.isConfirming)
            }
            .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 요약 카드

    private var summary: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) { total }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) { total }
                }
                Rectangle().fill(PumTokens.ColorToken.borderHairline).frame(height: 1)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(state.summaryLeft)
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(state.summaryRight)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.summaryLeft)
                        Text(state.summaryRight)
                    }
                }
                .pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("총 지급액 \(state.amountText), \(state.summaryLeft), \(state.summaryRight)"))
        }
    }

    @ViewBuilder private var total: some View {
        Text("총 지급액").pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px
        Spacer(minLength: PumTokens.Space.s8)
        Text(state.amountText).pumText(.title2, weight: .bold).foregroundStyle(PumColor.textPrimary) // 26px 700 → title2
            .lineLimit(1).minimumScaleFactor(0.5)
    }

    // MARK: 점 목록

    private var notes: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            ForEach(Array(state.notes.enumerated()), id: \.offset) { _, n in
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    Circle().fill(PumColor.textPrimary).frame(width: dot, height: dot)
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + PumTokens.Space.s4 }
                        .accessibilityHidden(true)
                    (Text(n.head) + Text(n.bold).fontWeight(.bold).foregroundColor(PumTokens.ColorToken.gray800) + Text(n.tail))
                        .pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(n.text + ".")) // 각 줄 한 문장
            }
        }
        .padding(.horizontal, PumTokens.Space.s4) // 원문: 카드보다 약 4 안쪽
    }

    // MARK: 토글

    private var toggles: some View {
        PumCard {
            VStack(spacing: 0) {
                toggleRow(PayrollConfirmState.payslipTitle, PayrollConfirmState.payslipSubtitle,
                          label: state.payslipAccessibilityLabel, isOn: $state.sendsPayslip)
                Rectangle().fill(PumTokens.ColorToken.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Space.s16) // 행 사이 hairline 안쪽
                toggleRow(PayrollConfirmState.reminderTitle, state.reminderLabel,
                          label: state.reminderAccessibilityLabel, isOn: $state.remindsPayDay)
            }
        }
        .animation(PumMotion.fast, value: state.sendsPayslip) // M2
        .animation(PumMotion.fast, value: state.remindsPayDay)
    }

    private func toggleRow(_ title: String, _ sub: String, label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 14px 600
                Text(sub).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary) // 12px
            }
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text(label))
    }
}
