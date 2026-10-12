// UI-IOS-2j · REQ-043 — 사장님 · 추가 근무 요청 (하위 화면, 탭 바 없음)
// 시간 · 휴게 칸 → C13 시간 선택 시트(#66). 「직접」 가산 입력 화면은 디자인 없음 — 지금은 클로저만 호출한다.
import SwiftUI

struct ExtraShiftRequestView: View {
    @State private var state: ExtraShiftRequestState
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()
    var onClose: () -> Void
    var onPickDate: () -> Void
    var onPickStart: () -> Void
    var onPickEnd: () -> Void
    var onPickBreak: () -> Void
    var onCustomPremium: () -> Void
    /// 보내기 — 끝나면 done(성공 여부). 실패면 버튼 잠금이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onSend: (ExtraShiftRequestState, @escaping (Bool) -> Void) -> Void

    // 화면 전용 상수 (DEC-005)
    /// 시간 칸 최소 너비 — 목업 약 73
    @ScaledMetric(relativeTo: .title3) private var timeCellMinWidth: CGFloat = 73
    /// 시간 칸 최소 높이 — 목업 약 31
    @ScaledMetric(relativeTo: .title3) private var timeCellMinHeight: CGFloat = 31
    /// 직원 행 아바타 — 목업 36
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = PumLayout.avatar

