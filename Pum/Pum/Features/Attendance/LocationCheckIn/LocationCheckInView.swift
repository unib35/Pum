// UI-IOS-10v · REQ-021 · REQ-022 · REQ-023 — 위치만 · 간편 출근: QR 없이 버튼 하나. 탭 바 없음.
// 위치는 「출근하기」를 누르는 순간 1회만 판정(REQ-023) — 이 화면은 위치를 추적하지 않는다. 지도는 그림 자리(MapKit 없음).
// 사업장 칩은 원문에 전환 근거가 없어 누르지 않는 칩(화살표 없음).
import SwiftUI

struct LocationCheckInView: View {
    var state: LocationCheckInState
    /// 출근하기. 끝나면 done(성공 여부)을 부른다 — 성공이면 부모가 10t로, 실패면 10u/10w로. 연결 전 기본값은 done(false).
    var onCheckIn: (_ done: @escaping (Bool) -> Void) -> Void

    @State private var lock = LocationCheckInLock()

    init(state: LocationCheckInState = .sample,
         onCheckIn: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onCheckIn = onCheckIn
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 값). 지도 그림은 10u와 같은 값.
    private enum Local {
        static let mapHeight: CGFloat = 176
        static let roadWidth: CGFloat = 10
        static let verticalRoadX: CGFloat = 0.30
        static let horizontalRoadY: CGFloat = 0.46
        /// 반경 원 지름 · 테두리 — 원문 약 95 · 2
        static let radiusCircle: CGFloat = 96
        static let radiusStroke: CGFloat = 2
        /// 사업장 표시(먹색 네모 + 흰 테두리) — 원문 약 14 · 3
        static let placeInner: CGFloat = 14
        static let placeRing: CGFloat = 3
        static let dotSize: CGFloat = 14
        static let dotRing: CGFloat = 3
        /// 내 위치 점 위치(원 중심 기준 오른쪽 위)
        static let dotOffsetX: CGFloat = 18
        static let dotOffsetY: CGFloat = -12
        /// 칩 안 네모 — 원문 24
        static let chipMark: CGFloat = 24
        static let glyph: CGFloat = 14
    }

    @ScaledMetric(relativeTo: .body) private var checkCircle = PumLayout.avatar - PumTokens.Space.s12
    @ScaledMetric(relativeTo: .caption) private var chipMarkSize = Local.chipMark

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                topRow
                todayCard
                mapCard
                methodCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
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

    /// 공통 후보 — 사업장 칩(흰 알약 + 파랑 네모 이니셜)
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
            Text(LocationCheckInState.todayTitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            Text(state.shiftText).pumText(.title3, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(PumColor.textPrimary)
        }
    }

    // MARK: 지도 + 현재 위치

    private var mapCard: some View {
        PumCard {
            VStack(spacing: 0) {
                mapPlaceholder.accessibilityHidden(true) // 그림은 숨기고 아래 행만 읽는다
                locationRow
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.locationAccessibilityLabel))
            }
        }
    }

    /// 공통 후보 — 지도 자리 그림(10u와 같은 길 · 바탕, MapKit 없이 도형으로만)
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
                // 반경 원: 연파랑 채움 + 파랑 테두리
                Circle().fill(PumColor.accentSoft)
                    .overlay(Circle().stroke(PumColor.accent, lineWidth: Local.radiusStroke))
                    .frame(width: Local.radiusCircle, height: Local.radiusCircle)
                    .position(x: w / 2, y: h * Local.horizontalRoadY)
                // 사업장 표시: 먹색 네모 + 흰 테두리
                RoundedRectangle(cornerRadius: PumTokens.Radius.xs / 2, style: .continuous)
                    .fill(PumColor.surfaceInverse)
                    .frame(width: Local.placeInner, height: Local.placeInner)
                    .overlay(RoundedRectangle(cornerRadius: PumTokens.Radius.xs / 2, style: .continuous)
                        .stroke(.white, lineWidth: Local.placeRing))
                    .position(x: w / 2, y: h * Local.horizontalRoadY)
                // 내 위치: 흰 테두리 파랑 점
                Circle().fill(PumColor.accent)
                    .frame(width: Local.dotSize, height: Local.dotSize)
                    .overlay(Circle().stroke(.white, lineWidth: Local.dotRing))
                    .position(x: w / 2 + Local.dotOffsetX, y: h * Local.horizontalRoadY + Local.dotOffsetY)
                Text(LocationCheckInState.mapLabel).pumText(.caption2, weight: .semibold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.leading, PumTokens.Space.s12)
                    .padding(.bottom, PumTokens.Space.s10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: Local.mapHeight)
    }

    private var locationRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                checkMark
                locationText.frame(maxWidth: .infinity, alignment: .leading)
                radiusLabel
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                checkMark
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    locationText
                    radiusLabel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    /// 공통 후보 — 회색 원 + 먹색 체크(10t · 10u와 같은 24 원)
    private var checkMark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: Local.glyph, weight: .bold))
            .foregroundStyle(PumColor.textPrimary)
            .frame(width: checkCircle, height: checkCircle)
            .background(PumColor.surfaceFill, in: Circle())
            .opacity(state.isWithinRadius ? 1 : 0) // 서버 판정이 반경 안일 때만 체크
            .accessibilityHidden(true)
    }

    private var locationText: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(LocationCheckInState.currentLocationTitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            if let detail = state.distanceDetail {
                Text(detail).pumText(.callout, weight: .bold).monospacedDigit()
                    .foregroundStyle(PumColor.textPrimary)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var radiusLabel: some View {
        Text(state.radiusText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            .multilineTextAlignment(.trailing)
    }

    // MARK: 출근 방식

    private var methodCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    methodKey.frame(maxWidth: .infinity, alignment: .leading)
                    methodValue
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    methodKey
                    methodValue
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .combine)
        }
    }

    private var methodKey: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(LocationCheckInState.methodTitle).font(PumTextStyle.body.font).fontWeight(.regular)
                .tracking(PumTokens.Tracking.body)
                .foregroundStyle(PumTokens.ColorToken.gray800)
            Text(state.methodDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
    }

    private var methodValue: some View {
        Text(state.methodValue).font(PumTextStyle.body.font).fontWeight(.semibold)
            .tracking(PumTokens.Tracking.body)
            .foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    // MARK: 바닥

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s8) {
            // 위치 판정 값이 없어도 활성 — 출퇴근 기록은 막지 않는다(REQ-029)
            PumButton(title: LocationCheckInState.checkInTitle, kind: .primary, isLoading: lock.isChecking,
                      loadingTitle: LocationCheckInState.checkingTitle, action: checkIn)
            Text(LocationCheckInState.footnote).pumText(.caption)
                .foregroundStyle(PumTokens.ColorToken.gray400)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s8)
        .background(PumColor.bgApp)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 끝나면 푼다
    private func checkIn() {
        guard lock.begin() else { return }
        onCheckIn { _ in lock.finish() }
    }
}

#Preview("10v") { LocationCheckInView(state: .sample) }
#Preview("10v · 큰 글자") { LocationCheckInView(state: .sample).dynamicTypeSize(.xxxLarge) }
