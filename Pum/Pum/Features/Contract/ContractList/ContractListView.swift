// UI-IOS-1ab · REQ-060 · DEC-005 — 계약서 보관함: 사업장별 계약 · 조건 변경 서명. 탭 바 없음.
// 색 의미: 초록 = 체결 완료, 주황 = 변경 서명 대기, 파랑 = 다음 동작(확인).
// PDF 보기 · 공유 · 확인은 클로저만(연결 후속).
import SwiftUI

struct ContractListView: View {
    @State private var record: ContractListRecord
    var onBack: () -> Void = {}
    var onViewPDF: (ContractItem) -> Void = { _ in }
    var onShare: (ContractItem) -> Void = { _ in }
    var onConfirmChange: (ContractItem) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(record: ContractListRecord = .sample,
         onBack: @escaping () -> Void = {},
         onViewPDF: @escaping (ContractItem) -> Void = { _ in },
         onShare: @escaping (ContractItem) -> Void = { _ in },
         onConfirmChange: @escaping (ContractItem) -> Void = { _ in }) {
        _record = State(initialValue: record)
        self.onBack = onBack
        self.onViewPDF = onViewPDF
        self.onShare = onShare
        self.onConfirmChange = onConfirmChange
    }

    /// 사업장 네모 약 44 — 큰 글자에서 글자와 함께 커진다(DEC-005: 토큰 밖 값에 이름)
    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 44
    /// 이력 시각 열 고정 폭: 「10/03 16:41」 13px 기준 약 82
    @ScaledMetric(relativeTo: .footnote) private var timeColumn: CGFloat = 82

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "계약서", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    Text("내 근로계약서").pumText(.title2) // 26px 700 → title2(24), 1h와 같게
                        .foregroundStyle(PumColor.textPrimary)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(record.items) { item in
                        card(item)
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
    }

