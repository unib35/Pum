// 디자인 시스템 F1–F9 · M0 · M22 — 토큰(PumTokens, 자동 생성)을 화면에서 쓰는 방법
import SwiftUI

// MARK: - 색 (F1 · F2: 색은 의미로만)

nonisolated enum PumColor {
    typealias T = PumTokens.ColorToken
    static let bgApp = T.bgApp
    static let surfaceCard = T.surfaceCard
    static let surfaceFill = T.surfaceFill
    static let surfaceInverse = T.surfaceInverse
    static let textPrimary = T.textPrimary
    static let textSecondary = T.textSecondary
    static let textTertiary = T.textTertiary
    static let textDisabled = T.textDisabled
    static let borderHairline = T.borderHairline
    static let accent = T.accent
    static let accentSoft = T.accentSoft
    static let statusDone = T.statusDone
    static let statusDoneSoft = T.statusDoneSoft
    static let statusAttention = T.statusAttention
    static let statusAttentionSoft = T.statusAttentionSoft
    static let statusAttentionLine = T.statusAttentionLine
    static let statusAttentionDot = T.statusAttentionDot
    static let statusDanger = T.statusDanger
    static let statusDangerSoft = T.statusDangerSoft
    /// 조금 진한 연파랑(#D6DFFB) — C7 아바타 · C8 예정 타임라인. 배지 · 선택 배경은 accentSoft(DEC-005)
    static let accentSoftStrong = T.blue100
    /// 먹색 바탕 위 보조 글자(디자인 rgba(255,255,255,.7)) · 강조 점(blue-300)
    static let textOnInverseSecondary = Color.white.opacity(0.7)
    static let accentOnInverse = T.blue300
}

/// 디자인 컴포넌트 고정 크기(토큰에 없는 컴포넌트 치수). 화면 코드에서 숫자 대신 이 이름을 쓴다.
nonisolated enum PumLayout {
    /// C7 사업장 타일(칩 안) 크기 · 모서리 비율
    static let storeTileSmall: CGFloat = 24
    static let storeTileRadiusRatio: CGFloat = 0.3
    /// C6 아이콘
    static let navIcon: CGFloat = 18
    static let tabIcon: CGFloat = 21
    /// 알림 점 · 근무일 점
    static let notificationDot: CGFloat = 9
    static let dayDot: CGFloat = 5
    /// C8 타임라인 구간 사이 간격
    static let timelineGap: CGFloat = 3
    /// 탭 아이콘과 이름 사이
    static let tabLabelGap: CGFloat = 2
}

// MARK: - 글자 (F3 · F4)

/// 디자인 글자 11단계. 동적 글자 크기를 따르도록 가장 가까운 iOS 텍스트 스타일에 묶는다.
enum PumTextStyle: CaseIterable, Sendable {
    case display, hero, title1, title2, title3, headline, body, callout, footnote, caption, caption2

    var token: PumTokens.FontToken {
        switch self {
        case .display: .display
        case .hero: .hero
        case .title1: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .display, .hero: .largeTitle
        case .title1: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }

    /// 자간: 제목 계열 −0.6, 숫자 큰 글자 −1.5, 나머지 −0.2 (tokens/typography.css)
    var tracking: CGFloat {
        switch self {
        case .display: PumTokens.Tracking.display
        case .hero, .title1, .title2, .title3: PumTokens.Tracking.title
        default: PumTokens.Tracking.body
        }
    }

    /// Pretendard(앱 번들) · 동적 글자 크기
    var font: Font {
        PumFont.font(size: token.size, weight: token.weight, relativeTo: relativeTo)
    }
}

private struct PumTextModifier: ViewModifier {
    let style: PumTextStyle
    let weight: Font.Weight?
    @ScaledMetric private var scale: CGFloat = 1

    init(style: PumTextStyle, weight: Font.Weight?) {
        self.style = style
        self.weight = weight
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        let t = style.token
        content
            .font(PumFont.font(size: t.size, weight: weight ?? t.weight, relativeTo: style.relativeTo))
            .monospacedDigit() // F4: 숫자는 고정폭
            .tracking(style.tracking)
            .lineSpacing(max(0, t.size * (t.lineHeight - 1)) * scale)
    }
}

extension View {
    /// `Text("…").pumText(.body)` — 크기 · 굵기 · 줄 간격 · 자간 · 고정폭 숫자를 한 번에.
    func pumText(_ style: PumTextStyle) -> some View {
        modifier(PumTextModifier(style: style, weight: nil))
    }

    /// 같은 크기 단계에서 굵기만 바꿀 때(디자인이 단계 기본과 다른 굵기를 쓸 때)
    func pumText(_ style: PumTextStyle, weight: Font.Weight) -> some View {
        modifier(PumTextModifier(style: style, weight: weight))
    }
}

// MARK: - 모션 (M0 · M22)

nonisolated enum PumMotion {
    static func curve(_ e: PumTokens.Easing, _ duration: Double) -> Animation {
        .timingCurve(e.c0x, e.c0y, e.c1x, e.c1y, duration: duration)
    }
    static let press = curve(.standard, PumTokens.Duration.press)
    static let fast = curve(.standard, PumTokens.Duration.fast)
    static let base = curve(.standard, PumTokens.Duration.base)
    static let exit = curve(.exit, PumTokens.Duration.base)
    static let sheet = curve(.sheet, PumTokens.Duration.sheet)
    static let progress = curve(.standard, PumTokens.Duration.progress)

    /// M22 동작 줄이기: 이동 · 크기 변화 대신 `--dur-fast` 페이드만.
    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation {
        reduceMotion ? curve(.standard, PumTokens.Duration.fast) : animation
    }
}

// MARK: - 테두리 · 그림자 (F7: 외곽선 우선, 그림자는 떠 있는 것만)

extension View {
    /// 외곽선 그림자 토큰(hairline · outline · attention)을 테두리로 그린다.
    func pumRing(_ shadow: PumTokens.Shadow, cornerRadius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: -shadow.spread / 2)
                .stroke(shadow.color, lineWidth: shadow.spread)
                .allowsHitTesting(false)
        )
    }

    /// float — 알럿 · 토스트에만.
    func pumFloatShadow() -> some View {
        let s = PumTokens.Shadow.float
        return shadow(color: s.color, radius: s.blur / 2, x: s.x, y: s.y)
    }
}
