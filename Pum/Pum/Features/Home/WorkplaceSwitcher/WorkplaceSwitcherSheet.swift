// UI-IOS-1y · REQ-008 — 사업장 전환 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
enum WorkplaceSwitcherLocal {
    /// 사업장 색 네모 약 44(1n과 같은 모양). 큰 글자에서 함께 커진다
    static let tileSize: CGFloat = 44
    /// 「전체 사업장」 겹친 네모 26×26(흰 테두리 2)(1n 칩과 같은 모양)
    static let stackTileWidth: CGFloat = 26
    static let stackTileHeight: CGFloat = 26
    /// 열린 칩 파랑 테두리 약 2 — 토큰에 2는 없어 이름만 붙임
    static let openRingWidth: CGFloat = 2
    /// 뒤 화면 맨 위 줄(칩 · 알림) 높이 40 — 누름 영역 44는 유지
    static let topRowHeight: CGFloat = 40
    /// 체크 칸 최소 폭(정렬용)
    static let markMinWidth: CGFloat = 24
}

struct WorkplaceSwitcherSheet: View {
    let state: WorkplaceSwitcherState
    var onSelect: (String) -> Void = { _ in }
    var onShowAll: () -> Void = {}
    var onAddByCode: () -> Void = {}

    @ScaledMetric private var tile = WorkplaceSwitcherLocal.tileSize
    @ScaledMetric private var stackW = WorkplaceSwitcherLocal.stackTileWidth
    @ScaledMetric private var stackH = WorkplaceSwitcherLocal.stackTileHeight
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            PumCard {
                ForEach(Array(state.workplaces.enumerated()), id: \.element.id) { index, w in
                    if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 원문: 전폭
                    row(w)
                }
            }
            PumCard { allRow }
            Button(action: onAddByCode) {
                HStack(spacing: PumTokens.Space.s8) { // 원문 gap 8
                    Image(systemName: "plus").font(.callout.weight(.semibold)).accessibilityHidden(true)
                    Text("초대 코드로 사업장 추가").pumText(.body, weight: .semibold)
                }
                .foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Space.s24 * 2) // 원문 높이 48
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
        .task {
            try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
            titleFocused = true
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { title; Spacer(minLength: PumTokens.Space.s8); count }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title; count }
        }
    }

    private var title: some View {
        // 목업 20px 700 → title3(20)
        Text("내 사업장").pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($titleFocused)
    }

    private var count: some View {
        Text(state.countText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    private func row(_ w: SwitcherWorkplace) -> some View {
        Button { onSelect(w.id) } label: {
            HStack(spacing: PumTokens.Space.s14) {
                // 15px 700 흰색 → callout(16)
                Text(w.initial).pumText(.callout, weight: .bold).foregroundStyle(.white)
                    .frame(width: tile, height: tile)
                    .background(w.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(w.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(w.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                markView(state.mark(for: w))
            }
            .padding(.vertical, PumTokens.Space.s14) // 원문 행 padding 14 16
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.accessibilityText(for: w)))
        .accessibilityAddTraits(w.id == state.selectedID ? .isSelected : [])
        .accessibilityHint(Text(w.id == state.selectedID ? "" : "이 사업장으로 바꿔요"))
    }

    @ViewBuilder
    private func markView(_ mark: SwitcherMark) -> some View {
        switch mark {
        case .selected:
            Image(systemName: "checkmark").font(.body.weight(.bold)).foregroundStyle(PumColor.accent)
                .frame(minWidth: WorkplaceSwitcherLocal.markMinWidth)
        case .pending(let n):
            PumBadge(text: SwitcherWorkplace.pendingText(n), kind: .attention)
        case .none:
            EmptyView()
        }
    }

    private var allRow: some View {
        Button(action: onShowAll) {
            HStack(spacing: PumTokens.Space.s14) {
                HStack(spacing: -PumTokens.Space.s8) { // 겹침 8
                    ForEach(state.workplaces) { w in
                        RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous).fill(w.tileColor)
                            .frame(width: stackW, height: stackH)
                            .overlay(RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                                .strokeBorder(PumColor.surfaceCard, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text("전체 사업장 모아보기").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.summaryText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
            }
            .padding(.vertical, PumTokens.Space.s14) // 원문 행 padding 14 16
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("전체 사업장 모아보기, \(state.summaryText)"))
    }
}
