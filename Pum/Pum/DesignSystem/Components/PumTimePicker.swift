// C13 Date · Time Picker — 시간 선택 휠 바텀시트(2j 스케줄 · 1af 추가 근무 · 1al 계약 · 2e 근무 조건 · 공지 공통)
// 구성: PumTimeWheel(세로 휠 하나) → PumTimeRangeSheetContent(시트 내용) → pumTimeRangeSheet(수식어, pumBottomSheet 위).
// 길이 「5시간」은 화면에 보이는 분 차이일 뿐 급여 계산이 아니다(급여는 엔진 한 곳).
// 날짜 · 종료일은 달력 디자인이 없어 값 칩만 그리고 눌림은 클로저로 넘긴다.
// 사용: view.pumTimeRangeSheet(isPresented: $open, value: $range, options: PumTimeRangeOptions(), onDone: { … })
import SwiftUI

// MARK: - 순수 계산 (테스트 대상)

/// 휠 값 · 문구 계산. 시각은 「하루 중 분」(0 ..< 1440, Asia/Seoul 벽시계 기준)으로만 다룬다.
nonisolated enum PumTimeWheelMath {
    static let minutesPerDay = 24 * 60

    /// 휠에 놓이는 값 목록: 0, 간격, 2*간격 … 하루 끝 전까지(24:00은 없다). 간격 0 이하는 1로 본다.
    static func values(interval: Int) -> [Int] {
        Array(stride(from: 0, to: minutesPerDay, by: max(1, interval)))
    }

    /// 임의의 분을 가장 가까운 휠 값으로. 하루 밖이면 첫/끝 값으로 붙인다.
    static func snapped(_ minutes: Int, interval: Int) -> Int {
        let step = max(1, interval)
        let last = (minutesPerDay - 1) / step * step
        let clamped = min(max(minutes, 0), minutesPerDay - 1)
        let rounded = (clamped + step / 2) / step * step
        return min(rounded, last)
    }

    /// 휠을 `steps`칸 옮긴 값(VoiceOver 위아래 쓸기). 끝에서는 더 가지 않는다.
    static func stepped(_ minutes: Int, by steps: Int, interval: Int) -> Int {
        let step = max(1, interval)
        return snapped(snapped(minutes, interval: step) + steps * step, interval: step)
    }

    /// 540 → "09:00" (원문은 24시간제)
    static func clockText(_ minutes: Int) -> String {
        let m = min(max(minutes, 0), minutesPerDay - 1)
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    /// 1020 → "오후 5시", 1050 → "오후 5시 30분" (VoiceOver)
    static func spokenText(_ minutes: Int) -> String {
        let m = min(max(minutes, 0), minutesPerDay - 1)
        let hour = m / 60, minute = m % 60
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let prefix = hour < 12 ? "오전" : "오후"
        return minute == 0 ? "\(prefix) \(h12)시" : "\(prefix) \(h12)시 \(minute)분"
    }

    /// 표시용 분 차이. 끝이 시작보다 이르면 다음 날로 넘어간 것(+24시간). 같으면 0.
    static func displayMinutes(start: Int, end: Int) -> Int {
        end >= start ? end - start : end + minutesPerDay - start
    }

    /// 300 → "5시간", 330 → "5시간 30분", 30 → "30분"
    static func durationText(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)분" }
        return m == 0 ? "\(h)시간" : "\(h)시간 \(m)분"
    }

    /// 「17:00 → 22:00」
    static func rangeText(start: Int, end: Int) -> String {
        "\(clockText(start)) → \(clockText(end))"
    }

    /// 「17:00 → 22:00 · 5시간」
    static func summary(start: Int, end: Int) -> String {
        "\(rangeText(start: start, end: end)) · \(durationText(minutes: displayMinutes(start: start, end: end)))"
    }
}

// MARK: - 값 · 옵션

