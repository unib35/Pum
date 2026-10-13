// UI-IOS-17d · REQ-050 — 게시 후 변경 시트(게시된 주 17a 위 · C9 바텀시트 안 내용)
// 바로 바꾸지 않고 직원에게 변경 요청을 보낸다 — 수락 전까지 기존 근무로 계산한다.
// 시간 · 인정 근무 · 예상 급여는 서버(엔진) 값 그대로(화면 계산 없음). 사유 입력만 화면 초안.
import SwiftUI

nonisolated struct PublishedChangeSheetState: Equatable, Sendable {
    /// 「게시된 근무 변경」
    let title: String
    /// 「게시됨」(연초록 배지)
    let badge: String
    let staffName: String
    let colorIndex: Int
    /// 「김하늘 · 10월 7일 수」
    let rowTitle: String
    /// 「휴게 30분」
    let note: String
    /// 기존 근무(서버) — 「17:00」 ~ 「22:00」
    let beforeStart: String
    let beforeEnd: String
    /// 변경 근무(서버)
    let afterStart: String
    let afterEnd: String
    /// 「인정 근무」 · 「4h 30m → 3h 30m」
    let workedLabel: String
    let workedText: String
    /// 「예상 급여」 · 「−12,000원」
    let payLabel: String
    let payText: String
    /// 「사유 · 직원에게 보여요」
    let reasonLabel: String
    /// 사유 입력의 바탕 값(처음 열릴 때 · 서버 새 값이 올 때)
    let initialReason: String
    /// 「김하늘님이 수락하면 바뀌어요 · 응답 전까지 기존 근무」
    let footnote: String
    /// 요청 보내는 중(서버)
    let isSending: Bool

    static let beforeLabel = "기존"
    static let afterLabel = "변경"
    static let sendTitle = "변경 요청 보내기"
    static let sendingTitle = "보내는 중"

    var beforeText: String { "\(beforeStart) \u{2013} \(beforeEnd)" }
    var afterText: String { "\(afterStart) \u{2013} \(afterEnd)" }

    /// 「기존 17:00부터 22:00, 변경 18:00부터 22:00」
    var spokenTimes: String {
        "\(Self.beforeLabel) \(beforeStart)부터 \(beforeEnd), \(Self.afterLabel) \(afterStart)부터 \(afterEnd)"
    }

    /// 「인정 근무 4h 30m → 3h 30m, 예상 급여 −12,000원」
    var spokenSummary: String { "\(workedLabel) \(workedText), \(payLabel) \(payText)" }
}

nonisolated extension PublishedChangeSheetState {
    static let sample = PublishedChangeSheetState(
        title: "게시된 근무 변경", badge: "게시됨",
        staffName: "김하늘", colorIndex: 1,
        rowTitle: "김하늘 \u{00B7} 10월 7일 수", note: "휴게 30분",
        beforeStart: "17:00", beforeEnd: "22:00",
        afterStart: "18:00", afterEnd: "22:00",
        workedLabel: "인정 근무", workedText: "4h 30m \u{2192} 3h 30m",
        payLabel: "예상 급여", payText: "\u{2212}12,000원",
        reasonLabel: "사유 \u{00B7} 직원에게 보여요", initialReason: "저녁 단체 예약 취소",
        footnote: "김하늘님이 수락하면 바뀌어요 \u{00B7} 응답 전까지 기존 근무",
        isSending: false)
}

struct PublishedChangeSheet: View {
    private let state: PublishedChangeSheetState
    private let onSend: (String) -> Void
    @State private var reason: String
    @FocusState private var reasonFocused: Bool
    @ScaledMetric(relativeTo: .callout) private var avatar: CGFloat = 40

    init(state: PublishedChangeSheetState, onSend: @escaping (String) -> Void = { _ in }) {
        self.state = state
        self.onSend = onSend
        _reason = State(initialValue: state.initialReason)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            header
            person
            timeBlock
            summaryCard
            reasonBlock
            PumButton(title: PublishedChangeSheetState.sendTitle, isLoading: state.isSending,
                      loadingTitle: PublishedChangeSheetState.sendingTitle) { onSend(reason) }
            Text(state.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
        // 서버가 새 사유 바탕을 주면, 손대지 않았을 때만 다시 받는다 — 입력 중인 글을 말없이 지우지 않게
        .onChange(of: state.initialReason) { old, new in
            if reason == old { reason = new }
        }
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                title
                Spacer(minLength: PumTokens.Space.s8)
                PumBadge(text: state.badge, kind: .done)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                PumBadge(text: state.badge, kind: .done)
            }
        }
    }

    private var title: some View {
        Text(state.title).pumText(.title3).foregroundStyle(PumColor.textPrimary) // 20px 700
            .accessibilityAddTraits(.isHeader)
    }

    private var person: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: state.staffName, colorIndex: state.colorIndex, size: avatar)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.rowTitle).pumText(.callout).foregroundStyle(PumColor.textPrimary)   // 14px 600
                Text(state.note).pumText(.caption).foregroundStyle(PumColor.textSecondary)     // 12px 400
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 기존 | 변경

    private var timeBlock: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: PumTokens.Space.s8) { beforeBox; afterBox }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { beforeBox; afterBox }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.spokenTimes))
    }

    private var beforeBox: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(PublishedChangeSheetState.beforeLabel).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            Text(state.beforeText).pumText(.headline, weight: .bold) // 18px 700 → headline(17)
                .strikethrough()
                .foregroundStyle(PumColor.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var afterBox: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(PublishedChangeSheetState.afterLabel).pumText(.caption).foregroundStyle(PumColor.accent)
            Text(state.afterText).pumText(.headline, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
    }

    // MARK: 인정 근무 · 예상 급여(서버 값)

    private var summaryCard: some View {
        PumCard {
            summaryRow(state.workedLabel, state.workedText)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            summaryRow(state.payLabel, state.payText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.spokenSummary))
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                Text(label).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800) // 14px 400
                Spacer(minLength: PumTokens.Space.s8)
                Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)           // 14px 700
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(label).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
                Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .padding(.vertical, PumTokens.Space.s8)
    }

    // MARK: 사유

    private var reasonBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text(state.reasonLabel).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumTokens.ColorToken.gray800) // 13px 600
            TextField("", text: $reason)
                .pumText(.headline, weight: .medium) // 16px 500 → headline(17)
                .foregroundStyle(PumColor.textPrimary)
                .focused($reasonFocused)
                .submitLabel(.done)
                .onSubmit { reasonFocused = false }
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.buttonH, alignment: .leading)
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                        .stroke(reasonFocused ? PumColor.accent : PumColor.borderHairline,
                                lineWidth: reasonFocused ? PumTokens.Shadow.outline.spread : PumTokens.Shadow.hairline.spread)
                }
                .accessibilityLabel(Text(state.reasonLabel))
        }
    }
}

#Preview("17d 시트") { PublishedChangeSheet(state: .sample).background(PumColor.bgApp) }
