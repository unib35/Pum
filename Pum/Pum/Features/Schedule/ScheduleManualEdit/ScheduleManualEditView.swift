// UI-IOS-9d · REQ-051 — 사장님 · 직접 조정(하위 화면, 탭 바 없음). 시간을 늘리면 즉시 재계산 · 계산 내역.
// 색: 파랑 = 근무 막대 · 바뀐 사람 카드 외곽 · 다음 동작, 먹색 = 선택(요일). 금액 · 내역은 엔진 값 그대로.
// 막대를 끌어 늘리는 동작은 원문에 없다(screen-index 「추정」) — 만들지 않고, 직원 행을 누르면 C13 시트로 시간을 바꾼다.
import SwiftUI

struct ScheduleManualEditView: View {
    @State private var state: ScheduleManualEditState
    @State private var pickerEmployee: Int?
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var onBack: () -> Void
    var onSelectDay: (Int) -> Void
    /// 직원의 근무를 바꿨다 — 부모(엔진)가 재계산해 `latestResult`로 돌려준다
    var onShiftChanged: (Int, ClosedRange<Int>) -> Void
    var onRevert: () -> Void
    /// 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 done(false). 반영은 직원 요청(수락) 경로
    var onApply: (@escaping (Bool) -> Void) -> Void
    /// 엔진의 최신 결과(계산 조건 basis 포함)
    var latestResult: ScheduleManualEditResult?
    /// 부모(서버)가 준 최신 날 · 근무. 바뀌면 화면 상태를 바꾼다(요일을 옮겼을 때 등)
    var serverState: ScheduleManualEditState?

    // 화면 전용 상수 (DEC-005)
    /// 요일 칸 높이 — 원문 약 49 (9a와 같은 값)
    @ScaledMetric(relativeTo: .body) private var dayCellHeight: CGFloat = 49
    /// 막대 트랙 높이 — 원문 약 16
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 16
    /// 직원 이름 칸 폭 — 원문 약 84
    @ScaledMetric(relativeTo: .body) private var nameColumn: CGFloat = 84
    /// 타임라인 작은 아바타 — 원문 약 24
    @ScaledMetric(relativeTo: .body) private var smallAvatar: CGFloat = 24
    /// 바뀐 사람 카드 아바타 — 원문 약 28
    @ScaledMetric(relativeTo: .body) private var cardAvatar: CGFloat = 28
    /// 시간 눈금 줄 높이
    @ScaledMetric(relativeTo: .caption2) private var tickHeight: CGFloat = 14

