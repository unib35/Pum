// UI-IOS-8d · REQ-052 — 인건비 시뮬레이터(하위 화면, 탭 바 없음). 실제 데이터는 바뀌지 않는다.
// 시간 · 휴게 칸 → C13 시간 선택 시트(2j와 같은 방식). 시급 · 기간 · 시간 변경 · 시급 변경은 화면이 없어 클로저만 부른다.
// 결과 카드는 지금 입력이 계산 조건과 같을 때만 숫자 · 내역을 보인다(다르면 머리만 남기고 부모에 알림).
import SwiftUI

struct LaborSimulatorView: View {
    @State private var state: LaborSimulatorState
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()
    var onClose: () -> Void
    var onSelectMode: (LaborSimulatorMode) -> Void
    var onEditWage: () -> Void
    var onPickPeriod: () -> Void
    /// 입력이 바뀔 때마다 — 부모가 엔진에 다시 계산을 요청한다
    var onInputsChanged: (LaborSimulatorInputs) -> Void
    var onShowResult: () -> Void
    /// 부모가 엔진에서 받은 최신 결과(계산 조건 포함). 바뀌면 화면 결과를 바꾼다 — 조건이 지금 입력과 같을 때만 보인다.
    var latestResult: LaborSimulatorResult?

    // 화면 전용 상수 (DEC-005)
    /// 요일 칩 지름 — 원문 30
    @ScaledMetric(relativeTo: .caption) private var chipSize = PumTimePickerStyle.weekdayChip
    /// 값 알약 최소 높이 — 원문 약 28
    @ScaledMetric(relativeTo: .body) private var pillHeight: CGFloat = 28

