// UI-IOS-21m · REQ-022 · REQ-095 — 출근 판정 중(직원). 탭 바 없음. 위치를 추적하지 않는다.
// 상태 하나(판정 중)만 그린다. 10초 넘음 → 「다시 확인 / 사장님 확인 요청」(10w) 전환은 호출자 책임(타이머 없음).
import SwiftUI

struct CheckInJudgingView: View {
    let state: CheckInJudgingState
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var circleSize = Local.stepCircle

    init(state: CheckInJudgingState = .sample, onBack: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
    }

    fileprivate enum Local {
        /// 상태 원 지름 — 원문 실측 약 24 (10t · 10u와 같은 값)
        static let stepCircle: CGFloat = 24
        /// 체크 크기 = 원 지름의 0.45
        static let checkRatio: CGFloat = 0.45
        /// 회전 호 길이(원 둘레 비율) · 한 바퀴 시간(M36 스피너 .9s — 토큰 없음)
        /// 판정 중 표시 — 원문 실측: 지름 약 17(상태 원 칸의 0.7) · 연회색 고리 위 굵기 약 2.5 먹색 호
        static let spinnerRatio: CGFloat = 0.7
        static let spinnerWidth: CGFloat = 2.5
        static let arcLength: CGFloat = 0.25
        static let spinSeconds: Double = 0.9
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    PumCard {
                        ForEach(Array(state.steps.enumerated()), id: \.element.id) { index, step in
                            stepRow(step, isLast: index == state.steps.count - 1)
                        }
                    }
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

    // MARK: 머리 · 제목

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(CheckInJudgingState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(CheckInJudgingState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.workplaceName).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            Text(CheckInJudgingState.title).pumText(.title2, weight: .bold)
                .tracking(PumTokens.Tracking.title)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.bottom, PumTokens.Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 확인 카드

    private func stepRow(_ step: CheckInJudgingStep, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            statusMark(step.status)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(step.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(step.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
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
        .accessibilityLabel(Text(step.accessibilityText))
    }

    @ViewBuilder
    private func statusMark(_ status: CheckInJudgingStep.Status) -> some View {
        switch status {
        case .done:
            // 체크리스트 규칙: 회색 원 + 먹색 체크
            Circle().fill(PumColor.surfaceFill)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: circleSize * Local.checkRatio, weight: .bold))
                        .foregroundStyle(PumColor.textPrimary)
                }
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
        case .checking:
            // 원문: 연회색 고리 위를 도는 먹색 호(상태 원보다 작게)
            ZStack {
                Circle().stroke(PumColor.surfaceFill, lineWidth: Local.spinnerWidth)
                    .padding(Local.spinnerWidth / 2)
                SpinningArc(reduceMotion: reduceMotion)
            }
            .frame(width: circleSize * Local.spinnerRatio, height: circleSize * Local.spinnerRatio)
            .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
        }
    }

    // MARK: 하단 고정

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: CheckInJudgingState.buttonTitle, kind: .primary, isLoading: true, action: {})
            Text(CheckInJudgingState.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

/// 진행 중 회전 호(AdminConfirmCheckIn과 같은 값 — 화면 전용 복사). 동작 줄이기가 켜져 있으면 돌지 않는다.
private struct SpinningArc: View {
    let reduceMotion: Bool
    @State private var spinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: CheckInJudgingView.Local.arcLength)
            .stroke(PumColor.textPrimary,
                    style: StrokeStyle(lineWidth: CheckInJudgingView.Local.spinnerWidth, lineCap: .round))
            .padding(CheckInJudgingView.Local.spinnerWidth / 2)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(reduceMotion ? nil
                       : .linear(duration: CheckInJudgingView.Local.spinSeconds).repeatForever(autoreverses: false),
                       value: spinning)
            .onAppear { if !reduceMotion { spinning = true } }
            .onChange(of: reduceMotion) { _, on in spinning = !on }
    }
}

#Preview("21m") { CheckInJudgingView(state: .sample) }
#Preview("21m · 큰 글자") { CheckInJudgingView(state: .sample).dynamicTypeSize(.accessibility3) }
