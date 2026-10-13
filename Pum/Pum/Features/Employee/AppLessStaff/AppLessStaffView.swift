// UI-IOS-20e · UI-IOS-20f · REQ-007 · DEC-001 — 앱 없는 직원 상세(탭 바 없음) + 하루 고치기 시트
// 시트는 서버 값(sheet)이 있을 때만 열린다. 근무함 · 시간 · 사유는 화면 초안(손대지 않았을 때만 서버 새 값을 받는다).
// 인정 근무 · 가산은 서버 미리보기 — 입력이 바뀌면 onInputsChanged로 알리고, 현재 입력과 같은 입력에 대한 값만 보인다.
// 처리 중 표시는 저장 버튼에만, 성공 뒤에는 잠근 채 둔다. 모든 기록은 「사업주 입력」으로 남는다.
import SwiftUI

struct AppLessStaffView: View {
    let state: AppLessStaffState
    /// 서버 값 — nil이면 시트를 열지 않는다
    let sheet: DayFixState?

    @State private var sheetOpen: Bool
    @State private var draft: DayFixDraft
    @State private var touched = false
    @State private var isSaving = false
    @State private var isSaved = false
    /// 시트 값이 오기 전에 눌렀다 — 값이 오면 연다
    /// 시트 값이 오기 전에 누른 날 — 같은 날 값이 오면 연다
    @State private var pendingDayID: String?
    /// 저장을 보낸 날 — 다른 날로 바뀐 뒤 늦게 온 응답은 무시
    @State private var savingDayID: String?
    @State private var focusedField: DayFixField?
    /// 시간 고르기 시트가 열린 칸
    @State private var picking: DayFixField?
    @State private var pickerValue = PumTimeRangeValue()

    var onBack: () -> Void
    /// 행 탭 — 날짜 id. 시트 값(DayFixState)을 불러오는 것은 호출자 몫
    var onEditDay: (String) -> Void
    var onFixOtherDay: () -> Void
    var onContract: () -> Void
    var onInvite: () -> Void
    /// 시트 입력(근무함 · 시간 · 휴게)이 바뀔 때 — 서버가 새 미리보기를 준다
    var onInputsChanged: (DayFixInput) -> Void
    /// 취소 · 막을 눌러 닫음
    var onCancel: () -> Void
    /// 저장(입력, done) — 끝나면 done(성공 여부). 실패면 버튼이 풀리고, 성공이면 잠근 채 둔다
    var onSave: (DayFixInput, @escaping (Bool) -> Void) -> Void

    @ScaledMetric(relativeTo: .title2) private var avatarSize = PumTokens.Space.s24 * 2

