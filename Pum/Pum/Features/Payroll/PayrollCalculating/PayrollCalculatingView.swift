// UI-IOS-21l · REQ-070 · REQ-095 — 급여 계산 중(사장님). 탭 바 없음.
// 끝나면 알림은 화면 밖(푸시) — 타이머 · 폴링 없음. 금액은 끝난 사람만, 카운트업 없음(M37).
import SwiftUI

struct PayrollCalculatingView: View {
    let state: PayrollCalculatingState
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var circleSize = Local.stepCircle
    @ScaledMetric(relativeTo: .body) private var barHeight = PumTokens.Space.s8

    init(state: PayrollCalculatingState = .sample, onBack: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
    }

    fileprivate enum Local {
        /// 상태 원 지름 — 원문 실측 약 24
        static let stepCircle: CGFloat = 24
        static let checkRatio: CGFloat = 0.45
        /// 회전 호: 지름 = 상태 원의 0.7 · 굵기 2.5 · 한 바퀴 .9s (21m과 같은 값)
        static let spinnerRatio: CGFloat = 0.7
        static let spinnerWidth: CGFloat = 2.5
        static let arcLength: CGFloat = 0.25
        static let spinSeconds: Double = 0.9
        /// 기다리는 중 빈 원 테두리
        static let emptyRingWidth: CGFloat = 1.5
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    PumCard {
                        ForEach(Array(state.rows.enumerated()), id: \.element.id) { index, row in
                            rowView(row, index: index, isLast: index == state.rows.count - 1)
                        }
                    }
                    .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: state.rows) // M37 행 fast
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    // MARK: 머리 · 제목 · 진행 막대

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(PayrollCalculatingState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(PayrollCalculatingState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.periodText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(PayrollCalculatingState.title).pumText(.title2, weight: .bold)
                .tracking(PumTokens.Tracking.title)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(state.progressText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .accessibilityLabel(Text(state.progressAccessibilityText))
            bar.padding(.top, PumTokens.Space.s8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.progressAccessibilityText))
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.bottom, PumTokens.Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 서버가 준 끝난 수 / 전체 수 비율만 그린다(금액 계산 아님)
    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                Capsule().fill(PumColor.accent)
                    .frame(width: geo.size.width * state.progressFraction)
            }
            .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: state.progressFraction) // M37
        }
        .frame(height: barHeight)
    }

    // MARK: 직원 행

    private func rowView(_ row: PayrollCalculatingRow, index: Int, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            statusMark(row.status)
            PumAvatar(name: row.name, colorIndex: row.colorIndex)
            // 금액은 넘치면 이름 아래로
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                    nameBlock(row)
                    Spacer(minLength: PumTokens.Space.s8)
                    amountLabel(row)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    nameBlock(row)
                    amountLabel(row)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.accessibilityText))
        .accessibilityValue(Text("\(index + 1)번째"))
    }

    private func nameBlock(_ row: PayrollCalculatingRow) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(row.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            if let detail = row.detailText {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func amountLabel(_ row: PayrollCalculatingRow) -> some View {
        if let amount = row.amountText {
            Text(amount).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        }
    }

    @ViewBuilder
    private func statusMark(_ status: PayrollCalculatingRow.Status) -> some View {
        switch status {
        case .done:
            Circle().fill(PumColor.surfaceFill)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: circleSize * Local.checkRatio, weight: .bold))
                        .foregroundStyle(PumColor.textPrimary)
                }
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
        case .calculating:
            ZStack {
                Circle().stroke(PumColor.surfaceFill, lineWidth: Local.spinnerWidth)
                    .padding(Local.spinnerWidth / 2)
                SpinningArc(reduceMotion: reduceMotion)
            }
            .frame(width: circleSize * Local.spinnerRatio, height: circleSize * Local.spinnerRatio)
            .frame(width: circleSize, height: circleSize)
            .accessibilityHidden(true)
        case .waiting:
            Circle().strokeBorder(PumColor.borderHairline, lineWidth: Local.emptyRingWidth)
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
        }
    }

    // MARK: 하단 고정

    private var footer: some View {
        PumButton(title: PayrollCalculatingState.buttonTitle, kind: .primary, isLoading: true,
                  loadingTitle: PayrollCalculatingState.buttonTitle, action: {})
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }
}

/// 진행 중 회전 호(21m과 같은 값 — 화면 전용 복사). 동작 줄이기가 켜져 있으면 돌지 않는다.
private struct SpinningArc: View {
    let reduceMotion: Bool
    @State private var spinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: PayrollCalculatingView.Local.arcLength)
            .stroke(PumColor.textPrimary,
                    style: StrokeStyle(lineWidth: PayrollCalculatingView.Local.spinnerWidth, lineCap: .round))
            .padding(PayrollCalculatingView.Local.spinnerWidth / 2)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(reduceMotion ? nil
                       : .linear(duration: PayrollCalculatingView.Local.spinSeconds).repeatForever(autoreverses: false),
                       value: spinning)
            .onAppear { if !reduceMotion { spinning = true } }
            .onChange(of: reduceMotion) { _, on in spinning = !on }
    }
}

#Preview("21l") { PayrollCalculatingView(state: .sample) }
#Preview("21l · 큰 글자") { PayrollCalculatingView(state: .sample).dynamicTypeSize(.accessibility3) }