    private func card(_ item: ContractItem) -> some View {
        PumCard(attention: item.isAttention) {
            VStack(spacing: 0) {
                header(item)
                if item.showsDetail {
                    divider
                    historyList(item)
                    actions(item)
                }
                if item.showsChange, let change = item.change {
                    divider
                    changeRow(item, change)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 원문: 카드 전폭
    }

    // 사업장 색 네모 · 이름 · 기간/시급 · 배지. 누르면 펼침 · 접힘(M11, 동작 줄이기면 즉시)
    @ViewBuilder
    private func header(_ item: ContractItem) -> some View {
        // 원문: 기간 · 시급 줄은 여러 줄로 접히고 배지는 오른쪽에 고정 — 접근성 큰 글자에서만 배지를 아래로
        let content = Group { if !typeSize.isAccessibilitySize {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                tile(item)
                titles(item)
                PumBadge(text: item.status.badgeText, kind: badgeKind(item.status)).fixedSize()
            }
        } else {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                    tile(item)
                    titles(item)
                }
                PumBadge(text: item.status.badgeText, kind: badgeKind(item.status))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } }
        .padding(PumTokens.Space.s16)
        .frame(minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .contentShape(Rectangle())
        if item.isExpandable {
            Button {
                withAnimation(reduceMotion ? nil : PumMotion.base) { record.toggle(id: item.id) }
            } label: { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.headerAccessibilityText))
                .accessibilityHint(Text(item.isExpanded ? "누르면 접어요" : "누르면 펼쳐요"))
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.headerAccessibilityText))
        }
    }

    private func tile(_ item: ContractItem) -> some View {
        Text(item.initial)
            .pumText(.body, weight: .bold) // 15px 700
            .foregroundStyle(.white)
            .frame(width: tileSize, height: tileSize)
            .background(PumAvatarPalette.stores[item.colorIndex % PumAvatarPalette.stores.count],
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityHidden(true)
    }

    private func titles(_ item: ContractItem) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(item.workplaceName).pumText(.body, weight: .bold) // 16px 700 → body(15)
                .foregroundStyle(PumColor.textPrimary)
            Text(item.summaryText).pumText(.caption) // 12px, 여러 줄 허용
                .foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func badgeKind(_ s: ContractStatus) -> PumBadge.Kind {
        switch s {
        case .signed: .done
        case .changePending: .attention
        }
    }

    // 이력: 「시각 · 내용」 한 줄씩(시각 고정 폭 열)
    private func historyList(_ item: ContractItem) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) { // 원문 줄 간격 약 31pt
            ForEach(item.history) { h in
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    Text(h.timeText).pumText(.footnote, weight: .regular)
                        .foregroundStyle(PumColor.textTertiary)
                        .frame(width: timeColumn, alignment: .leading)
                    Text(h.text).pumText(.footnote, weight: .regular)
                        .foregroundStyle(PumColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(h.accessibilityText))
            }
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.top, PumTokens.Space.s12)
    }

    // PDF 보기(OUTLINE) · 공유(회색 바탕) 같은 폭
    private func actions(_ item: ContractItem) -> some View {
        HStack(spacing: PumTokens.Space.s8) {
            PumButton(title: "PDF 보기", kind: .outline) { onViewPDF(item) }
            ContractTonalButton(title: "공유") { onShare(item) }
        }
        .padding(PumTokens.Space.s16)
    }

    // 변경 단락 + 확인 ›
    private func changeRow(_ item: ContractItem, _ c: ContractChangeNotice) -> some View {
        // 원문: 단락은 접히고 「확인 ›」는 오른쪽 — 접근성 큰 글자에서만 아래로
        Group { if !typeSize.isAccessibilitySize {
            HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                changeText(c).frame(maxWidth: .infinity, alignment: .leading)
                confirmButton(item).fixedSize()
            }
        } else {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                changeText(c)
                confirmButton(item)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } }
        .padding(.leading, PumTokens.Space.s16)
        .padding(.trailing, PumTokens.Space.s4)
        .padding(.vertical, PumTokens.Space.s4)
    }

    private func changeText(_ c: ContractChangeNotice) -> some View {
        (Text(c.leadText).foregroundStyle(PumColor.textPrimary)
         + Text(c.oldWageText).strikethrough().foregroundStyle(PumColor.textTertiary)
         + Text(ContractChangeNotice.arrowText).foregroundStyle(PumColor.textPrimary)
         + Text(c.newWageText).font(PumFont.font(size: PumTokens.FontToken.footnote.size, weight: .bold, relativeTo: .footnote))
            .foregroundStyle(PumTokens.ColorToken.gray800) // #3A4150 = gray800
         + Text(ContractChangeNotice.tailText).foregroundStyle(PumColor.textPrimary))
            .pumText(.footnote, weight: .regular) // 13px 400
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(c.accessibilityText))
    }

    private func confirmButton(_ item: ContractItem) -> some View {
        Button { onConfirmChange(item) } label: {
            Text("확인 ›").pumText(.footnote, weight: .bold) // 13px 700 파랑
                .foregroundStyle(PumColor.accent)
                .padding(.horizontal, PumTokens.Space.s12)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("확인"))
        .accessibilityHint(Text("변경 계약서를 확인해요"))
    }
}

/// 회색 바탕 버튼(먹색 글자, surfaceFill). 공통 PumButton에 회색 종류가 없어 화면 전용 — 공통 변경 요청 후보.
/// 높이 · 모서리 · 누름은 PumButton과 같다(buttonH · md · M1).
private struct ContractTonalButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(height: PumTokens.Size.buttonH)
                .contentShape(Rectangle())
        }
        .buttonStyle(ContractTonalStyle())
    }
}

private struct ContractTonalStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pumText(.headline) // PumButton regular와 같은 글자 단계
            .foregroundStyle(PumColor.textPrimary)
            .background(configuration.isPressed ? PumTokens.ColorToken.gray200 : PumColor.surfaceFill,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1) // M1
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: configuration.isPressed)
    }
}

#Preview("계약서 보관함") { ContractListView() }
