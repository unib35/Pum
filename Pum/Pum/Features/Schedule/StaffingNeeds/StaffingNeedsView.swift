// UI-IOS-9a · REQ-051 — 사장님 · 필요 인력 입력(하위 화면, 탭 바 없음). 시간대별로 몇 명.
// 색: 주황 = 처리 필요(경고 카드 외곽), 파랑 = 다음 동작, 먹색 = 선택(요일). 칩은 읽기 전용.
// 시간대 행을 눌러 시간을 고치는 동작은 원문 근거가 없어 두지 않았다(추가만 C13).
import SwiftUI

struct StaffingNeedsView: View {
    @State private var state: StaffingNeedsState
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onClose: () -> Void
    /// C13에서 고른 새 시간대(요일 id · 시작~끝 분) — 겹침 확인은 서버. 화면은 목록에 넣지 않고 부모가 `serverSlots`로 돌려준다
    var onAddSlot: (Int, ClosedRange<Int>) -> Void
    var onNeedsChanged: ([StaffingSlot]) -> Void
    var onRequestAvailability: () -> Void
    /// 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 done(false)
    var onRecommend: ([StaffingSlot], @escaping (Bool) -> Void) -> Void
    /// 부모(서버)가 준 최신 시간대 목록. 바뀌면 화면 목록을 바꾼다
    var serverSlots: [StaffingSlot]?

    // 화면 전용 상수 (DEC-005)
    /// 요일 칸 높이 — 원문 약 49
    @ScaledMetric(relativeTo: .body) private var dayCellHeight: CGFloat = 49
    /// 스테퍼 알약 최소 높이 — 원문 약 34
    @ScaledMetric(relativeTo: .body) private var stepperHeight: CGFloat = 34
    /// 스테퍼 인원 글자 칸 최소 폭 — 원문 36
    @ScaledMetric(relativeTo: .body) private var countMinWidth: CGFloat = 36

