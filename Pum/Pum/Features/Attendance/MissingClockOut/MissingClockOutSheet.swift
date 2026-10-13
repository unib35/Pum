// UI-IOS-1al · REQ-025 — 실제 퇴근시간 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값
enum MissingClockOutLocal {
    /// 시간 칸 크기(원문 약 86×60). 큰 글자에서 커진다
    static let timeCellWidth: CGFloat = 86
    static let timeCellHeight: CGFloat = 60
}

struct MissingClockOutSheet: View {
    let state: MissingClockOutState
    var onSelectField: (MissingClockOutField) -> Void = { _ in }
    var onStep: (MissingClockOutField, Int) -> Void = { _, _ in }
    var onSelect: (MissingClockOutReason) -> Void = { _ in }
    var onRequest: () -> Void = {}

    @ScaledMetric private var cellW = MissingClockOutLocal.timeCellWidth
    @ScaledMetric private var cellH = MissingClockOutLocal.timeCellHeight
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            // 목업 22px 700 → title3(20) — 1ao와 같은 선택
            Text("실제 몇 시에 퇴근했나요?").pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
            timeCard
            reasonList
            Text("사장님이 확인하면 근무기록이 확정돼요. 수정 요청과 같은 경로로 처리되고 이력이 남아요.")
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Space.s4) // 원문: 카드보다 약 4 안쪽
            PumButton(title: "사장님께 확인 요청", action: onRequest)
                .disabled(!state.canRequest)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
        .task {
            try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
            titleFocused = true
        }
    }

    // MARK: 시간 칸 + 한 줄

    /// 원문 1al: 시간 칸만 흰 카드 안, 「예정보다 …」 줄은 카드 아래(4 안쪽)
    private var timeCard: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumCard {
                HStack(spacing: PumTokens.Space.s14) { // 원문 gap 14
                    timeCell(.hour, text: String(format: "%02d", state.hour), label: "시")
                    Text(":").pumText(.display).foregroundStyle(PumTokens.ColorToken.gray400)
                        .accessibilityHidden(true)
                    timeCell(.minute, text: String(format: "%02d", state.minute), label: "분")
                }
                .frame(maxWidth: .infinity)
                .padding(PumTokens.Space.s18) // 원문 카드 padding 18
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { offsetLabel; Spacer(minLength: PumTokens.Space.s8); recognizedLabel }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) { offsetLabel; recognizedLabel }
            }
            .padding(.horizontal, PumTokens.Space.s4)
        }
    }

    private var offsetLabel: some View {
        Text(state.offsetText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    @ViewBuilder
    private var recognizedLabel: some View {
        if let line = state.recognizedLine {
            // 서버(엔진) 값 그대로
            Text(line).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        }
    }

    private func timeCell(_ field: MissingClockOutField, text: String, label: String) -> some View {
        let on = state.selectedField == field
        return Button { onSelectField(field) } label: {
            // 목업 44px 700 → display(52): 가까운 단계(DEC-005)
            Text(text).pumText(.display)
                .foregroundStyle(on ? PumColor.accent : PumColor.textPrimary)
                .frame(width: cellW, height: cellH)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                .background(on ? PumColor.accentSoftStrong : PumColor.surfaceFill,
                            in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(Int(text) ?? 0)"))
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onStep(field, 1)
            case .decrement: onStep(field, -1)
            @unknown default: break
            }
        }
    }

    // MARK: 사유 라디오

    private var reasonList: some View {
        let all = MissingClockOutReason.allCases
        return PumCard {
            ForEach(Array(all.enumerated()), id: \.offset) { index, reason in
                if index > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.horizontal, PumTokens.Size.rowPadX)
                }
                reasonRow(reason, index: index, count: all.count)
            }
        }
    }

    /// 공통 라디오 행(PumRadioRow) — 선택은 600 먹색, 나머지 400 gray800
    private func reasonRow(_ reason: MissingClockOutReason, index: Int, count: Int) -> some View {
        PumRadioRow(title: reason.title, isOn: state.selected == reason, index: index, count: count) { onSelect(reason) }
    }
}
