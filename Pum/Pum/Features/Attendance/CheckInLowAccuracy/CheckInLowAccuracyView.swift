// UI-IOS-10w · REQ-022 · REQ-029 — 출근 판정 · 위치 오차가 클 때: 판정 보류, 기록하지 않고 QR이나 확인 요청으로. 탭 바 없음.
// 오차 · 허용은 서버 판정 값 그대로(화면 계산 없음). 지도는 그림 자리만(MapKit 없음). 주황 = 처리 필요.
// 「매장 QR로 확인」 · 「사장님에게 확인 요청」은 다시 시도 중에도 막지 않는다(REQ-029).
import SwiftUI

struct CheckInLowAccuracyView: View {
    var state: CheckInLowAccuracyState
    var onClose: () -> Void
    /// 다시 시도. 끝나면 done(성공 여부)을 부른다. 연결 전 기본값은 done(false).
    var onRetry: (_ done: @escaping (Bool) -> Void) -> Void
    var onScanQR: () -> Void
    var onRequestOwner: () -> Void

    @State private var lock = CheckInLowAccuracyLock()
    @AccessibilityFocusState private var titleFocused: Bool

    init(state: CheckInLowAccuracyState = .sample,
         onClose: @escaping () -> Void = {},
         onRetry: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) },
         onScanQR: @escaping () -> Void = {},
         onRequestOwner: @escaping () -> Void = {}) {
        self.state = state
        self.onClose = onClose
        self.onRetry = onRetry
        self.onScanQR = onScanQR
        self.onRequestOwner = onRequestOwner
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 값)
    private enum Local {
        static let mapHeight: CGFloat = 150
        static let roadWidth: CGFloat = 10
        static let verticalRoadX: CGFloat = 0.30
        static let horizontalRoadY: CGFloat = 0.46
        /// 오차 범위 큰 원 지름(원문 약 150) · 점선 두께 · 점선 간격
        static let errorSize: CGFloat = 150
        static let errorStroke: CGFloat = 1
        static let errorDash: [CGFloat] = [4, 3]
        /// 반경 원 지름 · 테두리 · 안쪽 네모 — 원문 약 63 · 2 · 13
        static let pinSize: CGFloat = 64
        static let pinStroke: CGFloat = 2
        static let pinInner: CGFloat = 14
        /// 사업장 표시 · 오차 원 · 내 위치 점 위치 비율(원문)
        static let pinX: CGFloat = 0.50 // 원문: 사업장은 지도 가운데
        static let pinY: CGFloat = 0.50
        static let errorX: CGFloat = 0.58
        static let errorY: CGFloat = 0.50
        static let dotX: CGFloat = 0.58
        static let dotY: CGFloat = 0.46
        /// 내 위치 점 — 원문 약 20 · 흰 테두리 3
        static let dotSize: CGFloat = 14
        static let dotRing: CGFloat = 3
        static let glyph: CGFloat = 14
    }

    @ScaledMetric(relativeTo: .body) private var statusCircle = PumLayout.avatar - PumTokens.Space.s12

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    PumSectionHeader(title: CheckInLowAccuracyState.sectionTitle)
                    checkCard
                    mapCard
                    if !state.alternatives.isEmpty {
                        PumSectionHeader(title: CheckInLowAccuracyState.alternativesTitle)
                        alternativesCard
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
        .task {
            try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
            titleFocused = true
        }
    }

    // MARK: 헤더

    private var header: some View {
        ZStack {
            Text(CheckInLowAccuracyState.screenTitle).pumText(.headline, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.subtitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            Text(CheckInLowAccuracyState.title).pumText(.title2, weight: .bold)
                .tracking(PumTokens.Tracking.title)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.bottom, PumTokens.Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 확인 카드

    private var checkCard: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                // 판정 보류는 주의(주황 = 처리 필요)
                Text("!").font(.system(size: Local.glyph, weight: .heavy))
                    .foregroundStyle(PumColor.statusAttention)
                    .frame(width: statusCircle, height: statusCircle)
                    .background(PumColor.statusAttentionSoft, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(CheckInLowAccuracyState.locationTitle).font(PumTextStyle.body.font).fontWeight(.semibold)
                        .tracking(PumTokens.Tracking.body)
                        .foregroundStyle(PumColor.textPrimary)
                    Text(state.locationDetail).pumText(.caption).foregroundStyle(PumColor.statusAttention)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.locationAccessibilityLabel))
        }
    }

    // MARK: 지도 카드

    private var mapCard: some View {
        PumCard {
            VStack(spacing: 0) {
                mapPlaceholder
                    .accessibilityHidden(true) // 그림은 숨기고 아래 문장만 읽는다
                Text(state.hint).pumText(.footnote)
                    .foregroundStyle(PumTokens.ColorToken.gray700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, PumTokens.Space.s14)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
    }

    /// 공통 후보 — 지도 자리 그림 + 오차 범위(점선 원). 10u와 같은 길 · 바탕.
    private var mapPlaceholder: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                PumTokens.ColorToken.gray200
                Rectangle().fill(PumTokens.ColorToken.gray100)
                    .frame(width: Local.roadWidth, height: h)
                    .offset(x: w * Local.verticalRoadX - Local.roadWidth / 2)
                Rectangle().fill(PumTokens.ColorToken.gray100)
                    .frame(width: w, height: Local.roadWidth)
                    .offset(y: h * Local.horizontalRoadY - Local.roadWidth / 2)
                // 오차 범위: 회색 반투명 큰 원 + 점선 테두리
                ZStack {
                    Circle().fill(PumTokens.ColorToken.gray400.opacity(0.25))
                    Circle().stroke(PumColor.textSecondary,
                                    style: StrokeStyle(lineWidth: Local.errorStroke, dash: Local.errorDash))
                }
                .frame(width: Local.errorSize, height: Local.errorSize)
                .position(x: w * Local.errorX, y: h * Local.errorY)
                // 사업장 표시: 파랑 테두리 반경 원 안 먹색 네모
                ZStack {
                    Circle().fill(PumColor.accentSoft)
                    Circle().stroke(PumColor.accent, lineWidth: Local.pinStroke)
                    RoundedRectangle(cornerRadius: PumTokens.Radius.xs / 2, style: .continuous)
                        .fill(PumColor.surfaceInverse)
                        .frame(width: Local.pinInner, height: Local.pinInner)
                }
                .frame(width: Local.pinSize, height: Local.pinSize)
                .position(x: w * Local.pinX, y: h * Local.pinY)
                Circle().fill(PumColor.accent)
                    .frame(width: Local.dotSize, height: Local.dotSize)
                    .overlay(Circle().stroke(.white, lineWidth: Local.dotRing))
                    .position(x: w * Local.dotX, y: h * Local.dotY)
                Text(CheckInLowAccuracyState.mapLabel).pumText(.caption2, weight: .semibold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.leading, PumTokens.Space.s12)
                    .padding(.bottom, PumTokens.Space.s10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: Local.mapHeight)
        .clipped()
    }

    // MARK: 다른 방법

    private var alternativesCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(state.alternatives.enumerated()), id: \.element.id) { index, alt in
                    Button { perform(alt) } label: {
                        row(alt, isLast: index == state.alternatives.count - 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // 다시 시도 중에도 막지 않는다(REQ-029)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.accessibilityLabel(for: alt)))
                }
            }
        }
    }

    /// 공통 후보 — 키 · 값 › 행(10u와 같은 모양). 큰 글자에서는 키–값을 세로로 쌓는다.
    private func row(_ alt: CheckInLowAccuracyState.Alternative, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                keyText(alt.title).frame(maxWidth: .infinity, alignment: .leading)
                keyText(alt.detail).multilineTextAlignment(.trailing)
                chevron
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    keyText(alt.title)
                    keyText(alt.detail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                chevron
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
    }

    private func keyText(_ text: String) -> some View {
        Text(text).font(PumTextStyle.body.font).fontWeight(.semibold)
            .tracking(PumTokens.Tracking.body)
            .foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.leading)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.body.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled)
            .accessibilityHidden(true)
    }

    // MARK: 바닥

    private var footer: some View {
        PumButton(title: CheckInLowAccuracyState.retryTitle, kind: .outline, isLoading: lock.isChecking,
                  loadingTitle: CheckInLowAccuracyState.retryingTitle, action: retry)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s8)
            .background(PumColor.bgApp)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 끝나면 푼다
    private func retry() {
        guard lock.begin() else { return }
        onRetry { _ in lock.finish() }
    }

    private func perform(_ alt: CheckInLowAccuracyState.Alternative) {
        switch alt.kind {
        case .scanQR: onScanQR()
        case .requestOwner: onRequestOwner()
        }
    }
}

#Preview("10w") { CheckInLowAccuracyView(state: .sample) }
#Preview("10w · 큰 글자") { CheckInLowAccuracyView(state: .sample).dynamicTypeSize(.xxxLarge) }