    init(state: StaffingNeedsState = .sample,
         serverSlots: [StaffingSlot]? = nil,
         onClose: @escaping () -> Void = {},
         onAddSlot: @escaping (Int, ClosedRange<Int>) -> Void = { _, _ in },
         onNeedsChanged: @escaping ([StaffingSlot]) -> Void = { _ in },
         onRequestAvailability: @escaping () -> Void = {},
         onRecommend: @escaping ([StaffingSlot], @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.serverSlots = serverSlots
        self.onClose = onClose
        self.onAddSlot = onAddSlot
        self.onNeedsChanged = onNeedsChanged
        self.onRequestAvailability = onRequestAvailability
        self.onRecommend = onRecommend
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    weekRow
                    // 추천을 요청하는 동안은 보낸 값과 화면이 어긋나지 않게 잠근다
                    dayStrip.disabled(state.isRecommending)
                    section(state.sectionTitle) { slotCard }.disabled(state.isRecommending)
                    section(StaffingNeedsState.conditionsHeading) { conditionChips }
                    if let title = state.missingTitle { missingCard(title) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: serverSlots) { _, new in if let new { state.slots = new } }
        .onAppear { if state.isRecommending { state.endRecommend() } } // 9b에서 돌아오면 다시 누를 수 있게
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            let a = pickerValue.startMinutes, b = pickerValue.endMinutes
            guard a < b else { return } // 끝이 시작보다 늦을 때만 넘긴다(자정 넘김은 원문 근거 없음)
            onAddSlot(state.selectedDay, a ... b)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: StaffingNeedsState.recommendTitle, kind: .primary,
                      isLoading: state.isRecommending, action: recommend)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12) // 원문 위 12 · 아래 44 − 안전 영역 34 = 10
                .padding(.bottom, PumTokens.Space.s10)
                .background(PumColor.bgApp)
        }
    }

    /// 구역 제목 + 내용 — 원문: 제목 위 2 · 제목~내용 6(블록 12 − 6)
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title).padding(.top, PumTokens.Space.s2)
            content()
        }
    }

    /// 시간 범위만 켠다(날짜 · 휴게 · 반복 · 종료일 없음), 30분 간격
    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(title: "시간대 추가", showsDate: false, showsBreak: false, showsRepeat: false, showsEndDate: false)
    }

    private func openPicker() {
        pickerValue = PumTimeRangeValue(startMinutes: 11 * 60, endMinutes: 14 * 60)
        pickerOpen = true
    }

    private func recommend() {
        guard state.beginRecommend() else { return }
        // 실패일 때만 풀린다. 성공이면 호출한 쪽이 9b로 넘김(두 번 보내지 않기)
        onRecommend(state.slots) { ok in if !ok { state.endRecommend() } }
    }

    private func step(_ slot: StaffingSlot, by delta: Int) {
        if state.step(slot: slot.id, by: delta) { onNeedsChanged(state.slots) }
    }

    // MARK: 헤더

    private var header: some View {
        ZStack {
            Text(StaffingNeedsState.title).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    // MARK: 주 · 요일 스트립

    private var weekRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(state.weekText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            // 「다음 주」는 원문에서 회색 글자 — 누름 동작은 원문 근거가 없어 표시만
            Text(StaffingNeedsState.nextWeekTitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    /// 7칸 고정(큰 글자에서도 가로 스크롤 없이 글자만 커지고, 모자라면 조금 줄어든다)
    private var dayStrip: some View {
        HStack(spacing: 0) {
            ForEach(state.days) { day in
                let on = day.id == state.selectedDay
                Button {
                    if reduceMotion { state.select(day: day.id) }
                    else { withAnimation(PumMotion.fast) { state.select(day: day.id) } }
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
                            RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).fill(PumColor.surfaceInverse) // 원문 12
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

    // MARK: 시간대 카드

    private var slotCard: some View {
        PumCard {
            ForEach(state.selectedSlots) { slot in
                slotRow(slot)
                divider
            }
            Button(action: openPicker) {
                Text(StaffingNeedsState.addSlotTitle).pumText(.callout).foregroundStyle(PumColor.accent)
                    .padding(.vertical, PumTokens.Size.rowPadY)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// hairline은 카드 끝까지(원문)
    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    /// 시간대 왼쪽 · 스테퍼 오른쪽. 큰 글자에서 한 줄에 안 들어가면 스테퍼가 아래로 내려간다
    private func slotRow(_ slot: StaffingSlot) -> some View {
        let time = Text(slot.rangeText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { time.fixedSize(); Spacer(minLength: 0); stepper(slot) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { time; stepper(slot) }
        }
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 padding 12 16
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        // 시간대 + 인원을 한 번에 읽고, 위아래로 쓸어 조정한다
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(slot.spokenRange))
        .accessibilityValue(Text("\(slot.count)명"))
        // 음성 제어 · 스위치 제어용 이름 있는 동작(조정 동작과 같은 규칙)
        .accessibilityAction(named: Text("한 명 늘리기")) { step(slot, by: 1) }
        .accessibilityAction(named: Text("한 명 줄이기")) { step(slot, by: -1) }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(slot, by: 1)
            case .decrement: step(slot, by: -1)
            @unknown default: break
            }
        }
    }

    // MARK: 스테퍼 — 공통 후보(스테퍼가 공통에 없어 화면 전용)

    private func stepper(_ slot: StaffingSlot) -> some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: state.canDecrement(slot)) { step(slot, by: -1) }
            Text("\(slot.count)명").pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).fixedSize()
                .frame(minWidth: countMinWidth)
            stepButton("plus", enabled: state.canIncrement(slot)) { step(slot, by: 1) }
        }
        .frame(minHeight: stepperHeight)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
    }

    /// 누름 영역은 가로 · 세로 44pt — 알약 높이는 그대로 두고 세로 여백만 바깥으로 낸다
    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: PumLayout.navIcon, weight: .regular))
                .foregroundStyle(enabled ? PumTokens.ColorToken.gray700 : PumColor.textDisabled)
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                .padding(.horizontal, -(PumTokens.Size.tapMin - stepperHeight) / 2) // 배치는 원문 34 × 34
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .frame(height: stepperHeight)
    }

    // MARK: 조건 칩 — 읽기 전용 · 줄바꿈 흐름 배치(공통 후보)

    private var conditionChips: some View {
        PumFlowLayout(spacing: PumTokens.Space.s6) { // 원문 칩 사이 6
            ForEach(Array(state.conditions.enumerated()), id: \.offset) { _, text in
                Text(text).pumText(.caption, weight: .semibold)
                    .foregroundStyle(PumTokens.ColorToken.gray700)
                    .padding(.horizontal, PumTokens.Space.s8) // 원문 padding 5 9 → 가까운 4 8
                    .padding(.vertical, PumTokens.Space.s4)
                    .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 경고 카드

    private func missingCard(_ title: String) -> some View {
        let text = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout).foregroundStyle(PumColor.textPrimary)
            if let sub = state.missingSubtitle {
                Text(sub).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        let request = Button(action: onRequestAvailability) {
            Text("\(StaffingNeedsState.requestTitle) \u{203A}").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.accent)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("근무 가능 시간 요청"))
        return PumCard(attention: true) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s10) { text.frame(maxWidth: .infinity, alignment: .leading); request } // 원문 칸 사이 10
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { text; request }
            }
            .padding(.vertical, PumTokens.Space.s12) // 원문 padding 12 16
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 줄바꿈 흐름 배치 — 공통 후보(공통에 없어 화면 전용)

private struct PumFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = arrange(width: proposal.width ?? .infinity, subviews: subviews).size
        // 받은 폭을 그대로 쓴다 — 더 좁게 돌려주면 배치 때 줄이 더 꺾여 마지막 줄이 잘릴 수 있다(9c에서 확인)
        if let w = proposal.width, w.isFinite { return CGSize(width: w, height: size.height) }
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, f) in result.frames.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + f.minX, y: bounds.minY + f.minY), proposal: ProposedViewSize(f.size))
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for sub in subviews {
            var sz = sub.sizeThatFits(.unspecified)
            sz.width = min(sz.width, width) // 한 칩이 한 줄보다 길면 줄여서 넘침을 막는다
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowH), frames)
    }
}

#Preview("9a 원문") { StaffingNeedsView(state: .sample) }
#Preview("9a · 큰 글자") { StaffingNeedsView(state: .sample).dynamicTypeSize(.accessibility3) }
