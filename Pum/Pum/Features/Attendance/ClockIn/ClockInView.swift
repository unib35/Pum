// UI-IOS-1e · REQ-021 · REQ-022 · REQ-023 · REQ-029 — 출근 기록: QR 스캔 + 위치 확인
// 카메라 미리보기 자리는 먹색 바탕 + 스캔 틀만. 실제 카메라 · 위치 연결은 후속 이슈(이번 범위는 화면).
// 위치 판정은 주입한 상태 값으로 보여 준다 — 「확인됨」만 디자인이 있다.
import SwiftUI

struct ClockInView: View {
    var state: ClockInState = .sample
    var onBack: () -> Void = {}
    var onLocation: () -> Void = {}
    var onClockInByLocation: () -> Void = {}
    var onRequestManual: () -> Void = {}

    // 화면 전용 상수(먹색 위 반투명 · 스캔 틀). 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 먹색 위 반투명 흰 원(목업 rgba 흰색 약 14%)
        static let circleFill = Color.white.opacity(0.14)
        /// 스캔 틀 한 변 — 원문 240
        static let frameSide: CGFloat = 240
        /// 위 · 아래 둥근 버튼 지름 — 원문 40(누름 영역은 44 유지)
        static let circleSize: CGFloat = 40
        static let frameStroke: CGFloat = 3
        static let checkCircle: CGFloat = 36
        /// 체크 표시 크기: 목업 원 36 안 약 13px
        static let checkGlyph: CGFloat = 14
    }

    /// 「관리자에게 수동 기록 요청」 글자 한 줄 높이(원문 13px × 1.5) — 큰 글자에서 함께 커진다
    @ScaledMetric(relativeTo: .footnote) private var manualLineHeight: CGFloat = 19.5

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geo in
                // 시트 바탕을 홈 인디케이터 영역까지 잇기 위해 아래 안전 영역을 무시하고, 그만큼 시트 안쪽 여백을 더한다
                let bottomInset = geo.safeAreaInsets.bottom
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: PumTokens.Space.s24)
                        scanArea(width: geo.size.width)
                        Spacer(minLength: PumTokens.Space.s24)
                        sheet(bottomInset: bottomInset)
                    }
                    .frame(minHeight: geo.size.height + bottomInset)
                }
                .scrollBounceBehavior(.basedOnSize)
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .background(PumColor.surfaceInverse.ignoresSafeArea())
        // 먹색 바탕이라 상태 표시줄 글자를 흰색으로 — 화면에서 preferredColorScheme은 바꾸지 않는다
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: 헤더

    private var header: some View {
        ZStack {
            Text("출근 기록").pumText(.headline, weight: .semibold).foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                circleButton("chevron.left", label: "뒤로", action: onBack)
                Spacer()
                circleButton("scope", label: "위치 확인", action: onLocation)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private func circleButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: PumLayout.navIcon, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: Local.circleSize, height: Local.circleSize)
                .background(Local.circleFill, in: Circle())
                // 누름 영역 44 유지, 배치는 원문 40
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                .padding(-(PumTokens.Size.tapMin - Local.circleSize) / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    // MARK: 스캔 틀 · 안내

    private func scanArea(width: CGFloat) -> some View {
        let side = min(Local.frameSide, width)
        return VStack(spacing: PumTokens.Space.s24) {
            ClockInScanFrame()
                .stroke(.white, style: StrokeStyle(lineWidth: Local.frameStroke, lineCap: .round, lineJoin: .round))
                .frame(width: side, height: side)
                .accessibilityElement()
                .accessibilityLabel(Text("QR 스캔 영역"))
            VStack(spacing: PumTokens.Space.s4) {
                // 목업 18px 600 → headline(17) semibold
                Text(state.scanTitle).pumText(.headline, weight: .semibold).foregroundStyle(.white)
                Text(state.scanHint).pumText(.footnote).foregroundStyle(PumColor.textOnInverseSecondary) // 목업 55% — 충돌 #24에 따라 공통 70%
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, PumTokens.Size.screenPad)
        }
    }

    // MARK: 하단 시트(C9 바텀시트 모양, 고정)

    private func sheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: PumTokens.Space.s12) {
            if state.locationStatus == .confirmed { locationCard } // 다른 상태는 디자인 없음
            scheduleLine
            PumButton(title: "QR 없이 위치로 출근", kind: .outline, action: onClockInByLocation)
            Button(action: onRequestManual) {
                Text("관리자에게 수동 기록 요청").pumText(.footnote).underline()
                    .foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                    // 누름 영역 44 유지, 배치 높이는 글자 한 줄(원문)
                    .padding(.vertical, -max(0, PumTokens.Size.tapMin - manualLineHeight) / 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s20)
        .padding(.bottom, PumTokens.Space.s10 + bottomInset) // 원문 아래 44 − 홈 막대 34
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: PumTokens.Radius.xl, topTrailingRadius: PumTokens.Radius.xl, style: .continuous)
                .fill(PumColor.bgApp)
        )
    }

    private var locationCard: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                Image(systemName: "checkmark")
                    .font(.system(size: Local.checkGlyph, weight: .bold))
                    .foregroundStyle(PumColor.statusDone) // 「확인됨」 = 상태 표시라 초록(단계 완료의 무채색 규칙과 별개)
                    .frame(width: Local.checkCircle, height: Local.checkCircle)
                    .background(PumColor.statusDoneSoft, in: Circle())
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    // 목업 14px 600 → callout semibold
                    Text("현재 위치 확인됨").pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.locationDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.locationAccessibilityText))
    }

    private var scheduleLine: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                plannedLabel
                Spacer(minLength: PumTokens.Space.s8)
                onTimeLabel
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                plannedLabel
                onTimeLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var plannedLabel: some View {
        Text(state.plannedText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    @ViewBuilder private var onTimeLabel: some View {
        if let note = state.onTimeNote {
            Text(note).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.statusDone)
        }
    }
}

#Preview("1e") { ClockInView() }
#Preview("1e · 큰 글자") { ClockInView().dynamicTypeSize(.accessibility2) }
