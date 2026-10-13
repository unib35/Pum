// UI-IOS-10a · REQ-008 · REQ-060 — 근로조건 입력(하위 화면, 탭 바 없음). 「계약서 미리보기」 → 10b.
// 시급 · 급여일 · 지급 방법 · 계약 기간은 입력 화면이 없어(날짜 선택 #192 미정) 클로저만 부른다. 근무 시간 · 휴게는 C13 시트.
// 서버(엔진) 값은 계산 조건이 지금 입력과 같을 때만 보인다. 다르면 카드는 제목만 남기고 부모에 알린다.
import SwiftUI

struct WorkTermsInputView: View {
    @State private var state: WorkTermsInputState
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()
    var onBack: () -> Void
    var onEditWage: () -> Void
    var onPickPayday: () -> Void
    var onPickPayMethod: () -> Void
    var onPickPeriod: () -> Void
    /// 입력이 바뀔 때마다 — 부모가 엔진에 다시 계산을 요청한다
    var onTermsChanged: (WorkTermsInputs) -> Void
    var onShowItems: () -> Void
    var onPreview: () -> Void
    /// 부모가 엔진에서 받은 최신 결과(계산 조건 포함)
    var latestResult: WorkTermsResult?

    // 화면 전용 상수 (DEC-005)
    /// 요일 칩 한 변 — 원문 30(2e · 8d와 같은 값)
    @ScaledMetric(relativeTo: .caption) private var chipSize = PumTimePickerStyle.weekdayChip
    /// 필수 항목 줄 체크 원 지름 — 원문 20
    @ScaledMetric(relativeTo: .footnote) private var checkSize: CGFloat = 20