    init(state: LaborSimulatorState = .sample,
         onClose: @escaping () -> Void = {},
         onSelectMode: @escaping (LaborSimulatorMode) -> Void = { _ in },
         onEditWage: @escaping () -> Void = {},
         onPickPeriod: @escaping () -> Void = {},
         onInputsChanged: @escaping (LaborSimulatorInputs) -> Void = { _ in },
         onShowResult: @escaping () -> Void = {},
         latestResult: LaborSimulatorResult? = nil) {
        _state = State(initialValue: state)
        self.latestResult = latestResult
        self.onClose = onClose
        self.onSelectMode = onSelectMode
        self.onEditWage = onEditWage
        self.onPickPeriod = onPickPeriod
        self.onInputsChanged = onInputsChanged
        self.onShowResult = onShowResult
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    segments
                    inputCard
                    resultCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: latestResult) { _, new in if let new { state.result = new } } // 엔진 새 결과
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            state.apply(picked: pickerValue)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: LaborSimulatorState.detailTitle, kind: .primary, action: onShowResult)
                .disabled(!state.canShowDetail)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12) // 원문 위 12 · 아래 44 − 안전 영역 34 = 10
                .padding(.bottom, PumTokens.Space.s10)
                .background(PumColor.bgApp)
        }
        .onChange(of: state.inputs) { _, new in onInputsChanged(new) }
    }

    /// 시간 · 휴게만 켠다(날짜 · 반복 · 종료일 없음)
    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(showsDate: false, showsBreak: true, showsRepeat: false, showsEndDate: false)
    }

    private func openPicker() {
        pickerValue = state.pickerValue
        pickerOpen = true
    }

    // MARK: 헤더

    private var header: some View {
        ZStack {
            Text(LaborSimulatorState.title).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    // MARK: 세그먼트 — 공통 후보(세그먼트 컨트롤이 공통에 없어 화면 전용)

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(LaborSimulatorMode.allCases, id: \.self) { mode in
                let selected = mode == state.mode
                Button { onSelectMode(mode) } label: {
                    Text(mode.title)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, PumTokens.Space.s8) // 원문 칸 padding 7 0
                        .frame(maxWidth: .infinity)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.pill, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        // 누름 영역만 44 이상으로 키우고 배치는 원문 칸 높이만 쓴다
                        .padding(.vertical, PumTokens.Space.s6)
                        .contentShape(Rectangle())
                        .padding(.vertical, -PumTokens.Space.s6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(mode.title))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2) // 원문 3 → 가까운 2
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.pill, style: .continuous))
    }

    // MARK: 입력 카드

    private var inputCard: some View {
        PumCard {
            row("시급") { valuePill(state.wageText, tint: .blue, label: "시급 \(state.wageText)", action: onEditWage) }
            divider
            weekdayRow
            divider
            row("근무 시간") {
                valuePill(state.timeText, tint: .gray, label: "근무 시간 \(state.timeSpoken)", action: openPicker)
            }
            divider
            row("휴게") { valuePill(state.breakText, tint: .gray, label: "휴게 \(state.breakText)", action: openPicker) }
            divider
            row("기간") {
                valuePill(state.inputs.periodText, tint: .gray, label: "기간 \(state.inputs.periodText)", action: onPickPeriod)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    /// 라벨 왼쪽 · 값 오른쪽. 큰 글자에서 한 줄에 안 들어가면 값이 라벨 아래로 내려간다
    private func row<V: View>(_ label: String, @ViewBuilder value: () -> V) -> some View {
        let l = rowLabel(label), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private enum PillTint { case blue, gray }

    private func valuePill(_ text: String, tint: PillTint, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).pumText(.body, weight: .semibold)
                .foregroundStyle(tint == .blue ? PumColor.accent : PumColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, PumTokens.Space.s12)
                .frame(minHeight: pillHeight)
                .background(tint == .blue ? PumColor.accentSoft : PumColor.surfaceFill,
                            in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 요일 칩 — 화면 안에서 바로 토글

    private var weekdayRow: some View {
        let l = rowLabel("근무 요일")
        let days = PumTimePickerStyle.weekdays
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); chips(days) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { l; chips(days) }
            // 이것도 넘치면 두 줄(4 + 3)
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                l
                chips(Array(days.prefix(4)))
                chips(Array(days.dropFirst(4)))
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func chips(_ days: [(id: Int, short: String, long: String)]) -> some View {
        HStack(spacing: PumTokens.Space.s4) {
            ForEach(days, id: \.id) { day in
                let on = state.isWeekdaySelected(day.id)
                Button { state.toggleWeekday(day.id) } label: {
                    Text(day.short).pumText(.caption, weight: on ? .bold : .semibold)
                        .foregroundStyle(on ? Color.white : PumColor.textPrimary)
                        .frame(width: chipSize, height: chipSize)
                        .background(on ? PumColor.surfaceInverse : PumColor.surfaceFill, in: Circle())
                        // 누름 영역: 세로 44pt(배치는 칩 높이만), 가로는 칩 + 간격(이웃과 겹치지 않게)
                        .frame(minWidth: chipSize + PumTokens.Space.s4, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                        .padding(.vertical, -max(0, PumTokens.Size.tapMin - chipSize) / 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -PumTokens.Space.s2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day.long))
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    // MARK: 결과 카드

    private var resultCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: PumTokens.Space.s4) { // 원문 배지 왼쪽 4
                    Text(LaborSimulatorState.resultHeading).pumText(.footnote, weight: .medium)
                        .foregroundStyle(PumColor.textSecondary)
                    estimatePill
                    Spacer(minLength: 0)
                }
                // 머리 · 큰 숫자를 한 번에 읽는다(「예상 추가 인건비 약 504,000원」)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.resultSpoken))
                if let result = state.visibleResult {
                    Text(LaborSimulatorState.totalText(result.expectedWon))
                        .pumText(.hero).foregroundStyle(PumColor.textPrimary)
                        .minimumScaleFactor(0.6).lineLimit(2)
                        .padding(.top, PumTokens.Space.s4) // 원문 금액 위 4
                        .accessibilityHidden(true)
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.top, PumTokens.Space.s12) // 원문 내역 위 12 · 선 위 12
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 줄 사이 6
                        ForEach(Array(result.lines.enumerated()), id: \.offset) { _, line in
                            lineRow(line)
                        }
                    }
                    .padding(.top, PumTokens.Space.s12)
                }
            }
            .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 16 18
            .padding(.vertical, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 「예상」 회색 알약 — 공통 C2 배지는 읽을 때 「상태:」가 붙어 화면 전용(공통 후보)
    private var estimatePill: some View {
        Text(LaborSimulatorState.estimateBadge).pumText(.caption2, weight: .bold)
            .foregroundStyle(PumTokens.ColorToken.gray700) // 원문 #5B6170
            .padding(.vertical, PumTokens.Space.s2)
            .padding(.horizontal, PumTokens.Space.s6)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous))
    }

    /// 왼쪽 서버 문구(회색) · 오른쪽 서버 금액(굵게). 좁으면 세로
    private func lineRow(_ line: LaborSimulatorResult.Line) -> some View {
        let key = Text(line.title).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        let value = Text(LaborSimulatorState.amountText(line.amountWon)).pumText(.footnote, weight: .bold)
            .foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                key.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                value.fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { key; value }
        }
    }
}

#Preview("8d 원문") { LaborSimulatorView(state: .sample) }
