// UI-IOS-6n · REQ-096 — 급여 계산 문의(탭 바 없음, 모달).
// 처리 중 표시는 「문의 보내기」 버튼에만 둔다. 항목 · 내용 · 토글 · 받는 곳은 화면 안 초안(@State).
import SwiftUI

struct PayrollInquiryView: View {
    private let serverState: PayrollInquiryState
    @State private var draft: PayrollInquiryDraft
    @FocusState private var bodyFocused: Bool
    var isProcessing = false
    var startsEditing = false
    var onClose: () -> Void
    var onSend: (PayrollInquirySubmission) -> Void

    init(state: PayrollInquiryState = .sample,
         isProcessing: Bool = false,
         startsEditing: Bool = false,
         onClose: @escaping () -> Void = {},
         onSend: @escaping (PayrollInquirySubmission) -> Void = { _ in }) {
        self.serverState = state
        _draft = State(initialValue: state.initialDraft)
        self.isProcessing = isProcessing
        self.startsEditing = startsEditing
        self.onClose = onClose
        self.onSend = onSend
    }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    Text(PayrollInquiryState.titleLines.joined(separator: "\n"))
                        .pumText(.title1).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, PumTokens.Space.s4)
                    summaryCard
                    itemSection
                    inputBox
                    optionsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s8)
                .allowsHitTesting(!isProcessing)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .onChange(of: serverState) { old, new in
            if !old.hasChanges(draft) || !new.hasChanges(draft) { draft = new.initialDraft }
        }
        .onAppear { if startsEditing { bodyFocused = true } }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: 머리 — 닫기 모양(✕)

    private var header: some View {
        ZStack {
            Text(PayrollInquiryState.headerTitle)
                .pumText(.headline).foregroundStyle(PumColor.textPrimary).lineLimit(1)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }

    // MARK: 요약 카드

    private var summaryCard: some View {
        PumCard {
            ForEach(Array(serverState.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.horizontal, PumTokens.Size.rowPadX)
                }
                summaryRow(row)
            }
        }
    }

    private func summaryRow(_ row: InquirySummaryRow) -> some View {
        let l = Text(row.label).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let v = Text(row.value).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { l; Spacer(minLength: 0); v.fixedSize() }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { l; v.multilineTextAlignment(.leading) }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(row.label), \(row.value)"))
    }

    // MARK: 문제가 있는 항목

    private var itemSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: PayrollInquiryState.itemHeader)
            InquiryFlowLayout(spacing: PumTokens.Space.s8) {
                ForEach(Array(InquiryItem.allCases.enumerated()), id: \.element.id) { i, item in
                    PumChoicePill(title: item.title, isOn: draft.item == item, offStyle: .outlined,
                                  position: (i, InquiryItem.allCases.count)) {
                        draft.item = item
                    }
                }
            }
        }
    }

    // MARK: 내용 입력 — 입력 중엔 파랑 테두리

    private var inputBox: some View {
        let r = PumTokens.Radius.lg
        return TextField(PayrollInquiryState.placeholder, text: $draft.body, axis: .vertical)
            .pumText(.callout, weight: .regular)
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .focused($bodyFocused)
            .lineLimit(3...)
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .topLeading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(bodyFocused ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: bodyFocused ? PumSelectionStyle.ringWidth : 1)
            }
            .accessibilityLabel(Text("문의 내용"))
    }

    // MARK: 근거 첨부 · 받는 곳

    private var optionsCard: some View {
        PumCard {
            Toggle(isOn: $draft.attachesEvidence) {
                optionText(title: PayrollInquiryState.evidenceTitle, detail: serverState.evidenceDetail)
            }
            .tint(PumColor.accent)
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityLabel(Text(serverState.evidenceSpoken))

            ForEach(Array(InquiryRecipient.allCases.enumerated()), id: \.element.id) { i, r in
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                recipientRow(r, index: i, count: InquiryRecipient.allCases.count)
            }
        }
    }

    private func optionText(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.leading)
            Text(detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    private func recipientRow(_ r: InquiryRecipient, index: Int, count: Int) -> some View {
        let on = draft.recipient == r
        return Button { draft.recipient = r } label: {
            HStack(spacing: PumTokens.Space.s12) {
                optionText(title: r.title, detail: r.detail).frame(maxWidth: .infinity, alignment: .leading)
                PumRadioMark(isOn: on)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(r.title), \(r.detail), \(count)개 중 \(index + 1)번째"))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 하단

    private var bottomBar: some View {
        PumButton(title: PayrollInquiryState.sendTitle, isLoading: isProcessing) {
            onSend(serverState.submission(draft))
        }
        .disabled(!serverState.canSend(draft))
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

/// 칩이 한 줄에 안 들어가면 다음 줄로 넘기는 배치(받은 폭 그대로 돌려줌)
private struct InquiryFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = arrange(width: proposal.width ?? .infinity, subviews: subviews).size
        return CGSize(width: proposal.width ?? size.width, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var maxW: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            rowH = max(rowH, s.height)
            maxW = max(maxW, x - spacing)
        }
        return (CGSize(width: maxW, height: y + rowH), origins)
    }
}

#Preview("6n") { PayrollInquiryView(startsEditing: true) }
#Preview("6n · 큰 글자") { PayrollInquiryView().dynamicTypeSize(.xxxLarge) }
