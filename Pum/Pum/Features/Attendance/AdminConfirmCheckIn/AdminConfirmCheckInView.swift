// UI-IOS-10x · REQ-021 — 관리자 확인 방식: 누른 시각으로 요청, 사장님 확인 후 기록. 탭 바 · 하단 버튼 없음.
// 위치를 추적하지 않는다. 사업장 칩은 10v와 같게 누르지 않는 칩. 「요청 취소」 확인 창은 원문에 없어 클로저만 부른다.
import SwiftUI

struct AdminConfirmCheckInView: View {
    let state: AdminConfirmCheckInState
    var onCancelRequest: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: AdminConfirmCheckInState = .sample, onCancelRequest: @escaping () -> Void = {}) {
        self.state = state
        self.onCancelRequest = onCancelRequest
    }

    fileprivate enum Local {
        /// 칩 안 네모 — 원문 24
        static let chipMark: CGFloat = 24
        /// 단계 원 지름 — 원문 실측 약 24
        static let stepCircle: CGFloat = 24
        static let checkRatio: CGFloat = 0.45
        static let ringWidth: CGFloat = 1.5
        /// 진행 중 호 길이(원 둘레 비율) · 한 바퀴 시간(M36 스피너 .9s — 토큰 없음)
        static let arcLength: CGFloat = 0.25
        static let spinSeconds: Double = 0.9
    }

    @ScaledMetric(relativeTo: .body) private var circleSize = Local.stepCircle
    @ScaledMetric(relativeTo: .caption) private var chipMarkSize = Local.chipMark

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                topRow
                todayCard
                Text(AdminConfirmCheckInState.sectionTitle).pumText(.caption, weight: .bold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s8)
                    .padding(.top, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                stepsCard
                noticeCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PumColor.bgApp)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    // MARK: 위

    private var topRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                chip
                Spacer(minLength: PumTokens.Space.s8)
                dateLabel
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                chip
                dateLabel
            }
        }
    }

    private var dateLabel: some View {
        Text(state.dateText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    private var chip: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(state.workplaceInitial).pumText(.caption2, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: chipMarkSize, height: chipMarkSize)
                .background(PumColor.accent, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm - 1, style: .continuous))
                .accessibilityHidden(true)
            Text(state.workplaceName).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, PumTokens.Space.s4)
        .padding(.leading, PumTokens.Space.s4)
        .padding(.trailing, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
        .background(PumColor.surfaceCard, in: Capsule())
        .overlay(Capsule().stroke(PumColor.borderHairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: 오늘 근무

    private var todayCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    shiftBlock.frame(maxWidth: .infinity, alignment: .leading)
                    PumBadge(text: state.statusText, kind: .waiting)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    shiftBlock
                    PumBadge(text: state.statusText, kind: .waiting)
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .combine)
        }
    }

    private var shiftBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(AdminConfirmCheckInState.todayTitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            Text(state.shiftText).pumText(.title3, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(PumColor.textPrimary)
        }
    }

    // MARK: 단계

    private var stepsCard: some View {
        PumCard {
            ForEach(Array(state.steps.enumerated()), id: \.element.id) { i, step in
                if i > 0 { divider }
                stepRow(step, index: i)
            }
        }
    }

    private func stepRow(_ s: AdminConfirmCheckInState.Step, index: Int) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            stepCircle(s.status)
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
        .accessibilityLabel(Text(state.stepSpoken(at: index)))
    }

    /// 완료 = 회색 원 + 먹색 체크, 진행 중 = 원 테두리 위 회전 호(먹색), 아직 = 빈 원
    @ViewBuilder private func stepCircle(_ status: AdminConfirmCheckInState.StepStatus) -> some View {
        switch status {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: circleSize * Local.checkRatio, weight: .semibold))
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.surfaceFill, in: Circle())
                .accessibilityHidden(true)
        case .inProgress:
            ZStack {
                Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: Local.ringWidth)
                SpinningArc(reduceMotion: reduceMotion)
            }
            .frame(width: circleSize, height: circleSize)
            .accessibilityHidden(true)
        case .pending:
            Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: Local.ringWidth)
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
        }
    }

    // MARK: 확인 전에도 · 요청 취소

    private var noticeCard: some View {
        PumCard {
            noticeRow
            divider
            cancelRow
        }
    }

    private var noticeRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                noticeKey.frame(maxWidth: .infinity, alignment: .leading)
                noticeValue
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                noticeKey
                noticeValue
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.noticeAccessibilityLabel))
    }

    private var noticeKey: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.noticeTitle).font(PumTextStyle.body.font).fontWeight(.regular)
                .tracking(PumTokens.Tracking.body)
                .foregroundStyle(PumTokens.ColorToken.gray800)
            Text(state.noticeDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
    }

    private var noticeValue: some View {
        Text(state.noticeValue).pumText(.body, weight: .semibold)
            .foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    private var cancelRow: some View {
        Button(action: onCancelRequest) {
            HStack(spacing: PumTokens.Space.s12) {
                Text(AdminConfirmCheckInState.cancelTitle).pumText(.body, weight: .semibold)
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumTokens.ColorToken.gray300)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(AdminConfirmCheckInState.cancelTitle))
        .accessibilityAddTraits(.isButton)
    }
}

/// 원 테두리 위를 도는 먹색 호. 동작 줄이기(M22)가 켜져 있으면 돌지 않는다.
private struct SpinningArc: View {
    let reduceMotion: Bool
    @State private var spinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: AdminConfirmCheckInView.Local.arcLength)
            .stroke(PumColor.textPrimary,
                    style: StrokeStyle(lineWidth: AdminConfirmCheckInView.Local.ringWidth, lineCap: .round))
            .padding(AdminConfirmCheckInView.Local.ringWidth / 2)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(reduceMotion ? nil
                       : .linear(duration: AdminConfirmCheckInView.Local.spinSeconds).repeatForever(autoreverses: false),
                       value: spinning)
            .onAppear { if !reduceMotion { spinning = true } }
            .onChange(of: reduceMotion) { _, on in spinning = !on } // 화면이 떠 있는 동안 켜도 멈춤
    }
}

#Preview("10x") { AdminConfirmCheckInView(state: .sample) }
#Preview("10x · 큰 글자") { AdminConfirmCheckInView(state: .sample).dynamicTypeSize(.accessibility3) }
