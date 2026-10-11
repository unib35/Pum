// UI-IOS-1ao · REQ-026 · REQ-029 — 조기 퇴근 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값
enum EarlyLeaveLocal {
    /// 라디오 원 지름 약 22
    static let radioSize: CGFloat = 22
    /// 선택 점 / 원 비율
    static let dotRatio: CGFloat = 0.36
    /// 빈 라디오 테두리 두께
    static let radioStroke: CGFloat = 1.5
    /// 뒤 카드 안 흰 글자 투명도(목업 80–85%)
    static let cardTextOpacity = 0.8
}

struct EarlyLeaveSheet: View {
    let state: EarlyLeaveState
    var onSelect: (EarlyLeaveReason) -> Void = { _ in }
    var onContinue: () -> Void = {}
    var onRecord: () -> Void = {}

    @ScaledMetric private var radio = EarlyLeaveLocal.radioSize
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            compareCards
            Text("사유").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
            reasonList
            if state.needsOwnerCheck { notice }
            PumButtonPair(negative: "계속 근무", positive: state.recordTitle, negativeKind: .outline,
                          onNegative: onContinue, onPositive: onRecord)
                .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
        .task {
            try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
            titleFocused = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            // 목업 22px 700 → title3(20) — 1j 시트와 같은 선택
            Text("예정보다 일찍 퇴근해요").pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(state.subtitlePrefix).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                Text(state.earlyText).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.statusAttention)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var compareCards: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { plannedCell; actualCell }
                VStack(spacing: PumTokens.Space.s8) { plannedCell; actualCell }
            }
            .padding(PumTokens.Space.s8)
        }
    }

    private var plannedCell: some View {
        cell(label: "예정", range: state.plannedRange, line: state.plannedRecognizedLine,
             background: PumColor.surfaceFill, accent: PumColor.textSecondary)
    }

    private var actualCell: some View {
        cell(label: "실제", range: state.actualRange, line: state.actualRecognizedLine,
             background: PumColor.statusAttentionSoft, accent: PumColor.statusAttention)
    }

    private func cell(label: String, range: String, line: String, background: Color, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2).foregroundStyle(accent)
            Text(range).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(line).pumText(.caption).foregroundStyle(accent)
        }
        .padding(PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label) \(range), \(line)"))
    }

    private var reasonList: some View {
        let all = EarlyLeaveReason.allCases
        return PumCard {
            ForEach(Array(all.enumerated()), id: \.offset) { index, reason in
                if index > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.leading, PumTokens.Size.rowPadX)
                }
                reasonRow(reason, index: index, count: all.count)
            }
        }
    }

    private func reasonRow(_ reason: EarlyLeaveReason, index: Int, count: Int) -> some View {
        let on = state.selected == reason
        return Button { onSelect(reason) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                radioMark(on: on)
                Text(reason.title)
                    .pumText(.callout, weight: on ? .semibold : .regular)
                    .foregroundStyle(on ? PumColor.textPrimary : PumTokens.ColorToken.gray800)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(reason.title), \(on ? "선택됨, " : "")\(count)개 중 \(index + 1)번째"))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func radioMark(on: Bool) -> some View {
        ZStack {
            if on {
                Circle().fill(PumColor.accent)
                Circle().fill(.white).frame(width: radio * EarlyLeaveLocal.dotRatio)
            } else {
                Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: EarlyLeaveLocal.radioStroke)
            }
        }
        .frame(width: radio, height: radio)
    }

    private var notice: some View {
        (Text(state.noticeLead)
            + Text(EarlyLeaveState.noticeStrong).fontWeight(.bold)
            + Text(EarlyLeaveState.noticeTail))
            .pumText(.caption)
            .foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
