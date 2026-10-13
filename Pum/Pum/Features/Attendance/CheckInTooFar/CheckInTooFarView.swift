// UI-IOS-10u · REQ-022 · REQ-029 — 출근 판정 · 거리 초과: 기록하지 않고 대체 경로. 탭 바 없음.
// 거리 · 허용 · 정확도는 서버 판정 값 그대로 보여 준다(화면 계산 없음). 지도는 원문처럼 그림 자리만(MapKit · 실제 위치 표시 없음).
// 「사장님에게 확인 요청」은 요청 화면 원문이 없어 클로저만 부른다(두 곳 같은 동작). 정확도 100m 초과(판정 보류)는 10w — 이번 범위 아님.
import SwiftUI

struct CheckInTooFarView: View {
    var state: CheckInTooFarState
    var onClose: () -> Void
    /// 다시 확인. 끝나면 done(성공 여부)을 부른다 — 성공이면 부모가 10t로 바꾼다. 연결 전 기본값은 done(false).
    var onRetry: (_ done: @escaping (Bool) -> Void) -> Void
    var onRequestOwner: () -> Void

    @State private var lock = CheckInTooFarLock()
    @AccessibilityFocusState private var titleFocused: Bool

    init(state: CheckInTooFarState = .sample,
         onClose: @escaping () -> Void = {},
         onRetry: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) },
         onRequestOwner: @escaping () -> Void = {}) {
        self.state = state
        self.onClose = onClose
        self.onRetry = onRetry
        self.onRequestOwner = onRequestOwner
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 값)
    private enum Local {
        /// 지도 자리 높이 — 원문 약 133
        static let mapHeight: CGFloat = 132
        /// 지도 길 폭 — 원문 약 10
        static let roadWidth: CGFloat = 10
        /// 길 위치 비율(원문 가로 길 x 30% · 세로 길 y 46%)
        static let verticalRoadX: CGFloat = 0.30
        static let horizontalRoadY: CGFloat = 0.46
        /// 사업장 표시 지름 · 파랑 테두리 · 안쪽 먹색 네모 — 원문 40 · 2 · 12
        static let pinSize: CGFloat = 40
        static let pinStroke: CGFloat = 2
        static let pinInner: CGFloat = 12
        /// 내 위치 점 지름 · 흰 테두리 — 원문 약 20 · 3
        static let dotSize: CGFloat = 14
        static let dotRing: CGFloat = 3
        /// 내 위치 점 비율(원문 오른쪽 위)
        static let dotX: CGFloat = 0.86
        static let dotY: CGFloat = 0.18
        /// 상태 원 안 글리프 크기
        static let glyph: CGFloat = 14
    }

    @ScaledMetric(relativeTo: .body) private var checkCircle = PumLayout.avatar - PumTokens.Space.s12

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                        PumSectionHeader(title: CheckInTooFarState.sectionTitle)
                        checkCard
                    }
                    mapCard
                    infoCard
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
            Text(CheckInTooFarState.screenTitle).pumText(.headline, weight: .semibold)
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
            Text(CheckInTooFarState.title).pumText(.title2, weight: .bold)
                .tracking(PumTokens.Tracking.title)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 확인 카드

    private var checkCard: some View {
        PumCard {
            VStack(spacing: 0) {
                checkRow(title: CheckInTooFarState.qrTitle, detail: state.qrDetail, detailColor: PumColor.textSecondary,
                         failed: false, isLast: false)
                checkRow(title: CheckInTooFarState.locationTitle, detail: state.locationDetail, detailColor: PumColor.statusDanger,
                         failed: true, isLast: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.locationAccessibilityLabel))
            }
        }
    }

    /// 공통 후보 — 원 + 체크/✕ 상태 행(1e 위치 카드 · 10t와 같은 모양)
    private func checkRow(title: String, detail: String, detailColor: Color, failed: Bool, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            // 통과는 단계 완료의 무채색(회색 원 + 먹색 체크), 실패는 빨강(빨강 = 실패 · 누락)
            Image(systemName: failed ? "xmark" : "checkmark")
                .font(.system(size: Local.glyph, weight: .bold))
                .foregroundStyle(failed ? PumColor.statusDanger : PumColor.textPrimary)
                .frame(width: checkCircle, height: checkCircle) // 원문 약 24(10t와 같은 값)
                .background(failed ? PumColor.statusDangerSoft : PumColor.surfaceFill, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(title).font(PumTextStyle.body.font).fontWeight(.semibold)
                    .tracking(PumTokens.Tracking.body)
                    .foregroundStyle(PumColor.textPrimary)
                Text(detail).pumText(.caption).foregroundStyle(detailColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 지도 카드

    private var mapCard: some View {
        PumCard {
            VStack(spacing: 0) {
                mapPlaceholder
                    .accessibilityHidden(true) // 그림은 숨기고 아래 문장만 읽는다
                Text(CheckInTooFarState.mapMessage).pumText(.callout, weight: .semibold)
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, PumTokens.Space.s12)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
    }

    /// 공통 후보 — 지도 자리 그림(원문이 격자 그림이라 MapKit 없이 도형으로만)
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
                // 사업장 표시: 파랑 테두리 원 안 먹색 네모
                ZStack {
                    Circle().fill(PumColor.accentSoft)
                    Circle().stroke(PumColor.accent, lineWidth: Local.pinStroke)
                    RoundedRectangle(cornerRadius: PumTokens.Radius.xs / 2, style: .continuous)
                        .fill(PumColor.surfaceInverse)
                        .frame(width: Local.pinInner, height: Local.pinInner)
                }
                .frame(width: Local.pinSize, height: Local.pinSize)
                .position(x: w / 2, y: h / 2)
                // 내 위치: 흰 테두리 파랑 점
                Circle().fill(PumColor.accent)
                    .frame(width: Local.dotSize, height: Local.dotSize)
                    .overlay(Circle().stroke(.white, lineWidth: Local.dotRing))
                    .position(x: w * Local.dotX, y: h * Local.dotY)
                Text(CheckInTooFarState.mapLabel).pumText(.caption2, weight: .semibold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.leading, PumTokens.Space.s12)
                    .padding(.bottom, PumTokens.Space.s10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: Local.mapHeight)
    }

    // MARK: 정보 카드

    private var infoCard: some View {
        PumCard {
            VStack(spacing: 0) {
                infoRow(title: CheckInTooFarState.accuracyTitle, detail: state.accuracyNote, value: state.accuracyText,
                        isLast: false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.accuracyAccessibilityLabel))
                Button(action: requestOwner) {
                    infoRow(title: CheckInTooFarState.ownerRowTitle, detail: state.ownerRowDetail,
                            value: CheckInTooFarState.ownerAction, isLast: true, showsChevron: true)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // 대체 경로는 다시 확인하는 중에도 막지 않는다(판정이 오래 걸려도 출근 기록 길이 남게 — REQ-029)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.ownerRowAccessibilityLabel))
            }
        }
    }

    /// 공통 후보 — 키(제목 + 회색 설명) · 값 행. 큰 글자에서는 키–값을 세로로 쌓는다.
    private func infoRow(title: String, detail: String, value: String, isLast: Bool, showsChevron: Bool = false) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                keyBlock(title: title, detail: detail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                valueText(value, trailing: true)
                chevron(showsChevron)
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    keyBlock(title: title, detail: detail)
                    valueText(value, trailing: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                chevron(showsChevron)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
    }

    private func keyBlock(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).font(PumTextStyle.body.font).fontWeight(.regular)
                .tracking(PumTokens.Tracking.body)
                .foregroundStyle(PumTokens.ColorToken.gray800)
            Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
    }

    private func valueText(_ text: String, trailing: Bool) -> some View {
        Text(text).font(PumTextStyle.body.font).fontWeight(.semibold)
            .tracking(PumTokens.Tracking.body)
            .foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(trailing ? .trailing : .leading)
    }

    @ViewBuilder private func chevron(_ shows: Bool) -> some View {
        if shows {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(PumColor.textDisabled)
                .accessibilityHidden(true)
        }
    }

    // MARK: 바닥

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: CheckInTooFarState.retryTitle, kind: .primary, isLoading: lock.isChecking,
                      loadingTitle: CheckInTooFarState.retryingTitle, action: retry)
            PumButton(title: CheckInTooFarState.ownerAction, kind: .text, action: requestOwner)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 끝나면 푼다
    private func retry() {
        guard lock.begin() else { return }
        onRetry { _ in lock.finish() }
    }

    private func requestOwner() {
        onRequestOwner()
    }
}

#Preview("10u") { CheckInTooFarView(state: .sample) }
#Preview("10u · 큰 글자") { CheckInTooFarView(state: .sample).dynamicTypeSize(.xxxLarge) }
