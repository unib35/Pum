// UI-IOS-8e · REQ-052 — 시뮬레이션 결과: 이번 달 인건비 비교 · 스케줄 반영은 별도 확인. 탭 바 없음.
// 이 화면은 실제 데이터를 바꾸지 않는다. 「스케줄에 추가」는 별도 확인 화면으로 가는 동작만 알린다(그래서 잠금 없음).
// 색: 파랑 = 강조(추가 후 · 바뀐 요일 · 주 버튼 · 9a). 현재 · 변화 없음 = 먹색/회색.
import SwiftUI

struct LaborSimulatorResultView: View {
    var state: LaborSimulatorResultState = .sample
    var onBack: () -> Void = {}
    var onOpenRecommend: () -> Void = {}
    /// 스케줄 반영은 별도 확인 화면에서 — 여기서는 이동만
    var onAddToSchedule: () -> Void = {}
    var onSaveOnly: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    compareCard
                    PumSectionHeader(title: state.weekdayHeader)
                    weekdayCard
                    recommendCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            bottomButtons
        }
        .background(PumColor.bgApp)
    }

    // MARK: 비교 카드

    private var compareCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                Text(state.compareTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                ViewThatFits(in: .horizontal) {
                    // 원문: 두 열 같은 폭 · 화살표는 카드 가운데
                    HStack(alignment: .bottom, spacing: PumTokens.Space.s12) {
                        currentColumn.frame(maxWidth: .infinity, alignment: .leading)
                        arrow(systemName: "arrow.right").padding(.bottom, PumTokens.Space.s4)
                        afterColumn.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        currentColumn
                        arrow(systemName: "arrow.down")
                        afterColumn
                    }
                }
                (Text(state.deltaAmountText).foregroundStyle(PumColor.textPrimary)
                 + Text(state.deltaPercentSuffix).foregroundStyle(PumColor.textSecondary))
                    .pumText(.footnote)
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.compareAccessibilityText))
        }
    }

    private var currentColumn: some View {
        amountColumn("현재", state.currentText, label: PumColor.textSecondary, labelWeight: .regular, value: PumColor.textPrimary)
    }

    private var afterColumn: some View {
        amountColumn("추가 후", state.afterText, label: PumColor.accent, labelWeight: .semibold, value: PumColor.accent)
    }

    private func amountColumn(_ title: String, _ value: String, label: Color, labelWeight: Font.Weight, value valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.caption, weight: labelWeight).foregroundStyle(label)
            Text(value).pumText(.title3).foregroundStyle(valueColor) // 원문 20px 700
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func arrow(systemName: String) -> some View {
        Image(systemName: systemName).font(.callout.weight(.semibold))
            .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
    }

    // MARK: 요일별 인원

    private var weekdayCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(state.weekdays) { weekdayColumn($0) }
                }
                VStack(spacing: PumTokens.Space.s12) { // 넓은 글자에서는 두 줄(4 + 3), 축소하지 않는다
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(state.weekdays.prefix(4)) { weekdayColumn($0) }
                    }
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(state.weekdays.dropFirst(4)) { weekdayColumn($0) }
                        ForEach(0..<max(0, 4 - state.weekdays.dropFirst(4).count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity, minHeight: 1).accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(.horizontal, PumTokens.Space.s12)
            .padding(.vertical, PumTokens.Space.s14)
        }
    }

    private func weekdayColumn(_ day: LaborSimulatorWeekday) -> some View {
        VStack(spacing: PumTokens.Space.s2) {
            Text(day.name).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 원문 11px
            Text(day.headcountText).pumText(.body, weight: .bold) // 원문 15px 700
                .foregroundStyle(day.isChanged ? PumColor.accent : PumColor.textPrimary)
                .lineLimit(1).fixedSize()
            Text(day.changeText).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary) // 원문 10px → 11px 근사
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.accessibilityText))
    }

    // MARK: 스케줄 추천 행

    private var recommendCard: some View {
        PumCard {
            Button(action: onOpenRecommend) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.recommendTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.recommendSubtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(state.recommendTag) \u{203A}").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.accent)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(state.recommendTitle), \(state.recommendSubtitle)"))
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: 하단

    private var bottomButtons: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: state.addTitle, kind: .primary, action: onAddToSchedule)
            // 원문은 한 줄 전체가 회색 글자 — 「저장만 하기」만 눌리는 글자 버튼, 뒤는 안내
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) { saveOnlyButton; Text(state.saveOnlyNotice) }
                VStack(spacing: 0) { saveOnlyButton; Text(state.saveOnlyNotice) }
            }
            .pumText(.callout, weight: .regular)
            .foregroundStyle(PumColor.textSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s12)
    }

    private var saveOnlyButton: some View {
        Button(action: onSaveOnly) {
            Text(state.saveOnlyTitle)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("8e") { LaborSimulatorResultView(state: .sample) }
#Preview("8e · 큰 글자") { LaborSimulatorResultView(state: .sample).dynamicTypeSize(.xxxLarge) }
