// UI-IOS-9b · REQ-051 — 추천 3안: 최저가만이 아니라 변경 정도까지 비교. 탭 바 없음.
// 색: 초록 = 충족 · 비용 감소 / 주황 = 처리 필요(부족) / 파랑 = 선택. 최저가라는 이유로 따로 강조하지 않는다(선택 테두리만).
// 금액 · 차이 · 건수는 서버(엔진) 값 그대로 — 화면에서 계산하지 않는다.
import SwiftUI

struct ScheduleOptionsView: View {
    let state: ScheduleOptionsState
    var onBack: () -> Void = {}
    var onSelect: (String) -> Void = { _ in }
    var onShowDetail: (String) -> Void = { _ in }

    @State private var selectedID: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: ScheduleOptionsState = .sample,
         onBack: @escaping () -> Void = {},
         onSelect: @escaping (String) -> Void = { _ in },
         onShowDetail: @escaping (String) -> Void = { _ in }) {
        self.state = state
        self.onBack = onBack
        self.onSelect = onSelect
        self.onShowDetail = onShowDetail
        _selectedID = State(initialValue: state.selectedID)
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    currentCard
                    ForEach(Array(state.options.enumerated()), id: \.element.id) { index, option in
                        optionCard(option, index: index)
                    }
                    Text(state.notice)
                        .pumText(.caption, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            bottomButton
        }
        .background(PumColor.bgApp)
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: selectedID)
    }

    // MARK: 현재 스케줄

    private var currentCard: some View {
        PumCard(attention: true) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                    currentLeading.frame(maxWidth: .infinity, alignment: .leading)
                    shortagePill
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 넘치면 알약은 아래로
                    currentLeading
                    shortagePill
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.currentAccessibilityText))
        }
    }

    private var currentLeading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.currentTitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            Text(state.currentText + "원").pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 18px 700 → 17px 근사
        }
    }

    @ViewBuilder private var shortagePill: some View {
        if let text = state.shortageText {
            Text(text)
                .pumText(.caption, weight: .semibold)
                .foregroundStyle(PumColor.statusAttention)
                .padding(.horizontal, PumTokens.Space.s12)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.statusAttentionSoft, in: Capsule())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 3안 카드
    // 공통 후보: 「오른쪽 위에 값(차이)이 있는 선택 카드」. PumChoiceCard는 그 자리에 라디오가 고정이라 맞지 않아 화면 전용으로 만들고,
    // 같은 모양(모서리 lg · 선택 2pt 파랑 테두리)은 PumChoiceCardStyle 값을 쓴다.

    private func optionCard(_ option: ScheduleOption, index: Int) -> some View {
        let isOn = option.id == selectedID
        let r = PumTokens.Radius.lg
        return Button {
            selectedID = option.id
            onSelect(option.id)
        } label: {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                        Text(option.name).pumText(.footnote, weight: .bold)
                            .foregroundStyle(isOn ? PumColor.accent : PumTokens.ColorToken.gray700)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(option.deltaText).pumText(.footnote, weight: .bold)
                            .foregroundStyle(option.direction == .decrease ? PumColor.statusDone : PumTokens.ColorToken.gray700)
                    }
                    Text(option.totalText + "원").pumText(.title2).foregroundStyle(PumColor.textPrimary)
                    Text(option.changeText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                checkRow(option)
            }
            .padding(PumChoiceCardStyle.padding)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(isOn ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: isOn ? PumChoiceCardStyle.selectedRing : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(option.accessibilityText))
        .accessibilityValue(Text("\(state.options.count)개 중 \(index + 1)번째"))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    /// 한 줄에 안 들어가면 줄바꿈
    private func checkRow(_ option: ScheduleOption) -> some View {
        let items = option.checks
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                ForEach(items, id: \.title) { checkItem($0) }
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                ForEach(items, id: \.title) { checkItem($0) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkItem(_ item: ScheduleOptionCheck) -> some View {
        HStack(spacing: PumTokens.Space.s4) {
            if item.met {
                Image(systemName: "checkmark").font(.caption.weight(.bold)).accessibilityHidden(true)
            }
            Text(item.title).pumText(.footnote, weight: .semibold)
        }
        .foregroundStyle(item.met ? PumColor.statusDone : PumColor.textSecondary)
    }

    // MARK: 하단

    private var bottomButton: some View {
        let title = state.option(id: selectedID)?.detailTitle ?? ""
        return PumButton(title: title, kind: .primary) { onShowDetail(selectedID) }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s12)
    }
}

#Preview("9b") { ScheduleOptionsView(state: .sample) }
#Preview("9b · 큰 글자") { ScheduleOptionsView(state: .sample).dynamicTypeSize(.xxxLarge) }
