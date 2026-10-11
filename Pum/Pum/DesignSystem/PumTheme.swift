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
    @ScaledMetric private var scale: CGFloat = 1

    init(style: PumTextStyle) {
        self.style = style
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        let t = style.token
        content
            .font(style.font)
            .monospacedDigit() // F4: 숫자는 고정폭
            .tracking(style.tracking)
            .lineSpacing(max(0, t.size * (t.lineHeight - 1)) * scale)
    }
}

extension View {
    /// `Text("…").pumText(.body)` — 크기 · 굵기 · 줄 간격 · 자간 · 고정폭 숫자를 한 번에.
    func pumText(_ style: PumTextStyle) -> some View {
        modifier(PumTextModifier(style: style))
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
