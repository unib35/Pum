// UI-IOS-19h · REQ-030 — 직원 · 출퇴근 기록(하루, 탭 바 없음) + 휴게 시트
// 시트는 서버 값(sheet)이 있을 때만 열린다. 선택 · 사유는 화면 초안(손대지 않았을 때만 서버 새 값을 받는다).
// 처리 중 표시는 보내기 버튼에만, 성공 뒤에는 잠근 채 둔다. 출퇴근 버튼 없음 — 신고만 한다.
import SwiftUI

struct BreakReportView: View {
    let state: BreakReportState
    /// 서버 값 — nil이면 시트를 열지 않는다
    let sheet: BreakReportSheetState?

    @State private var sheetOpen: Bool
    @State private var choiceID: String
    @State private var reason: String
    @State private var touched = false
    @State private var isSending = false
    @State private var isSent = false
    /// 시트 값이 오기 전에 눌렀다 — 값이 오면 연다
    @State private var pendingOpen = false
    private let startsFocused: Bool

    var onBack: () -> Void
    /// 「휴게 시간이 달랐어요」 — 시트 값을 불러오는 것은 호출자 몫
    var onReportBreak: () -> Void
    /// 보내기(선택, 사유) — 끝나면 done(성공 여부). 실패면 버튼이 풀리고, 성공이면 잠근 채 둔다
    var onSend: (BreakChoice, String, @escaping (Bool) -> Void) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    init(state: BreakReportState,
         sheet: BreakReportSheetState? = nil,
         startsWithSheetOpen: Bool = false,
         onBack: @escaping () -> Void = {},
         onReportBreak: @escaping () -> Void = {},
         onSend: @escaping (BreakChoice, String, @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }) {
        self.state = state
        self.sheet = sheet
        _sheetOpen = State(initialValue: startsWithSheetOpen && sheet != nil)
        _choiceID = State(initialValue: sheet?.initialChoiceID ?? "")
        _reason = State(initialValue: sheet?.initialReason ?? "")
        startsFocused = startsWithSheetOpen
        self.onBack = onBack
        self.onReportBreak = onReportBreak
        self.onSend = onSend
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    titleBlock
                    recordCard
                    reportCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .pumBottomSheet(isPresented: $sheetOpen) {
            if let sheet {
                BreakReportSheet(
                    state: sheet,
                    choiceID: $choiceID,
                    reason: $reason,
                    isSending: isSending,
                    isSent: isSent,
                    startsFocused: startsFocused,
                    onEdit: { touched = true },
                    onSend: send
                )
            }
        }
        .onChange(of: sheet) { _, new in
            if !touched && !isSending && !isSent { // 보내는 중 · 보낸 뒤에는 보낸 값 그대로
                choiceID = new?.initialChoiceID ?? ""
                reason = new?.initialReason ?? ""
            }
            if new == nil { sheetOpen = false }
            if new != nil && pendingOpen { pendingOpen = false; sheetOpen = true }
        }
    }

    private func openSheet() {
        onReportBreak()
        if sheet != nil { sheetOpen = true } else { pendingOpen = true }
    }

    private func send() {
        guard let sheet, !isSending, !isSent, let input = sheet.input(choiceID: choiceID, reason: reason) else { return }
        isSending = true
        onSend(input.choice, input.reason) { ok in
            isSending = false
            if ok { isSent = true }
        }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(BreakReportState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(BreakReportState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 배지 줄~제목 6
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { badge; subtitle }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { badge; subtitle }
            }
            Text(state.dateTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s2) // 원문 padding 2 4 0
    }

    private var badge: some View {
        PumBadge(text: BreakReportState.badgeText, kind: .done)
    }

    private var subtitle: some View {
        Text(BreakReportState.subtitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
    }

    // MARK: 카드

    private var recordCard: some View {
        PumCard {
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                recordRow(row)
            }
        }
    }

    private func recordRow(_ row: BreakReportRow) -> some View {
        let key = Text(row.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
        let value = Text(row.value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { key; Spacer(minLength: PumTokens.Space.s8); value }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { key; value }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.readout))
    }

    private var reportCard: some View {
        PumCard {
            Button(action: openSheet) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(BreakReportState.reportTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(BreakReportState.reportDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").pumText(.callout, weight: .semibold)
                        .foregroundStyle(PumColor.textTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Size.rowPadY)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.reportReadout))
            .accessibilityAddTraits(.isButton)
        }
    }
}

#Preview("19h 출퇴근 기록") { BreakReportView(state: .sample, sheet: .sample) }
#Preview("19h 휴게 시트") { BreakReportView(state: .sample, sheet: .sample, startsWithSheetOpen: true) }
#Preview("19h · 큰 글자") { BreakReportView(state: .sample, sheet: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("19h 시트 · 큰 글자") { BreakReportView(state: .sample, sheet: .sample, startsWithSheetOpen: true).dynamicTypeSize(.xxxLarge) }