/// 시트가 고치는 값. 날짜 · 종료일은 글자만 가진다(달력은 후속). 요일 id는 2e와 같게 월 1 … 일 7.
struct PumTimeRangeValue: Equatable {
    var startMinutes = 17 * 60
    var endMinutes = 22 * 60
    /// 휴게 분 — 0(없음) · 30 · 60
    var breakMinutes = 30
    var weekdays: Set<Int> = [1, 3, 5]
    var dateText = "10월 5일 (월)"
    var endDateText = "없음"
}

/// 화면마다 필요한 것만 켠다.
struct PumTimeRangeOptions {
    enum Mode { case range, startOnly, endOnly }

    var title = "근무 시간"
    var mode: Mode = .range
    /// 시간 행 이름(원문 「근무시간」). 한 시각만 고르는 모드에서는 이 이름 옆에 고른 시각이 보인다.
    var rangeLabel = "근무시간"
    var showsDate = true
    var showsBreak = true
    var showsRepeat = true
    var showsEndDate = true
    var intervalMinutes = 30
    var doneTitle = "완료"
    var onDateTap: (() -> Void)?
    var onEndDateTap: (() -> Void)?
}

enum PumTimePickerStyle {
    /// 휠 한 칸 높이 — 원문 실측 약 30(띠 31 · 상자 약 92)이라 토큰 밖 크기(DEC-005). 큰 글자에서 글자와 함께 커진다
    static let rowHeight: CGFloat = 31
    /// 휠 상자에 보이는 칸 수(위 · 가운데 · 아래)
    static let visibleRows = 3
    /// 흰 띠의 좌우 안쪽 여백(원문 약 6)
    static let bandInset: CGFloat = 6
    /// 휠 하나의 최소 폭 — 두 휠이 가로로 놓이려면 이만큼씩 필요하고, 모자라면 위아래로 쌓는다
    static let wheelMinWidth: CGFloat = 120
    /// 요일 칩 지름(원문 30, 2e와 같은 값)
    static let weekdayChip: CGFloat = 30
    static let weekdays: [(id: Int, short: String, long: String)] = [
        (1, "월", "월요일"), (2, "화", "화요일"), (3, "수", "수요일"), (4, "목", "목요일"),
        (5, "금", "금요일"), (6, "토", "토요일"), (7, "일", "일요일"),
    ]
    static let breakChoices: [(minutes: Int, title: String)] = [(0, "없음"), (30, "30분"), (60, "1시간")]
}

// MARK: - 휠 하나

/// 세로 시간 휠. 회색 상자 · 가운데 흰 띠 · 위아래 연회색. 스크롤하면 가운데로 스냅하고 값이 바뀔 때마다 햅틱(M21 selection).
/// `PumTimeWheel(title: "시작", minutes: $m)` — 값은 하루 중 분.
struct PumTimeWheel: View {
    let title: String
    @Binding var minutes: Int
    var intervalMinutes = 30

    @State private var scrollID: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var rowHeight = PumTimePickerStyle.rowHeight

    init(title: String, minutes: Binding<Int>, intervalMinutes: Int = 30) {
        self.title = title
        _minutes = minutes
        self.intervalMinutes = intervalMinutes
        _scrollID = State(initialValue: PumTimeWheelMath.snapped(minutes.wrappedValue, interval: intervalMinutes))
    }