    init(state: AppLessStaffState,
         sheet: DayFixState? = nil,
         startsWithSheetOpen: Bool = false,
         onBack: @escaping () -> Void = {},
         onEditDay: @escaping (String) -> Void = { _ in },
         onFixOtherDay: @escaping () -> Void = {},
         onContract: @escaping () -> Void = {},
         onInvite: @escaping () -> Void = {},
         onInputsChanged: @escaping (DayFixInput) -> Void = { _ in },
         onCancel: @escaping () -> Void = {},
         onSave: @escaping (DayFixInput, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.sheet = sheet
        _sheetOpen = State(initialValue: startsWithSheetOpen && sheet != nil)
        _draft = State(initialValue: sheet?.initialDraft ?? DayFixDraft(kind: .worked, startMinutes: 0, endMinutes: 0, breakMinutes: 0, reason: ""))
        _focusedField = State(initialValue: startsWithSheetOpen ? .start : nil) // 원문 캡처: 출근 칸이 입력 중 모양
        self.onBack = onBack
        self.onEditDay = onEditDay
        self.onFixOtherDay = onFixOtherDay
        self.onContract = onContract
        self.onInvite = onInvite
        self.onInputsChanged = onInputsChanged
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    workCard
                    actionCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .pumBottomSheet(isPresented: $sheetOpen, onDismiss: dismissed) {
            if let sheet {
                DayFixSheet(
                    state: sheet,
                    draft: $draft,
                    isSaving: isSaving,
                    isSaved: isSaved,
                    focusedField: focusedField,
                    onEdit: { touched = true },
                    onPickStart: { openPicker(.start) },
                    onPickEnd: { openPicker(.end) },
                    onCancel: cancel,
                    onSave: save
                )
            }
        }
        .pumTimeRangeSheet(
            isPresented: Binding(get: { picking != nil }, set: { if !$0 { closePicker() } }),
            value: $pickerValue,
            options: pickerOptions
        )
        .onChange(of: pickerValue) { _, new in
            guard let field = picking else { return }
            // 고르기를 연 것만으로는 손댄 것이 아님 — 값이 실제로 바뀔 때만
            if field == .start {
                guard new.startMinutes != draft.startMinutes else { return }
                touched = true; draft.startMinutes = new.startMinutes
            } else {
                guard new.endMinutes != draft.endMinutes else { return }
                touched = true; draft.endMinutes = new.endMinutes
            }
        }
        .onChange(of: draft) { old, new in
            guard touched, let sheet, sheet.input(old).calcKey != sheet.input(new).calcKey else { return }
            onInputsChanged(sheet.input(new)) // 사유만 바뀐 것은 알리지 않는다
        }
        .onChange(of: sheet) { old, new in
            if old?.dayID != new?.dayID { // 다른 날이면 새로 시작(보내던 응답은 버린다)
                touched = false
                isSaved = false
                isSaving = false
                savingDayID = nil
                pickerReset()
            }
            if !touched && !isSaving && !isSaved { // 보내는 중 · 보낸 뒤에는 보낸 값 그대로
                if let new { draft = new.initialDraft }
            }
            if new == nil { sheetOpen = false }
            if let new, pendingDayID == new.dayID { pendingDayID = nil; sheetOpen = true }
        }
    }

    // MARK: 시트 동작

    private var pickerOptions: PumTimeRangeOptions {
        let isStart = picking != .end
        return PumTimeRangeOptions(
            title: isStart ? DayFixState.startPickerTitle : DayFixState.endPickerTitle,
            mode: isStart ? .startOnly : .endOnly,
            rangeLabel: isStart ? DayFixState.startTitle : DayFixState.endTitle,
            showsDate: false, showsBreak: false, showsRepeat: false, showsEndDate: false)
    }

    private func openPicker(_ field: DayFixField) {
        pickerValue = PumTimeRangeValue(startMinutes: draft.startMinutes, endMinutes: draft.endMinutes)
        focusedField = field
        picking = field
    }

    private func closePicker() {
        picking = nil
        focusedField = nil
    }

    private func pickerReset() {
        picking = nil
        focusedField = nil
    }

    private func open(day id: String) {
        onEditDay(id)
        if let sheet, sheet.dayID == id { sheetOpen = true } else { pendingDayID = id }
    }

    private func cancel() {
        guard !isSaving else { return }
        sheetOpen = false
        dismissed()
    }

    private func dismissed() {
        pendingDayID = nil
        onCancel()
    }

    private func save() {
        guard let sheet, !isSaving, !isSaved else { return }
        isSaving = true
        savingDayID = sheet.dayID
        onSave(sheet.input(draft)) { ok in
            guard savingDayID == sheet.dayID else { return } // 그사이 다른 날로 바뀌었으면 무시
            savingDayID = nil
            isSaving = false
            if ok { isSaved = true }
        }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(AppLessStaffState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLessStaffState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var header: some View {
        let nameBlock = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.name).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(state.summaryText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        let badge = PumBadge(text: AppLessStaffState.badgeText, kind: .waiting)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                avatar
                nameBlock.frame(maxWidth: .infinity, alignment: .leading)
                badge
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                HStack(spacing: PumTokens.Space.s12) { avatar; badge }
                nameBlock
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .combine)
    }

    /// 원문 아바타는 회색 바탕(C7 색 순환에 없음) — 이름 첫 글자
    private var avatar: some View {
        Text(PumAvatar.initial(for: state.name))
            .pumText(.headline, weight: .bold)
            .foregroundStyle(PumTokens.ColorToken.gray800)
            .frame(width: avatarSize, height: avatarSize)
            .background(PumColor.surfaceFill, in: Circle())
            .accessibilityHidden(true)
    }

    // MARK: 근무 카드

    private var workCard: some View {
        PumCard {
            sectionRow
            // 원문: 제목 줄 밑에는 구분선이 없고, 행 사이에만 있다
            ForEach(Array(state.days.enumerated()), id: \.element.id) { i, day in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                dayRow(day)
            }
        }
    }

    private var sectionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { sectionTitle; Spacer(minLength: PumTokens.Space.s8); ownerInput }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { sectionTitle; ownerInput }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.top, PumTokens.Space.s14) // 원문 padding 14 16 4
        .padding(.bottom, PumTokens.Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.sectionReadout))
        .accessibilityAddTraits(.isHeader)
    }

    private var sectionTitle: some View {
        Text(state.sectionTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var ownerInput: some View {
        Text(AppLessStaffState.ownerInputText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    private func dayRow(_ day: AppLessWorkDay) -> some View {
        let upcoming = day.status == .upcoming
        let tint = upcoming ? PumColor.textTertiary : PumColor.textPrimary
        let date = Text(day.dateText).pumText(.callout, weight: .semibold).foregroundStyle(tint)
        let times = VStack(alignment: .trailing, spacing: PumTokens.Space.s2) {
            Text(day.timeText).pumText(.callout, weight: .semibold).foregroundStyle(tint)
            Text(day.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: false, vertical: true)
        return Button { open(day: day.id) } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    date.fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: PumTokens.Space.s8)
                    times
                    dayBadge(day)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    date
                    HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                        times
                        dayBadge(day)
                    }
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.readout))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private func dayBadge(_ day: AppLessWorkDay) -> some View {
        switch day.status {
        case .asPlanned:
            PumBadge(text: AppLessDayStatus.asPlanned.badgeText ?? "", kind: .waiting).accessibilityHidden(true)
        case .edited:
            PumBadge(text: AppLessDayStatus.edited.badgeText ?? "", kind: .closed).accessibilityHidden(true) // 흰 바탕 + 테두리
        case .upcoming:
            EmptyView()
        }
    }

    // MARK: 이동 카드

    private var actionCard: some View {
        PumCard {
            navRow(title: AppLessStaffState.fixOtherTitle, detail: AppLessStaffState.fixOtherDetail,
                   readout: state.fixOtherReadout, action: onFixOtherDay)
            Divider().overlay(PumColor.borderHairline)
            navRow(title: AppLessStaffState.contractTitle, detail: state.contractText,
                   readout: state.contractReadout, action: onContract)
            Divider().overlay(PumColor.borderHairline)
            navRow(title: AppLessStaffState.inviteTitle, detail: AppLessStaffState.inviteDetail,
                   readout: state.inviteReadout, action: onInvite)
        }
    }

    private func navRow(title: String, detail: String, readout: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").pumText(.callout, weight: .semibold)
                    .foregroundStyle(PumColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(readout))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("20e 앱 없는 직원") { AppLessStaffView(state: .sample, sheet: .sample) }
#Preview("20f 하루 고치기 시트") { AppLessStaffView(state: .sample, sheet: .sample, startsWithSheetOpen: true) }
#Preview("20e · 큰 글자") { AppLessStaffView(state: .sample, sheet: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("20f 시트 · 큰 글자") { AppLessStaffView(state: .sample, sheet: .sample, startsWithSheetOpen: true).dynamicTypeSize(.xxxLarge) }