    init(state: WorkTermsInputState = .sample,
         onBack: @escaping () -> Void = {},
         onEditWage: @escaping () -> Void = {},
         onPickPayday: @escaping () -> Void = {},
         onPickPayMethod: @escaping () -> Void = {},
         onPickPeriod: @escaping () -> Void = {},
         onTermsChanged: @escaping (WorkTermsInputs) -> Void = { _ in },
         onShowItems: @escaping () -> Void = {},
         onPreview: @escaping () -> Void = {},
         latestResult: WorkTermsResult? = nil) {
        var initial = state
        if let r = latestResult, r.basis == state.inputs { initial.result = r }
        _state = State(initialValue: initial)
        self.latestResult = latestResult
        self.onBack = onBack
        self.onEditWage = onEditWage
        self.onPickPayday = onPickPayday
        self.onPickPayMethod = onPickPayMethod
        self.onPickPeriod = onPickPeriod
        self.onTermsChanged = onTermsChanged
        self.onShowItems = onShowItems
        self.onPreview = onPreview
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: WorkTermsInputState.title, onBack: onBack) {
                Text(WorkTermsInputState.stepText).pumText(.footnote, weight: .semibold)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.trailing, PumTokens.Space.s8)
                    .accessibilityLabel(Text("2단계 중 1단계"))
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(spacing: PumTokens.Space.s12) {
                    employeeCard
                    section(WorkTermsInputState.wageHeading) { wageCard }
                    section(WorkTermsInputState.workHeading) { workCard }
                    weeklyCard
                    requiredLine
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        // 엔진 새 결과 — 지금 입력으로 계산한 것만 받는다(늦게 온 이전 조건 응답이 새 결과를 덮지 않게)
        .onChange(of: latestResult) { _, new in if let new, new.basis == state.inputs { state.result = new } }
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            state.apply(picked: pickerValue)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: WorkTermsInputState.previewTitle, kind: .primary, action: onPreview)
                .disabled(!state.canPreview)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
        .onChange(of: state.inputs) { _, new in onTermsChanged(new) }
    }

    /// 시간 · 휴게만 켠다(날짜 · 반복 · 종료일 없음)
    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(showsDate: false, showsBreak: true, showsRepeat: false, showsEndDate: false)
    }

    private func openPicker() {
        pickerValue = state.pickerValue
        pickerOpen = true
    }

    // MARK: 직원 카드

    private var employeeCard: some View {
        PumCard {
            let avatar = PumAvatar(name: state.employeeName, colorIndex: 1)
            let names = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.employeeName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(state.subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            let badge = PumBadge(text: WorkTermsInputState.employeeBadge, kind: .attention)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    avatar
                    names.frame(maxWidth: .infinity, alignment: .leading)
                    badge
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    HStack(spacing: PumTokens.Space.s12) { avatar; names }
                    badge
                }
            }
            .padding(.vertical, PumTokens.Space.s12)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: 임금

    private var wageCard: some View {
        PumCard {
            // 시급: 값 아래 최저임금 안내(서버 값). 낮으면 안내 글자만 빨강(원문 없음 — 새 문구 없음)
            kvRow("시급", chevron: false, spoken: state.wageSpoken, action: onEditWage) {
                VStack(alignment: .trailing, spacing: PumTokens.Space.s2) {
                    valueText(state.wageText)
                    if let note = state.minimumWageText {
                        Text(note).pumText(.caption)
                            .foregroundStyle(state.isBelowMinimumWage ? PumColor.statusDanger : PumColor.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            divider
            kvRow("급여일", spoken: "급여일, \(state.inputs.paydayText)", action: onPickPayday) {
                valueText(state.inputs.paydayText)
            }
            divider
            kvRow("지급 방법", spoken: "지급 방법, \(state.inputs.payMethodText)", action: onPickPayMethod) {
                valueText(state.inputs.payMethodText)
            }
        }
    }

    // MARK: 근무

    private var workCard: some View {
        PumCard {
            kvRow("계약 기간", spoken: "계약 기간, \(state.inputs.periodText)", action: onPickPeriod) {
                valueText(state.inputs.periodText)
            }
            divider
            weekdayRow
            divider
            kvRow("근무 시간", spoken: "근무 시간, \(state.timeSpoken)", action: openPicker) { valueText(state.timeText) }
            divider
            kvRow("휴게", subtitle: state.breakNotice, chevron: false, spoken: breakSpoken, action: openPicker) {
                valueText(state.breakText)
            }
        }
    }

    private var breakSpoken: String {
        ["휴게", state.breakText, state.breakNotice].compactMap { $0 }.joined(separator: ", ")
    }

    // MARK: 주 소정근로시간 카드 — 서버 값, 조건이 다르면 제목만

    private var weeklyCard: some View {
        PumCard {
            let left = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(WorkTermsInputState.weeklyTitle).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                if let benefits = state.benefitsText {
                    Text(benefits).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    left.frame(maxWidth: .infinity, alignment: .leading)
                    if let weekly = state.weeklyText { valueText(weekly) }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    left
                    if let weekly = state.weeklyText { valueText(weekly) }
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: 필수 항목 줄 — 서버 값, 조건이 다르면 숨김

    @ViewBuilder private var requiredLine: some View {
        if let text = state.requiredText {
            let label = HStack(spacing: PumTokens.Space.s10) {
                Image(systemName: "checkmark")
                    .font(.system(size: checkSize * 0.6, weight: .bold))
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(width: checkSize, height: checkSize)
                    .background(PumColor.surfaceFill, in: Circle())
                    .accessibilityHidden(true)
                Text(text).pumText(.footnote).foregroundStyle(PumTokens.ColorToken.gray800)
            }
            let link = Button(action: onShowItems) {
                Text(WorkTermsInputState.showItemsTitle).pumText(.footnote, weight: .semibold)
                    .foregroundStyle(PumColor.accent)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { label; Spacer(minLength: 0); link }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { label; link }
            }
            .padding(.horizontal, PumTokens.Space.s4)
        }
    }

    // MARK: 행 조각

    /// 구역 제목과 카드 사이 6(원문)
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title)
            content()
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    private func valueText(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    private func keyText(_ text: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(text).pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let subtitle { Text(subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary) }
        }
    }

    /// 키–값 행(누르면 action). 좁으면 값이 키 아래로 내려간다(세로)
    private func kvRow<V: View>(_ key: String, subtitle: String? = nil, chevron: Bool = true,
                                spoken: String, action: @escaping () -> Void,
                                @ViewBuilder value: () -> V) -> some View {
        let k = keyText(key, subtitle: subtitle), v = value()
        let chev = Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
        return Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    k.fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: PumTokens.Space.s12)
                    v
                    if chevron { chev }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    k
                    HStack(spacing: PumTokens.Space.s8) { v; if chevron { chev } }
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 요일 칩 — 화면 안에서 바로 토글 (둥근 네모)

    private var weekdayRow: some View {
        let l = keyText("근무 요일")
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
                    Text(day.short).pumText(.caption, weight: .semibold)
                        .foregroundStyle(on ? Color.white : PumColor.textSecondary)
                        .frame(width: chipSize, height: chipSize)
                        .background(on ? PumColor.surfaceInverse : PumColor.surfaceFill,
                                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                        // 누름 영역: 세로 44pt, 가로는 칩 + 간격(이웃과 겹치지 않게). 줄 높이에는 칩 크기만 쓴다
                        .frame(minWidth: chipSize + PumTokens.Space.s4, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                        .padding(.vertical, -max(0, PumTokens.Size.tapMin - chipSize) / 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -PumTokens.Space.s2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day.long)) // 선택 상태는 특성으로 한 번만
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

#Preview("10a 원문") { WorkTermsInputView(state: .sample) }
