// C5 List Row · Card · Section — 카드 모서리 14 · 흰 바탕 · hairline · 안쪽 구분선 1px · 키는 회색, 값은 먹색 600
import SwiftUI

struct PumCard<Content: View>: View {
    /// 확인 필요 카드: 주황 외곽선(attention)
    var attention = false
    /// 모서리 — 기본 14. 원문이 다른 카드만 토큰 값(md 12 · xl 16)을 준다(DEC-013)
    var radius: CGFloat = PumTokens.Radius.lg
    @ViewBuilder let content: Content

    var body: some View {
        let r = radius
        VStack(spacing: 0) { content }
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .pumRing(attention ? .attention : .hairline, cornerRadius: r)
    }
}

struct PumSectionHeader: View {
    let title: String
    var attention = false

    var body: some View {
        Text(title)
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption))
            .foregroundStyle(attention ? PumColor.statusAttention : PumColor.textSecondary)
            .padding(.horizontal, PumTokens.Space.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 키–값 행 · 이동 행(chevron) · 토글 행
struct PumRow<Trailing: View>: View {
    let title: String
    var subtitle: String?
    /// 키–값 행은 키를 회색으로(C5)
    var isKey = false
    var showsChevron = false
    var isLast = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).pumText(.body).foregroundStyle(isKey ? PumColor.textSecondary : PumColor.textPrimary)
                if let subtitle {
                    Text(subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX) // 안쪽 구분선
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension PumRow where Trailing == PumRowValue {
    /// 키–값 행
    init(_ title: String, value: String, isLast: Bool = false) {
        self.init(title: title, isKey: true, isLast: isLast) { PumRowValue(text: value) }
    }
}

struct PumRowValue: View {
    let text: String
    var body: some View {
        Text(text).pumText(.body).font(PumFont.font(size: PumTokens.FontToken.body.size, weight: .semibold, relativeTo: .body)).foregroundStyle(PumColor.textPrimary)
    }
}