    private var current: Int { PumTimeWheelMath.snapped(minutes, interval: intervalMinutes) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                .fill(PumColor.surfaceFill) // 시트 바탕(bgApp) 위에서 보이게 — 원문은 흰 시트 위 연회색 상자
            // 가운데 흰 띠
            RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                .fill(PumColor.surfaceCard)
                .frame(height: rowHeight)
                .padding(.horizontal, PumTimePickerStyle.bandInset)
                .accessibilityHidden(true)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(PumTimeWheelMath.values(interval: intervalMinutes), id: \.self) { m in
                        let selected = m == current
                        Text(PumTimeWheelMath.clockText(m))
                            .pumText(selected ? .title3 : .body, weight: selected ? .bold : .medium) // 20px 700 / 15px 500
                            .monospacedDigit()
                            .foregroundStyle(selected ? PumColor.textPrimary : PumTokens.ColorToken.gray400)
                            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { select(m) }
                            .id(m)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.vertical, rowHeight, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            // viewAligned는 위 여백 경계에 칸을 맞춘다 — 여백이 한 칸이라 그 칸이 곧 가운데 띠(anchor를 주면 한 칸 밀림)
            .scrollPosition(id: $scrollID)
        }
        .frame(height: rowHeight * CGFloat(PumTimePickerStyle.visibleRows))
        .frame(minWidth: PumTimePickerStyle.wheelMinWidth)
        .onChange(of: scrollID) { _, new in
            if let new, new != minutes { minutes = new }
        }
        .onChange(of: minutes) { _, new in
            let target = PumTimeWheelMath.snapped(new, interval: intervalMinutes)
            guard scrollID != target else { return }
            // M22: 동작 줄이기면 움직임 없이 바로
            if reduceMotion { scrollID = target } else { withAnimation(PumMotion.fast) { scrollID = target } }
        }
        .sensoryFeedback(.selection, trigger: current) // M21 selection = 휠
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(PumTimeWheelMath.spokenText(current)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: minutes = PumTimeWheelMath.stepped(current, by: 1, interval: intervalMinutes)
            case .decrement: minutes = PumTimeWheelMath.stepped(current, by: -1, interval: intervalMinutes)
            @unknown default: break
            }
        }
    }

    private func select(_ m: Int) {
        guard m != current else { return }
        minutes = m
    }
}

// MARK: - 시트 내용

/// 원문 시트 내용. 켜고 끄는 행은 `options`. 값은 바로 `value`에 쓰이고, 「완료」는 `onDone`만 부른다.
struct PumTimeRangeSheetContent: View {
    @Binding var value: PumTimeRangeValue
    var options = PumTimeRangeOptions()
    var onDone: () -> Void = {}

    @ScaledMetric(relativeTo: .caption) private var chipSize = PumTimePickerStyle.weekdayChip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(options.title)
                .pumText(.headline, weight: .bold) // 원문 18px 700 — 가장 가까운 단계(17)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, PumTokens.Space.s8)
            if options.showsDate { dateRow; divider }
            timeSection
            if options.showsBreak { divider; breakRow }
            if options.showsRepeat { divider; repeatRow }
            if options.showsEndDate { divider; endDateRow }
            PumButton(title: options.doneTitle, kind: .primary, action: onDone)
                .padding(.top, PumTokens.Space.s16)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 행

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    private func label(_ text: String) -> some View {
        Text(text).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px 400
    }

