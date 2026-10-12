// UI-IOS-21j · 21k · REQ-095 · M8 · M32 — 사장님 · 직원 홈 로딩: 머리 · 탭은 실제, 본문만 스켈레톤(숫자 자리 비움)
// 크기는 원문 캡처(402pt 폭) 실측에 가까운 값 — 토큰에 없는 줄 폭 · 높이는 근사
import SwiftUI

/// 스켈레톤 전용 크기(원문 실측 근사)
private enum HomeSkeletonLayout {
    static let lineHeight: CGFloat = 12
    static let subLineHeight: CGFloat = 10
    static let titleLineWidth: CGFloat = 130
    static let subLineWidth: CGFloat = 192
    static let cardTitleWidth: CGFloat = 125
    static let cardTitleHeight: CGFloat = 14
    static let greetingWidth: CGFloat = 84
    static let headlineWidth: CGFloat = 150
    static let headlineHeight: CGFloat = 24
    static let amountWidth: CGFloat = 185
    static let amountHeight: CGFloat = 22
    static let barHeight: CGFloat = PumTokens.Space.s6
    static let kickerWidth: CGFloat = 82
    static let todayTitleWidth: CGFloat = 112
    static let todayClockWidth: CGFloat = 205
    static let todayClockHeight: CGFloat = 26
    static let todaySubWidth: CGFloat = 158
    static let buttonSlotHeight: CGFloat = 54
}

/// 원 + 두 줄 한 행(원 지름은 원문 약 34pt, 글자 크기에 맞춰 커진다)
private struct SkeletonPersonRow: View {
    @ScaledMetric(relativeTo: .body) private var circle: CGFloat = 34
    var showsDivider = true

    var body: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumSkeletonBlock(width: circle, height: circle).clipShape(Circle())
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                PumSkeletonBlock(width: HomeSkeletonLayout.titleLineWidth, height: HomeSkeletonLayout.lineHeight)
                PumSkeletonBlock(width: HomeSkeletonLayout.subLineWidth, height: HomeSkeletonLayout.subLineHeight)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            }
        }
    }
}

/// 제목 줄 + 원·두 줄 행 n개(2번째 카드 꼴)
private struct SkeletonTitledRowsCard: View {
    let rows: Int

    var body: some View {
        PumCard {
            PumSkeletonBlock(width: HomeSkeletonLayout.cardTitleWidth, height: HomeSkeletonLayout.cardTitleHeight)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, PumTokens.Space.s16)
                .padding(.bottom, PumTokens.Space.s6)
                .padding(.horizontal, PumTokens.Size.rowPadX)
            ForEach(0..<rows, id: \.self) { SkeletonPersonRow(showsDivider: $0 < rows - 1) }
        }
    }
}

/// UI-IOS-21j 본문
struct OwnerHomeLoadingBody: View {
    var body: some View {
        VStack(spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                PumSkeletonBlock(width: HomeSkeletonLayout.greetingWidth, height: HomeSkeletonLayout.lineHeight)
                PumSkeletonBlock(width: HomeSkeletonLayout.headlineWidth, height: HomeSkeletonLayout.headlineHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s4)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s2)

            PumCard { ForEach(0..<3, id: \.self) { SkeletonPersonRow(showsDivider: $0 < 2) } }
            SkeletonTitledRowsCard(rows: 2)
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    PumSkeletonBlock(width: HomeSkeletonLayout.kickerWidth, height: HomeSkeletonLayout.lineHeight)
                    PumSkeletonBlock(width: HomeSkeletonLayout.amountWidth, height: HomeSkeletonLayout.amountHeight)
                    PumSkeletonBlock(height: HomeSkeletonLayout.barHeight).clipShape(Capsule())
                }
                .padding(PumTokens.Space.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// UI-IOS-21k 본문 — 출근 버튼 자리는 회색 사각(버튼 아님, 누를 수 없음)
struct EmployeeHomeLoadingBody: View {
    var body: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    PumSkeletonBlock(width: HomeSkeletonLayout.todayTitleWidth, height: HomeSkeletonLayout.lineHeight)
                    PumSkeletonBlock(width: HomeSkeletonLayout.todayClockWidth, height: HomeSkeletonLayout.todayClockHeight)
                    PumSkeletonBlock(width: HomeSkeletonLayout.todaySubWidth, height: HomeSkeletonLayout.subLineHeight)
                    PumSkeletonBlock(height: HomeSkeletonLayout.buttonSlotHeight)
                        .clipShape(RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .padding(.top, PumTokens.Space.s6)
                }
                .padding(PumTokens.Space.s18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            SkeletonTitledRowsCard(rows: 3)
        }
    }
}
