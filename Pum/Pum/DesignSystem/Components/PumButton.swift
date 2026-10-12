// C1 Button — PRIMARY 화면당 하나 · DARK 완료·저장 · OUTLINE 보조 · DANGER OUTLINE 거절 · TEXT 취소·나중에
// TONAL(회색 바탕 · 먹색 글자)은 C1 목록 밖 — 1ab 「공유」 원문에서 모았다
// 높이 54(작게 44) · 모서리 12 · 누름 M1 · 처리 중 M26 · 비활성은 이유를 문구에
import SwiftUI

struct PumButton: View {
    nonisolated enum Kind: CaseIterable { case primary, dark, outline, dangerOutline, tonal, text }
    enum Size { case regular, small }

    let title: String
    var kind: Kind = .primary
    var size: Size = .regular
    var isLoading = false
    var loadingTitle: String?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    PumButtonProgressLabel(title: loadingTitle ?? title)
                }
            }
            .padding(.horizontal, PumTokens.Space.s16) // 작은 버튼을 내용 폭으로 쓸 때(.fixedSize) 여백
            .frame(maxWidth: .infinity)
            .frame(height: size == .regular ? PumTokens.Size.buttonH : PumTokens.Size.buttonHSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PumButtonStyle(kind: kind, size: size, enabled: isEnabled && !isLoading))
        .disabled(isLoading)
        .animation(PumMotion.fast, value: isLoading) // M26 라벨 교체 --dur-fast
        .accessibilityValue(isLoading ? Text(loadingTitle ?? "처리 중") : Text(""))
    }
}

/// M26: 0.4초 안에 끝나면 진행 표시를 띄우지 않는다.
private struct PumButtonProgressLabel: View {
    let title: String
    @State private var showSpinner = false

    var body: some View {
        HStack(spacing: PumTokens.Space.s8) {
            if showSpinner { ProgressView().tint(.current) }
            Text(title)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            showSpinner = true
        }
    }
}

private extension Color {
    static var current: Color { Color.primary }
}

struct PumButtonStyle: ButtonStyle {
    let kind: PumButton.Kind
    let size: PumButton.Size
    let enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let radius = PumTokens.Radius.md
        let pressed = configuration.isPressed
        configuration.label
            .pumText(size == .regular ? .headline : .callout)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(background(pressed: pressed))
            )
            .modifier(RingModifier(ring: ring, radius: radius))
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1) // M1 scale .97
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: pressed)
    }

    private var foreground: Color {
        guard enabled else { return kind == .text ? PumColor.textDisabled : .white } // 디자인 C1 DISABLED: gray-300 바탕 · 흰 글자
        switch kind {
        case .primary, .dark: return .white
        case .outline, .tonal: return PumColor.textPrimary
        case .dangerOutline: return PumColor.statusDanger
        case .text: return PumColor.textSecondary
        }
    }

    private func background(pressed: Bool) -> Color {
        guard enabled else { return kind == .text ? .clear : PumTokens.ColorToken.gray300 }
        switch kind {
        case .primary: return pressed ? PumTokens.ColorToken.blue700 : PumColor.accent // M1 한 단계 진하게
        case .dark: return pressed ? PumTokens.ColorToken.gray800 : PumColor.surfaceInverse
        case .outline, .dangerOutline: return pressed ? PumColor.surfaceFill : PumColor.surfaceCard
        case .tonal: return pressed ? PumTokens.ColorToken.gray200 : PumColor.surfaceFill
        case .text: return pressed ? PumColor.surfaceFill : .clear
        }
    }

    private var ring: PumTokens.Shadow? {
        guard enabled else { return nil }
        switch kind {
        case .outline: return .outline
        case .dangerOutline:
            return PumTokens.Shadow(x: 0, y: 0, blur: 0, spread: PumTokens.Shadow.outline.spread, color: PumColor.statusDanger)
        default: return nil
        }
    }
}

private struct RingModifier: ViewModifier {
    let ring: PumTokens.Shadow?
    let radius: CGFloat
    func body(content: Content) -> some View {
        if let ring { content.pumRing(ring, cornerRadius: radius) } else { content }
    }
}

/// C1 PAIR — 부정이 왼쪽, 비율 1 : 1.5
struct PumButtonPair: View {
    let negative: String
    let positive: String
    /// 디자인 C1 PAIR 예시는 거절(빨간 외곽선)
    var negativeKind: PumButton.Kind = .dangerOutline
    var size: PumButton.Size = .regular
    let onNegative: () -> Void
    let onPositive: () -> Void

    var body: some View {
        GeometryReader { geo in
            let gap = PumTokens.Space.s8
            let unit = (geo.size.width - gap) / 2.5
            HStack(spacing: gap) {
                PumButton(title: negative, kind: negativeKind, size: size, action: onNegative).frame(width: unit)
                PumButton(title: positive, kind: .primary, size: size, action: onPositive).frame(width: unit * 1.5)
            }
        }
        .frame(height: size == .regular ? PumTokens.Size.buttonH : PumTokens.Size.buttonHSm)
    }
}