    init(state: ExtraShiftRequestState,
         onClose: @escaping () -> Void = {},
         onPickDate: @escaping () -> Void = {},
         onPickStart: @escaping () -> Void = {},
         onPickEnd: @escaping () -> Void = {},
         onPickBreak: @escaping () -> Void = {},
         onCustomPremium: @escaping () -> Void = {},
         onSend: @escaping (ExtraShiftRequestState, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.onClose = onClose
        self.onPickDate = onPickDate
        self.onPickStart = onPickStart
        self.onPickEnd = onPickEnd
        self.onPickBreak = onPickBreak
        self.onCustomPremium = onCustomPremium
        self.onSend = onSend
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    card
                    reasonSection
                    recipientsSection
                    notice
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            state = state.applying(picked: pickerValue)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 0명이면 비활성 — 이유 문구 없음(충돌 #30)
            PumButton(title: state.sendTitle, kind: .primary, isLoading: state.isSending, action: send)
                .disabled(!state.canSend)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    /// 반복 · 종료일은 끈다(2j에 없음). 날짜 행은 화면의 날짜 문구 + 기존 onPickDate(달력 없음)
    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(
            showsDate: true, showsBreak: true, showsRepeat: false, showsEndDate: false,
            intervalMinutes: ExtraShiftRequestState.pickerIntervalMinutes,
            onDateTap: onPickDate
        )
    }

    /// 열 때의 값을 시트용 복사본에 담는다 — 「완료」 전에 닫으면 화면 값은 그대로
    private func openPicker(_ open: @escaping () -> Void) {
        open()
        pickerValue = state.pickerValue
        pickerOpen = true
    }

    private func send() {
        guard state.beginSend() else { return }
        // 실패면 다시 누를 수 있게 풀고, 성공이면 잠근 채 둔다(호출한 쪽이 화면을 닫음 — 두 번 보내지 않기)
        onSend(state) { ok in if !ok { state.endSend() } }
    }

    // MARK: 헤더

    private var header: some View {
        ZStack {
            Text(ExtraShiftRequestState.title).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.top, PumTokens.Space.s8)
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    // MARK: 카드

    private var card: some View {
        PumCard {
            dateRow
            divider
            timeRow
            divider
            breakRow
            divider
            premiumRow
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func rowLayout<L: View, V: View>(@ViewBuilder label: () -> L, @ViewBuilder value: () -> V) -> some View {
        let l = label(), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private var dateRow: some View {
        rowLayout {
            rowLabel("날짜")
        } value: {
            Button(action: onPickDate) {
                HStack(spacing: PumTokens.Space.s8) {
                    Text(state.dateText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let holiday = state.holidayName {
                        Text(holiday).pumText(.caption, weight: .bold).foregroundStyle(PumColor.statusDanger)
                    }
                }
                .padding(.horizontal, PumTokens.Space.s12)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("날짜, \(state.dateText)" + (state.holidayName.map { ", \($0)" } ?? "")))
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("날짜를 골라요"))
        }
    }

    private var timeRow: some View {
        rowLayout {
            rowLabel("시간")
        } value: {
            HStack(spacing: PumTokens.Space.s8) {
                timeCell(state.startText, label: "시작 시간") { openPicker(onPickStart) }
                Text("–").pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray300)
                    .accessibilityHidden(true)
                timeCell(state.endText, label: "종료 시간") { openPicker(onPickEnd) }
            }
        }
    }

    private func timeCell(_ text: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            // 목업 18px 700 → title3 bold
            Text(text).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: timeCellMinWidth, minHeight: timeCellMinHeight)
                .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s6))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(text)"))
        .accessibilityAddTraits(.isButton)
    }

    private var breakRow: some View {
        rowLayout {
            rowLabel("휴게")
        } value: {
            Button { openPicker(onPickBreak) } label: {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
                    Text(state.breakText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    if let recognized = state.recognizedText {
                        Text("· \(recognized)").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                }
                // 보이는 줄 높이는 그대로, 누름 영역만 위아래로 넓힌다(행이 원문보다 높아지지 않게)
                .padding(.vertical, PumTokens.Space.s12)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("휴게 \(state.breakText)" + (state.recognizedText.map { ", \($0)" } ?? "")))
            .accessibilityAddTraits(.isButton)
        }
    }

    private var premiumRow: some View {
        rowLayout {
            rowLabel("급여 가산")
        } value: {
            ExtraShiftFlow(spacing: PumTokens.Space.s8) {
                PumChoicePill(title: "없음", isOn: state.premium == .none, offStyle: .filled, position: (0, 3)) {
                    state.setPremium(.none)
                }
                PumChoicePill(title: state.holidayPremiumTitle, isOn: state.premium == .holiday, offStyle: .filled, position: (1, 3)) {
                    state.setPremium(.holiday)
                }
                // 「직접」 입력 화면은 디자인 없음 — 클로저만
                PumChoicePill(title: "직접", isOn: state.premium == .custom, offStyle: .filled, position: (2, 3), action: onCustomPremium)
            }
        }
    }

    // MARK: 사유

    private var reasonSection: some View {
        let all = ExtraShiftReason.allCases
        return VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("사유").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, PumTokens.Space.s4)
            ExtraShiftFlow(spacing: PumTokens.Space.s8) {
                ForEach(Array(all.enumerated()), id: \.offset) { index, reason in
                    PumChoicePill(title: reason.title, isOn: state.reason == reason, offStyle: .outlined,
                                  position: (index, all.count)) {
                        state.toggle(reason: reason)
                    }
                }
            }
        }
    }

    // MARK: 받는 직원

    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            (Text(state.recipientsLead).fontWeight(.bold)
                + Text(state.recipientsTail).fontWeight(.medium))
                .pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, PumTokens.Space.s4)
            PumCard {
                ForEach(Array(state.candidates.enumerated()), id: \.element.id) { index, c in
                    if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 원문: 직원 행 구분선은 카드 끝까지
                    candidateRow(c)
                }
            }
        }
    }

    private func candidateRow(_ c: ExtraShiftCandidate) -> some View {
        Button { state.toggle(candidate: c.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumAvatar(name: c.name, colorIndex: c.colorIndex, size: avatarSize)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    // 선택 안 된 직원 이름은 회색(원문). 수당 관련 강조는 만들지 않는다(REQ-051)
                    Text(c.name).pumText(.callout, weight: .semibold)
                        .foregroundStyle(c.isSelected ? PumColor.textPrimary : PumColor.textSecondary)
                    Text(c.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PumCheckMark(isOn: c.isSelected)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(c.accessibilityText))
        .accessibilityAddTraits(c.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 안내

    private var notice: some View {
        Text(ExtraShiftRequestState.notice)
            .pumText(.caption).foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s4)
    }
}

/// 알약이 한 줄에 안 들어가면 줄바꿈 — 공통 후보(1af의 Flow와 같은 모양)
private struct ExtraShiftFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, p) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        var origins: [CGPoint] = []
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + spacing; rowH = max(rowH, sz.height); maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowH), origins)
    }
}

#Preview("2j · 캡처 상태") { ExtraShiftRequestView(state: .sample) }
#Preview("2j · 큰 글자") { ExtraShiftRequestView(state: .sample).dynamicTypeSize(.accessibility1) }
