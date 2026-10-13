// UI-IOS-19b · REQ-082 — 새 시급 정하기 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
// 월 인건비 · 건수는 서버 값. 최저 미만이면 보내기 비활성 + 그 행에 이유(원문 없음).
import SwiftUI

struct NewWageSheet: View {
    let state: NewWageSheetState
    @Binding var draft: [String: Int]
    let isSending: Bool
    let isSent: Bool
    var onEdit: () -> Void = {}
    var onCancel: () -> Void = {}
    var onSend: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize
    /// 아바타 지름 — 원문 약 30
    @ScaledMetric(relativeTo: .callout) private var avatarSize: CGFloat = 30
    /// 입력칸 폭 — 원문 약 112
    @ScaledMetric(relativeTo: .body) private var fieldWidth: CGFloat = 112
    /// 입력 자릿수 상한 — 9자리(억 단위)
    private let maxDigits = 9

    private var locked: Bool { isSending || isSent }
    private var stacked: Bool { typeSize >= .xxxLarge }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            wageCard
            summaryCard
            buttons
            Text(NewWageSheetState.footerNotice)
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { title; Spacer(minLength: PumTokens.Space.s8); minimum }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title; minimum }
        }
        .padding(.top, PumTokens.Space.s4)
    }

    private var title: some View {
        Text(NewWageSheetState.title).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var minimum: some View {
        Text(state.minimumLine).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    // MARK: 직원별 입력

    private var wageCard: some View {
        PumCard {
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, e in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                wageRow(e)
            }
        }
    }

    private func wageRow(_ e: WageEmployee) -> some View {
        let below = state.isRowBelowMinimum(e, in: draft)
        return VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            Group {
                if stacked {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) { identity(e); field(e, below: below) }
                } else {
                    HStack(spacing: PumTokens.Space.s12) { identity(e); field(e, below: below) }
                }
            }
            if below {
                Text(NewWageSheetState.belowMinimumHint).pumText(.caption).foregroundStyle(PumColor.statusAttention)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    private func identity(_ e: WageEmployee) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: e.name, colorIndex: e.colorIndex, size: avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(e.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text("지금 \(WageYearTransitionState.won(e.currentWage))").pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(true) // 입력칸 라벨이 이름 · 지금 시급을 함께 읽는다
    }

    private func field(_ e: WageEmployee, below: Bool) -> some View {
        HStack(spacing: 0) {
            TextField("", text: text(for: e))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .pumText(.body, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary)
                .tint(PumColor.accent)
                .disabled(locked)
                .accessibilityLabel(Text(state.inputLabel(e)))
                .accessibilityValue(Text(WageYearTransitionState.won(state.wage(e.id, in: draft))))
                .accessibilityHint(Text(below ? NewWageSheetState.belowMinimumHint : ""))
            Text("원").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
        .frame(width: stacked ? nil : fieldWidth)
        .frame(maxWidth: stacked ? .infinity : nil)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .pumRing(below ? .attention : .hairline, cornerRadius: PumTokens.Radius.md)
    }

    /// 숫자만 받고 콤마를 붙여 보여 준다 — 저장은 정수(원)
    private func text(for e: WageEmployee) -> Binding<String> {
        Binding(
            get: {
                let w = state.wage(e.id, in: draft)
                return w == 0 ? "" : PumFormat.amount(w)
            },
            set: { new in
                let digits = String(new.filter(\.isNumber).prefix(maxDigits))
                onEdit()
                draft[e.id] = Int(digits) ?? 0
            }
        )
    }

    // MARK: 요약

    private var summaryCard: some View {
        PumCard {
            summaryRow(title: NewWageSheetState.costTitle, detail: NewWageSheetState.costDetail, value: state.costValue)
            Divider().overlay(PumColor.borderHairline)
            summaryRow(title: NewWageSheetState.contractTitle, detail: NewWageSheetState.contractDetail, value: state.contractValue)
        }
    }

    private func summaryRow(title: String, detail: String, value: String) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(title).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textPrimary)
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title), \(detail)"))
        .accessibilityValue(Text(value))
    }

    // MARK: 버튼

    private var buttons: some View {
        let cancel = PumButton(title: NewWageSheetState.cancelTitle, kind: .outline, action: onCancel)
            .disabled(isSending)
        let send = PumButton(title: state.sendTitle, isLoading: isSending, loadingTitle: NewWageSheetState.sendingTitle, action: onSend)
            .disabled(!state.canSend(draft) || isSent)
            .accessibilityHint(Text(state.canSend(draft) ? "" : NewWageSheetState.belowMinimumHint))
        return Group {
            if stacked {
                VStack(spacing: PumTokens.Space.s8) { send; cancel }
            } else {
                WageRatioLayout(ratio: 1.5, gap: PumTokens.Space.s8) { cancel; send } // C1 PAIR — 취소 : 보내기 = 1 : 1.5
            }
        }
        .padding(.top, PumTokens.Space.s4)
    }
}

/// 두 칸을 1 : ratio 폭으로 나란히 놓는다(C1 PAIR)
private struct WageRatioLayout: Layout {
    let ratio: CGFloat
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        let h = subviews.map { $0.sizeThatFits(.init(width: w, height: nil)).height }.max() ?? 0
        return CGSize(width: w, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let unit = (bounds.width - gap) / (1 + ratio)
        let widths = [unit, unit * ratio]
        var x = bounds.minX
        for (i, s) in subviews.enumerated() {
            s.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: .init(width: widths[i], height: bounds.height))
            x += widths[i] + gap
        }
    }
}

#Preview("19b 시트") {
    @Previewable @State var draft = NewWageSheetState.sample.initialWages
    PumBottomSheetPanel { NewWageSheet(state: .sample, draft: $draft, isSending: false, isSent: false) }
}
