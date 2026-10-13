// UI-IOS-6e · REQ-023 — 위치 권한 안내 시트(C9). 위치는 출퇴근 버튼을 누르는 순간 1회만.
// 「계속」은 호출자가 시스템 위치 권한을 요청한다. 시트를 닫아도 출근은 막지 않는다(REQ-029) —
// 닫기(막 누르기 · VoiceOver 닫기)는 「위치 없이 QR로만 출근할게요」와 같은 뜻(onUseQROnly)이다.
import SwiftUI

struct LocationPermissionIntroView: View {
    let state: LocationPermissionIntroState
    var onContinue: () -> Void
    var onUseQROnly: () -> Void
    @State private var isPresented: Bool

    init(state: LocationPermissionIntroState = .sample,
         isPresented: Bool = true,
         onContinue: @escaping () -> Void = {},
         onUseQROnly: @escaping () -> Void = {}) {
        self.state = state
        self.onContinue = onContinue
        self.onUseQROnly = onUseQROnly
        _isPresented = State(initialValue: isPresented)
    }

    var body: some View {
        LocationPermissionBackdrop(state: state)
            .pumBottomSheet(isPresented: $isPresented, onDismiss: onUseQROnly) {
                LocationPermissionSheetContent(state: state, onContinue: proceed, onUseQROnly: skip)
            }
    }

    private func proceed() {
        isPresented = false
        onContinue()
    }

    private func skip() {
        isPresented = false
        onUseQROnly()
    }
}

// MARK: - 뒤 화면 (첫 근무 홈, 원문 그대로)

private struct LocationPermissionBackdrop: View {
    let state: LocationPermissionIntroState

    var body: some View {
        VStack(spacing: PumTokens.Space.s16) {
            HStack {
                PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
                Spacer()
                PumIconButton(systemImage: "bell", label: "알림") {}
            }
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        Text(state.shiftDateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                        Text(state.shiftTimeText).pumText(.hero).foregroundStyle(PumColor.textPrimary)
                    }
                    PumButton(title: state.clockInTitle) {}
                }
                .padding(PumTokens.Space.s18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PumColor.bgApp)
    }
}

// MARK: - 시트 내용

private struct LocationPermissionSheetContent: View {
    let state: LocationPermissionIntroState
    let onContinue: () -> Void
    let onUseQROnly: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text("\(LocationPermissionIntroState.headingFirstLine)\n\(LocationPermissionIntroState.headingSecondLine)")
                .pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Text(state.headingPlain))
                .accessibilityAddTraits(.isHeader)
            PumCard {
                VStack(spacing: 0) {
                    ForEach(Array(state.reasons.enumerated()), id: \.element.id) { index, reason in
                        if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                        LocationPermissionReasonRow(reason: reason)
                    }
                }
                .padding(.horizontal, PumTokens.Space.s16)
            }
            Text("\(LocationPermissionIntroState.hintBefore)\(Text(LocationPermissionIntroState.hintStrong).bold())\(LocationPermissionIntroState.hintAfter)")
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityLabel(Text(state.hintPlain))
            PumButton(title: LocationPermissionIntroState.continueTitle, action: onContinue)
            // 원문 링크 높이 약 20(14px 글자) — 누름 영역 44는 유지, 배치 높이만 20
            PumButton(title: LocationPermissionIntroState.qrOnlyTitle, kind: .text, size: .small, action: onUseQROnly)
                .padding(.vertical, -(PumTokens.Size.tapMin - PumTokens.Space.s20) / 2)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s12)
    }
}

private struct LocationPermissionReasonRow: View {
    let reason: LocationPermissionReason
    @ScaledMetric private var badge = PumTokens.Space.s20 // 원문 번호 원 약 20

    var body: some View {
        HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            Text("\(reason.number)")
                .pumText(.caption2, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: badge, height: badge)
                .background(PumColor.textPrimary, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(reason.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(reason.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(reason.spoken))
    }
}

#Preview("6e 위치 권한 안내") {
    LocationPermissionIntroView()
}