    /// 이름 왼쪽 · 내용 오른쪽. 큰 글자에서 한 줄에 안 들어가면 이름 아래로 내려 줄바꿈한다.
    private func labeledRow<Items: View>(_ name: String, @ViewBuilder items: () -> Items) -> some View {
        let content = items()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                label(name)
                Spacer(minLength: PumTokens.Space.s8)
                PumTimeWrapLayout(spacing: PumTokens.Space.s4) { content }
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                label(name)
                PumTimeWrapLayout(spacing: PumTokens.Space.s4) { content }
            }
        }
        .padding(.vertical, PumTokens.Space.s8)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    private var dateRow: some View {
        labeledRow("날짜") {
            valueChip(value.dateText, action: options.onDateTap)
        }
    }

    private var endDateRow: some View {
        Button { options.onEndDateTap?() } label: {
            ViewThatFits(in: .horizontal) {
                HStack {
                    label("종료일")
                    Spacer(minLength: PumTokens.Space.s8)
                    endDateValue
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    label("종료일")
                    endDateValue
                }
            }
            .padding(.vertical, PumTokens.Space.s8)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(options.onEndDateTap == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("종료일"))
        .accessibilityValue(Text(value.endDateText))
        .accessibilityAddTraits(.isButton)
    }

    private var endDateValue: some View {
        Text(value.endDateText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 14px 600
    }

    /// 날짜 칩 — 회색 채움 둥근 칩. 누르면 클로저(달력은 후속). 44 터치는 위아래로 넓힌다.
    private func valueChip(_ text: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Text(text).pumText(.callout, weight: .semibold) // 14px 600
                .foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s10)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel(Text("날짜"))
        .accessibilityValue(Text(text))
    }

    // MARK: 시간

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    label(options.rangeLabel)
                    Spacer(minLength: PumTokens.Space.s8)
                    summary
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    label(options.rangeLabel)
                    summary
                }
            }
            .padding(.top, PumTokens.Space.s8)
            wheels
                .padding(.bottom, PumTokens.Space.s12)
        }
    }

    /// 「17:00 → 22:00」 먹색 굵게 + 「· 5시간」 회색 보통 — 한 문구로 읽힌다
    private var summary: some View {
        let main: String
        let tail: String
        switch options.mode {
        case .range:
            main = PumTimeWheelMath.rangeText(start: value.startMinutes, end: value.endMinutes)
            tail = " · " + PumTimeWheelMath.durationText(minutes: PumTimeWheelMath.displayMinutes(start: value.startMinutes, end: value.endMinutes))
        case .startOnly:
            main = PumTimeWheelMath.clockText(value.startMinutes)
            tail = ""
        case .endOnly:
            main = PumTimeWheelMath.clockText(value.endMinutes)
            tail = ""
        }
        let mainText = Text(main).pumTextStyle(.body, weight: .bold, color: PumColor.textPrimary)
        let tailText = Text(tail).pumTextStyle(.callout, weight: .regular, color: PumColor.textSecondary)
        return Text("\(mainText)\(tailText)")
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(spokenSummary))
    }

    private var spokenSummary: String {
        switch options.mode {
        case .range:
            "\(PumTimeWheelMath.spokenText(value.startMinutes))부터 \(PumTimeWheelMath.spokenText(value.endMinutes))까지, \(PumTimeWheelMath.durationText(minutes: PumTimeWheelMath.displayMinutes(start: value.startMinutes, end: value.endMinutes)))"
        case .startOnly: PumTimeWheelMath.spokenText(value.startMinutes)
        case .endOnly: PumTimeWheelMath.spokenText(value.endMinutes)
        }
    }

    @ViewBuilder private var wheels: some View {
        let step = options.intervalMinutes
        switch options.mode {
        case .startOnly:
            PumTimeWheel(title: "시작", minutes: $value.startMinutes, intervalMinutes: step)
        case .endOnly:
            PumTimeWheel(title: "종료", minutes: $value.endMinutes, intervalMinutes: step)
        case .range:
            // 좁으면(큰 글자) 위아래로 — 화살표도 아래를 향한다
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    PumTimeWheel(title: "시작", minutes: $value.startMinutes, intervalMinutes: step)
                    arrow("arrow.right")
                    PumTimeWheel(title: "종료", minutes: $value.endMinutes, intervalMinutes: step)
                }
                VStack(spacing: PumTokens.Space.s8) {
                    PumTimeWheel(title: "시작", minutes: $value.startMinutes, intervalMinutes: step)
                    arrow("arrow.down")
                    PumTimeWheel(title: "종료", minutes: $value.endMinutes, intervalMinutes: step)
                }
            }
        }
    }

    private func arrow(_ name: String) -> some View {
        Image(systemName: name)
            .pumText(.callout, weight: .regular) // 16px 근사
            .foregroundStyle(PumTokens.ColorToken.gray400)
            .accessibilityHidden(true)
    }

    // MARK: 휴게 · 반복

    private var breakRow: some View {
        labeledRow("휴게") {
            ForEach(Array(PumTimePickerStyle.breakChoices.enumerated()), id: \.offset) { i, c in
                PumChoicePill(
                    title: c.title, isOn: value.breakMinutes == c.minutes, offStyle: .filled,
                    position: (i, PumTimePickerStyle.breakChoices.count)
                ) { value.breakMinutes = c.minutes }
            }
        }
    }

    private var repeatRow: some View {
        labeledRow("반복") {
            ForEach(PumTimePickerStyle.weekdays, id: \.id) { d in weekdayChip(d) }
        }
    }

    private func weekdayChip(_ d: (id: Int, short: String, long: String)) -> some View {
        let on = value.weekdays.contains(d.id)
        let pad = max(0, (PumTokens.Size.tapMin - chipSize) / 2)
        return Button {
            if on { value.weekdays.remove(d.id) } else { value.weekdays.insert(d.id) }
        } label: {
            Text(d.short)
                .pumText(.caption, weight: on ? .bold : .semibold) // 12px 700/600
                .foregroundStyle(on ? Color.white : PumColor.textPrimary)
                .frame(width: chipSize, height: chipSize)
                .background(on ? PumColor.surfaceInverse : PumColor.surfaceFill, in: Circle())
                // 보이는 지름은 원문(30), 누름은 위아래로 44까지(옆 칩과 겹치지 않게 가로는 원 크기 그대로)
                .padding(.vertical, pad)
                .contentShape(Rectangle())
                .padding(.vertical, -pad)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(d.long))
        .accessibilityValue(Text(on ? "선택됨" : "선택 안 됨"))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

private extension Text {
    /// Text끼리 `+`로 이으려면 View 수식어(pumText)가 아니라 Text를 돌려주는 수식이 필요하다
    func pumTextStyle(_ style: PumTextStyle, weight: Font.Weight, color: Color) -> Text {
        font(PumFont.font(size: style.token.size, weight: weight, relativeTo: style.relativeTo)).foregroundColor(color)
    }
}

/// 한 줄에 들어가면 한 줄, 넘치면 줄바꿈하는 배치(휴게 알약 · 요일 칩)
private struct PumTimeWrapLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(width: bounds.width, subviews: subviews)
        for (i, f) in r.frames.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + f.minX, y: bounds.minY + f.minY), proposal: ProposedViewSize(f.size))
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            frames.append(CGRect(x: x, y: y, width: sz.width, height: sz.height))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowH), frames)
    }
}