    init(state: ScheduleManualEditState = .sample,
         latestResult: ScheduleManualEditResult? = nil,
         serverState: ScheduleManualEditState? = nil,
         onBack: @escaping () -> Void = {},
         onSelectDay: @escaping (Int) -> Void = { _ in },
         onShiftChanged: @escaping (Int, ClosedRange<Int>) -> Void = { _, _ in },
         onRevert: @escaping () -> Void = {},
         onApply: @escaping (@escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        _state = State(initialValue: state)
        self.latestResult = latestResult
        self.serverState = serverState
        self.onBack = onBack
        self.onSelectDay = onSelectDay
        self.onShiftChanged = onShiftChanged
        self.onRevert = onRevert
        self.onApply = onApply
    }

    private var isLarge: Bool { typeSize >= .xxLarge }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    dayStrip
                    timelineCard
                    if let title = state.cardTitle { changedCard(title) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: latestResult) { _, new in if let new { state.result = new } }
        .onChange(of: serverState) { _, new in
            guard let new else { return }
            state.days = new.days
            state.selectedDay = new.selectedDay
            state.shifts = new.shifts
            state.needs = new.needs
        }
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            guard let id = pickerEmployee else { return }
            let a = pickerValue.startMinutes, b = pickerValue.endMinutes
            // 끝이 시작보다 늦을 때만(자정 넘김은 원문 근거 없음)
            if state.setRange(employeeId: id, start: a, end: b) { onShiftChanged(id, a ... b) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { buttons }
    }

    /// 시간 범위만 켠다(날짜 · 휴게 · 반복 · 종료일 없음), 30분 간격
    private var pickerOptions: PumTimeRangeOptions {
        let name = state.shifts.first { $0.employeeId == pickerEmployee }?.name ?? "근무"
        return PumTimeRangeOptions(title: "\(name) 근무 시간", showsDate: false, showsBreak: false, showsRepeat: false, showsEndDate: false)
    }

    private func openPicker(_ shift: ManualEditShift) {
        pickerEmployee = shift.employeeId
        pickerValue = PumTimeRangeValue(startMinutes: shift.startMinutes, endMinutes: shift.endMinutes)
        pickerOpen = true
    }

    // MARK: 요일 스트립 — 공통 후보(9a와 같은 값)

    private var dayStrip: some View {
        HStack(spacing: 0) {
            ForEach(state.days) { day in
                let on = day.id == state.selectedDay
                Button {
                    if reduceMotion { state.select(day: day.id) }
                    else { withAnimation(PumMotion.fast) { state.select(day: day.id) } }
                    onSelectDay(day.id)
                } label: {
                    VStack(spacing: PumTokens.Space.s2) {
                        Text(day.short).pumText(.caption2, weight: .regular)
                            .foregroundStyle(on ? PumColor.textOnInverseSecondary : PumColor.textSecondary)
                        Text("\(day.date)").pumText(.body, weight: on ? .bold : .semibold)
                            .foregroundStyle(on ? Color.white : PumColor.textPrimary)
                    }
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, minHeight: max(dayCellHeight, PumTokens.Size.tapMin))
                    .background {
                        if on {
                            RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous).fill(PumColor.surfaceInverse)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day.spoken))
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    // MARK: 타임라인 카드

    private var timelineCard: some View {
        PumCard {
            VStack(spacing: 0) {
                tickRow
                ForEach(state.shifts) { shift in
                    divider
                    shiftRow(shift)
                }
                divider
                needsRow
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    /// 시간 눈금 — 막대와 같은 9–23시 비율 위치. 큰 글자에서도 줄이 한 줄 높이를 지킨다
    private var tickRow: some View {
        HStack(spacing: 0) {
            if !isLarge { Color.clear.frame(width: nameColumn + PumTokens.Space.s8, height: 1) }
            GeometryReader { geo in
                ForEach(ScheduleManualEditState.timeTicks, id: \.self) { h in
                    Text("\(h)").pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary)
                        .lineLimit(1).fixedSize()
                        .position(x: min(max(ScheduleManualEditState.tickFraction(hour: h) * geo.size.width, 8), geo.size.width - 8),
                                  y: geo.size.height / 2)
                }
            }
            .frame(height: tickHeight)
        }
        .padding(.bottom, PumTokens.Space.s8)
        .accessibilityHidden(true)
    }

    private func shiftRow(_ shift: ManualEditShift) -> some View {
        let name = HStack(spacing: PumTokens.Space.s8) {
            PumAvatar(name: shift.name, colorIndex: shift.colorIndex, size: smallAvatar)
            Text(shift.name).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.leading)
        }
        return Button { openPicker(shift) } label: {
            Group {
                if isLarge {
                    // 큰 글자 — 이름 칸을 위로 빼서 막대 폭을 넓힌다
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) { name; track(shift) }
                } else {
                    HStack(spacing: PumTokens.Space.s8) {
                        name.frame(width: nameColumn, alignment: .leading)
                        track(shift)
                    }
                }
            }
            .padding(.vertical, PumTokens.Space.s10)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(shift.spoken))
        .accessibilityHint(Text("누르면 근무 시간을 바꿔요"))
        .accessibilityAddTraits(.isButton)
    }

    /// 연회색 트랙 위 파랑 막대. 늘어난 구간은 연파랑 + 파랑 테두리. 9–23시 범위로 잘라 그린다(그리기용 계산)
    private func track(_ shift: ManualEditShift) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous).fill(PumColor.surfaceFill)
                // 원래 근무와 겹치는 구간은 진한 파랑
                let solidStart = max(shift.startMinutes, shift.originalStart)
                let solidEnd = min(shift.endMinutes, shift.originalEnd)
                if let f = ScheduleManualEditState.barFraction(start: solidStart, end: solidEnd) {
                    bar(f, width: w, filled: true)
                }
                // 편집 전에 없던 구간(원문의 19–22)
                ForEach(shift.addedRanges, id: \.lowerBound) { r in
                    if let f = ScheduleManualEditState.barFraction(start: r.lowerBound, end: r.upperBound) {
                        bar(f, width: w, filled: false)
                    }
                }
            }
        }
        .frame(height: trackHeight)
        .animation(reduceMotion ? nil : PumMotion.fast, value: shift.value)
    }

    private func bar(_ f: ClosedRange<Double>, width: CGFloat, filled: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous)
        return shape
            .fill(filled ? PumColor.accent : PumTokens.ColorToken.blue300)
            .overlay { if !filled { shape.stroke(PumColor.accent, lineWidth: PumTokens.Shadow.hairline.spread) } }
            .frame(width: max((f.upperBound - f.lowerBound) * width, 0))
            .offset(x: f.lowerBound * width)
    }

    /// 아래 줄 — 서버 문자열 그대로. 한 줄에 안 들어가면 세로로
    private var needsRow: some View {
        let label = Text(ScheduleManualEditState.needLabel).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let items = state.displayedNeeds
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                label
                ForEach(Array(items.enumerated()), id: \.offset) { _, t in
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(t).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
            }
            .lineLimit(1)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                label
                ForEach(Array(items.enumerated()), id: \.offset) { _, t in
                    Text(t).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
            }
        }
        .padding(.top, PumTokens.Space.s10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(ScheduleManualEditState.needLabel), " + items.joined(separator: ", ")))
    }

    // MARK: 바뀐 사람 카드 (파랑 두꺼운 테두리)

    private func changedCard(_ title: String) -> some View {
        let r = PumTokens.Radius.lg
        let name = state.changedShift?.name ?? ""
        let index = state.changedShift?.colorIndex ?? 0
        return PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    PumAvatar(name: name, colorIndex: index, size: cardAvatar)
                    // 이름 줄 + 시간 범위: 한 줄에 안 들어가면 시간이 아래로
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { titleText(title); rangeText }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) { titleText(title); rangeText }
                    }
                }
                if let res = state.visibleResult {
                    amountRow(res)
                    divider
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                        ForEach(Array(res.lines.enumerated()), id: \.offset) { _, line in lineRow(line) }
                    }
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .inset(by: -PumTokens.Shadow.outline.spread / 2)
                .stroke(PumColor.accent, lineWidth: PumTokens.Shadow.outline.spread)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.visibleResult.map { "\(title), \($0.rangeText), \($0.spoken)" } ?? title))
    }

    private func titleText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    @ViewBuilder private var rangeText: some View {
        if let res = state.visibleResult {
            Text(res.rangeText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }

    /// 취소선 이전 값 · 큰 새 값 · 증감 — 모두 서버 값. 한 줄에 안 들어가면 세로
    private func amountRow(_ res: ScheduleManualEditResult) -> some View {
        let before = Text(res.beforeText).pumText(.footnote, weight: .regular).strikethrough()
            .foregroundStyle(PumColor.textTertiary)
        let after = Text(res.afterText).pumText(.title2).foregroundStyle(PumColor.textPrimary)
        let delta = Text(res.deltaText).pumText(.footnote, weight: .bold).foregroundStyle(PumTokens.ColorToken.gray700)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { before; after; delta }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { before; after; delta }
        }
    }

    /// 왼쪽 회색 설명 · 오른쪽 굵은 값. 큰 글자에서는 세로
    @ViewBuilder private func lineRow(_ line: ScheduleManualEditResult.Line) -> some View {
        let left = Text(line.title).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let right = Text(line.valueText).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        if isLarge {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { left; right }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                left.frame(maxWidth: .infinity, alignment: .leading)
                right.fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    // MARK: 하단 버튼

    private var buttons: some View {
        Group {
            if isLarge {
                VStack(spacing: PumTokens.Space.s8) { applyButton; revertButton }
            } else {
                // 되돌리기 : 적용 = 1 : 1.5 (C1 PAIR와 같은 비율)
                GeometryReader { geo in
                    let gap = PumTokens.Space.s8
                    let unit = (geo.size.width - gap) / 2.5
                    HStack(spacing: gap) {
                        revertButton.frame(width: unit)
                        applyButton.frame(width: unit * 1.5)
                    }
                }
                .frame(height: PumTokens.Size.buttonH)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    private var revertButton: some View {
        PumButton(title: ScheduleManualEditState.revertTitle, kind: .outline, action: revert).disabled(!state.canRevert)
    }

    private var applyButton: some View {
        PumButton(title: state.applyTitle, kind: .primary, isLoading: state.isApplying, action: apply).disabled(!state.canApply)
    }

    private func revert() {
        guard state.canRevert, state.revert() else { return }
        onRevert()
    }

    private func apply() {
        guard state.beginApply() else { return }
        // 실패일 때만 풀린다. 성공이면 호출한 쪽이 이 화면을 닫는다(두 번 보내지 않기)
        onApply { ok in if !ok { state.endApply() } }
    }
}

#Preview("9d 원문") { ScheduleManualEditView(state: .sample) }
#Preview("9d · 큰 글자") { ScheduleManualEditView(state: .sample).dynamicTypeSize(.accessibility3) }
