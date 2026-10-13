// UI-IOS-10d · REQ-074 — 급여명세서 발행(탭 바 없음). 이 화면에서 발행하지 않는다 — 「N명 발행하기」는 10e 확인 시트를 여는 클로저만.
// 10e는 이 뷰를 그대로 뒤에 깔고(스크롤 위치는 10e가 정함) 그 위에 시트를 올린다.
import SwiftUI

struct PayslipIssueView: View {
    @State private var state: PayslipIssueState
    /// 서버가 준 원래 값 — 바뀌면 화면 값을 다시 받는다(보내는 때 선택만 화면에 남긴다)
    private let serverState: PayslipIssueState
    var onBack: () -> Void
    var onTimingChanged: (PayslipSendTiming) -> Void
    var onRequestInfo: (String) -> Void   // 직원 ID
    var onIssue: (PayslipSendTiming) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    /// 세그먼트 칸 높이 — 원문 약 36(누름 영역은 44까지)
    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 36
    /// 체크 원 지름 — 원문 약 20
    /// 직원 줄 아바타 지름 — 원문 32
    @ScaledMetric(relativeTo: .body) private var rowAvatar: CGFloat = 32
    @ScaledMetric(relativeTo: .caption) private var checkSize = PumLayout.avatar - PumTokens.Space.s16

    init(state: PayslipIssueState = .sample,
         onBack: @escaping () -> Void = {},
         onTimingChanged: @escaping (PayslipSendTiming) -> Void = { _ in },
         onRequestInfo: @escaping (String) -> Void = { _ in },
         onIssue: @escaping (PayslipSendTiming) -> Void = { _ in }) {
        _state = State(initialValue: state)
        self.serverState = state
        self.onBack = onBack
        self.onTimingChanged = onTimingChanged
        self.onRequestInfo = onRequestInfo
        self.onIssue = onIssue
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    summaryCard
                    timingSection
                    peopleSection
                    requiredSection
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: serverState) { _, new in
            let picked = state.selectedTimingID
            state = new
            if new.timings.contains(where: { $0.id == picked }) { state.selectedTimingID = picked }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: 요약 카드

    private var summaryCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                    summaryTexts
                    Spacer(minLength: PumTokens.Space.s8)
                    PumBadge(text: state.statusBadgeText, kind: .done)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    summaryTexts
                    PumBadge(text: state.statusBadgeText, kind: .done)
                }
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(state.periodText), \(state.waitingText), \(state.statusBadgeText)"))
    }

    private var summaryTexts: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.periodText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            // 원문 22px 700 → title-3 20px 근사
            Text(state.waitingText).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 보내는 때 — 세그먼트는 공통에 없어 화면 전용(공통 후보: 8d와 같은 값)

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: PayslipIssueState.timingHeader)
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    segments
                    Text(state.timingNote).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, PumTokens.Space.s12)
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(state.timings) { t in
                let selected = t.id == state.selectedTimingID
                Button {
                    state.selectedTimingID = t.id
                    onTimingChanged(t)
                } label: {
                    Text(t.title)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: max(segmentHeight, PumTokens.Size.tapMin))
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(t.title))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 직원 목록

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: state.peopleHeaderText)
            PumCard {
                ForEach(Array(state.people.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                    row(p)
                }
            }
        }
    }

    private func row(_ p: PayslipIssuePerson) -> some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s12) {
            PumAvatar(name: p.name, colorIndex: p.colorIndex, size: rowAvatar).accessibilityHidden(true)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                    nameBlock(p)
                    Spacer(minLength: PumTokens.Space.s8)
                    amountText(p)
                    requestButton(p)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    nameBlock(p)
                    amountText(p)
                    requestButton(p)
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(p.accessibilityText))
        .accessibilityActions {
            if p.canRequestInfo { Button("요청") { onRequestInfo(p.id) } }
        }
    }

    private func nameBlock(_ p: PayslipIssuePerson) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(p.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            if let missing = p.missingText {
                Text(missing).pumText(.caption, weight: .regular).foregroundStyle(PumColor.statusAttention)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func amountText(_ p: PayslipIssuePerson) -> some View {
        Text(p.amountText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func requestButton(_ p: PayslipIssuePerson) -> some View {
        if p.canRequestInfo {
            Button { onRequestInfo(p.id) } label: {
                Text("요청 ›").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                    .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: 필수 기재 항목

    private var requiredSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: PayslipIssueState.requiredHeader)
            PumCard {
                let columns = typeSize.isAccessibilitySize
                    ? [GridItem(.flexible(), alignment: .topLeading)]
                    : [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: PumTokens.Space.s10) {
                    ForEach(state.requiredItems) { item in
                        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                            itemMark(ok: item.isOk)
                            Text(item.displayText).pumText(.footnote, weight: .regular)
                                .foregroundStyle(PumTokens.ColorToken.gray800)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(item.accessibilityText))
                    }
                }
                .padding(.vertical, PumTokens.Space.s14)
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // 공통 후보: 체크 원(확인 = 회색 원 + 먹색 체크 · 확인 필요 = 연주황 원 + 「!」). 7a · 10a와 같은 값.
    private func itemMark(ok: Bool) -> some View {
        Circle()
            .fill(ok ? PumColor.surfaceFill : PumColor.statusAttentionSoft)
            .overlay {
                if ok {
                    Image(systemName: "checkmark").font(.system(size: checkSize * 0.45, weight: .semibold)) // 원 크기에 비례(원문 작은 체크)
                        .foregroundStyle(PumColor.textPrimary)
                } else {
                    Text("!").pumText(.caption, weight: .bold).foregroundStyle(PumColor.statusAttention)
                }
            }
            .frame(width: checkSize, height: checkSize)
            .accessibilityHidden(true)
    }

    // MARK: 하단

    private var bottomBar: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: state.issueButtonTitle, kind: .primary) {
                if let t = state.selectedTiming { onIssue(t) }
            }
            .disabled(!state.canIssue || state.selectedTiming == nil)
            if let note = state.blockedNote {
                Text(note).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("10d") { PayslipIssueView() }
#Preview("10d · 큰 글자") { PayslipIssueView().dynamicTypeSize(.xxxLarge) }
