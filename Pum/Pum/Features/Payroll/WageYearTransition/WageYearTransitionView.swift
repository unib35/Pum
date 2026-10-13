// UI-IOS-19a · UI-IOS-19b · REQ-082 — 사장님 · 연도 전환 (하위 화면, 탭 바 없음) + 새 시급 정하기 시트
// 시트는 서버 값(sheet)이 있을 때만 열린다. 시급 입력은 화면 초안(손대지 않았을 때만 서버 새 값을 받는다).
// 처리 중 표시는 보내기 버튼에만, 성공 뒤에는 잠근 채 둔다. 원문 없음: 최저 미만이면 보내기 비활성 + 그 행에 이유.
import SwiftUI

struct WageYearTransitionView: View {
    let state: WageYearTransitionState
    /// 서버 값 — nil이면 시트를 열지 않는다
    let sheet: NewWageSheetState?

    @State private var sheetOpen: Bool
    @State private var draft: [String: Int]
    /// 손대지 않았을 때만 서버 새 값을 받는다
    @State private var touched = false
    @State private var isSending = false
    @State private var isSent = false
    /// 시트 값이 오기 전에 「새 시급 정하기」를 눌렀다 — 값이 오면 연다
    @State private var pendingOpen = false

    var onBack: () -> Void
    /// 「새 시급 정하기」 — 시트 값을 불러오는 것은 호출자 몫
    var onSetWages: () -> Void
    var onShowFine: () -> Void
    /// 보내기(직원별 새 시급) — 끝나면 done(성공 여부). 실패면 버튼이 풀리고, 성공이면 잠근 채 둔다
    var onSend: ([NewWageInput], @escaping (Bool) -> Void) -> Void

    /// 아바타 지름 — 원문 약 30
    @ScaledMetric(relativeTo: .callout) private var avatarSize: CGFloat = 30

    init(state: WageYearTransitionState,
         sheet: NewWageSheetState? = nil,
         startsWithSheetOpen: Bool = false,
         onBack: @escaping () -> Void = {},
         onSetWages: @escaping () -> Void = {},
         onShowFine: @escaping () -> Void = {},
         onSend: @escaping ([NewWageInput], @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.sheet = sheet
        _sheetOpen = State(initialValue: startsWithSheetOpen && sheet != nil)
        _draft = State(initialValue: sheet?.initialWages ?? [:])
        self.onBack = onBack
        self.onSetWages = onSetWages
        self.onShowFine = onShowFine
        self.onSend = onSend
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    titleBlock
                    if !state.below.isEmpty { belowCard }
                    if !state.thin.isEmpty { thinCard }
                    if !state.fine.isEmpty || !state.excluded.isEmpty { fineCard }
                    holidayCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .pumBottomSheet(isPresented: $sheetOpen) {
            if let sheet {
                NewWageSheet(
                    state: sheet,
                    draft: $draft,
                    isSending: isSending,
                    isSent: isSent,
                    onEdit: { touched = true },
                    onCancel: { sheetOpen = false },
                    onSend: send
                )
            }
        }
        .onChange(of: sheet) { _, new in
            if !touched { draft = new?.initialWages ?? [:] }
            if new == nil { sheetOpen = false }
            if new != nil && pendingOpen { pendingOpen = false; sheetOpen = true }
        }
    }

    private func openSheet() {
        onSetWages()
        if sheet != nil { sheetOpen = true } else { pendingOpen = true }
    }

    private func send() {
        guard let sheet, sheet.canSend(draft), !isSending, !isSent else { return }
        isSending = true
        onSend(sheet.inputs(draft)) { ok in
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
                    Text(WageYearTransitionState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(WageYearTransitionState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.effectiveDateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.minimumTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(state.increaseLine).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .padding(.top, -PumTokens.Space.s2) // 원문 제목~증가 줄 2
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s2) // 원문 padding 2 4 0
        .accessibilityElement(children: .combine)
    }

    private func cardHeader(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.top, PumTokens.Space.s14) // 원문 머리 padding 14 16 4
            .padding(.bottom, PumTokens.Space.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: 카드

    private var belowCard: some View {
        PumCard {
            cardHeader(state.belowHeader)
            ForEach(Array(state.below.enumerated()), id: \.element.id) { i, e in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                employeeRow(e, badge: PumBadge(text: WageYearTransitionState.belowBadge, kind: .attention), readout: state.belowReadout(e))
            }
        }
    }

    private var thinCard: some View {
        PumCard {
            cardHeader(state.thinHeader)
            ForEach(Array(state.thin.enumerated()), id: \.element.id) { i, e in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                employeeRow(e, badge: PumBadge(text: state.marginBadge(e), kind: .waiting), readout: state.thinReadout(e))
            }
        }
    }

    private func employeeRow(_ e: WageEmployee, badge: PumBadge, readout: String) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: e.name, colorIndex: e.colorIndex, size: avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(e.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(state.currentLine(e)).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            badge
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(readout))
    }

    private var fineCard: some View {
        PumCard {
            cardHeader(WageYearTransitionState.fineHeader)
            if !state.fine.isEmpty {
                Button(action: onShowFine) {
                    HStack(spacing: PumTokens.Space.s12) {
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            Text(state.fineNames).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                            Text(state.fineWages).pumText(.caption).foregroundStyle(PumColor.textSecondary)
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
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.fineReadout))
                .accessibilityAddTraits(.isButton)
            }
            ForEach(state.excluded) { e in
                Divider().overlay(PumColor.borderHairline)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(e.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.excludedDetail(e)).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Size.rowPadY)
                .frame(minHeight: PumTokens.Size.tapMin)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.excludedReadout(e)))
            }
        }
    }

    private var holidayCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(WageYearTransitionState.holidayTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(WageYearTransitionState.holidayDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s10) { // 원문 버튼~안내 10
            PumButton(title: WageYearTransitionState.setWagesTitle, action: openSheet)
            Text(state.footerNotice)
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s10) // 원문 하단 44 − 홈 막대 안전 영역 34
        .background(PumColor.bgApp)
    }
}

#Preview("19a 연도 전환") { WageYearTransitionView(state: .sample, sheet: .sample) }
#Preview("19b 새 시급 정하기") { WageYearTransitionView(state: .sample, sheet: .sample, startsWithSheetOpen: true) }
#Preview("19a · 큰 글자") { WageYearTransitionView(state: .sample, sheet: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("19b · 큰 글자") { WageYearTransitionView(state: .sample, sheet: .sample, startsWithSheetOpen: true).dynamicTypeSize(.xxxLarge) }