// MARK: - 수식어

extension View {
    /// C13 시간 선택 시트 — `pumBottomSheet`에 얹는다. 「완료」를 누르면 닫고 `onDone`을 부른다.
    /// 값은 시트 안에서 바로 `value`에 쓰이므로 취소가 필요하면 호출 쪽에서 열 때의 값을 따로 둔다.
    func pumTimeRangeSheet(
        isPresented: Binding<Bool>,
        value: Binding<PumTimeRangeValue>,
        options: PumTimeRangeOptions = PumTimeRangeOptions(),
        onDone: @escaping () -> Void = {}
    ) -> some View {
        pumBottomSheet(isPresented: isPresented) {
            PumTimeRangeSheetContent(value: value, options: options) {
                isPresented.wrappedValue = false
                onDone()
            }
        }
    }
}

// MARK: - 원문 비교 데모 · 미리보기

/// 시트가 열린 채 원문 값(10월 5일 (월) · 17:00 → 22:00 · 휴게 30분 · 월수금 · 종료일 없음)으로 보이는 화면. 개발 메뉴용.
struct PumTimePickerDemo: View {
    @State private var open = true
    @State private var value = PumTimeRangeValue()

    var body: some View {
        PumColor.bgApp
            .ignoresSafeArea()
            .pumTimeRangeSheet(isPresented: $open, value: $value, options: PumTimeRangeOptions(onDateTap: {}, onEndDateTap: {}))
            .onChange(of: open) { _, isOpen in if !isOpen { open = true } } // 데모는 닫아도 다시 열어 둔다
    }
}

#Preview("C13") { PumTimePickerDemo() }
#Preview("C13 · 큰 글자") { PumTimePickerDemo().dynamicTypeSize(.accessibility3) }
#Preview("C13 · 끝 휠만") {
    PumColor.bgApp.ignoresSafeArea()
        .pumTimeRangeSheet(
            isPresented: .constant(true), value: .constant(PumTimeRangeValue()),
            options: PumTimeRangeOptions(title: "퇴근 시각", mode: .endOnly, rangeLabel: "종료", showsDate: false, showsBreak: false, showsRepeat: false, showsEndDate: false)
        )
}
