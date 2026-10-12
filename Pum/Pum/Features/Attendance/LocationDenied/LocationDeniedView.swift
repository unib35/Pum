// UI-IOS-6r · REQ-022 · REQ-095 — 위치 권한이 꺼져 있을 때 대체 경로(직원). 탭 바 없음.
// 「iPhone 설정으로 이동」은 호출자가 설정을 연다(화면은 URL을 열지 않음).
// 「매장 QR로 출근」 · 「관리자에게 수동 기록 요청」은 어떤 경우에도 잠그지 않는다(REQ-029).
import SwiftUI

struct LocationDeniedView: View {
    var state: LocationDeniedState
    var onBack: () -> Void
    var onOpenSettings: () -> Void
    var onUseQR: () -> Void
    var onRequestManual: () -> Void

    init(state: LocationDeniedState = .sample,
         onBack: @escaping () -> Void = {},
         onOpenSettings: @escaping () -> Void = {},
         onUseQR: @escaping () -> Void = {},
         onRequestManual: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onOpenSettings = onOpenSettings
        self.onUseQR = onUseQR
        self.onRequestManual = onRequestManual
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: LocationDeniedState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    stepsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text(LocationDeniedState.heading).pumText(.title2, weight: .bold)
                .tracking(PumTokens.Tracking.title)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(state.message).pumText(.footnote)
                .foregroundStyle(PumColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.bottom, PumTokens.Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(LocationDeniedState.steps.enumerated()), id: \.element.id) { index, step in
                    LocationDeniedStepRow(step: step, isLast: index == LocationDeniedState.steps.count - 1)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: LocationDeniedState.openSettingsTitle, action: onOpenSettings)
            PumButton(title: LocationDeniedState.useQRTitle, kind: .outline, action: onUseQR)
            Button(action: onRequestManual) {
                Text(LocationDeniedState.requestManualTitle).pumText(.footnote).underline()
                    .foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s8)
        .background(PumColor.bgApp)
    }
}

private struct LocationDeniedStepRow: View {
    let step: LocationDeniedStep
    let isLast: Bool
    @ScaledMetric(relativeTo: .body) private var badge = PumTokens.Space.s24 // 원문 번호 원 약 22

    var body: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text("\(step.number)")
                .pumText(.caption2, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: badge, height: badge)
                .background(PumColor.surfaceFill, in: Circle())
                .accessibilityHidden(true)
            Text(step.title).pumText(.callout, weight: .medium)
                .foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.spoken))
    }
}

#Preview("6r") { LocationDeniedView() }
#Preview("6r · 큰 글자") { LocationDeniedView().dynamicTypeSize(.xxxLarge) }
