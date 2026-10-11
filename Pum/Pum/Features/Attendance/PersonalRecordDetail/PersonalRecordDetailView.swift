// UI-IOS-2g · REQ-005 · REQ-006 — 개인 기록 상세(하위 화면, 탭 바 없음)
// 시간 휠(공통 #66)은 후속 — 지금은 시간 칸을 누르면 onPickStart / onPickEnd만 부른다.
// 「삭제」는 onDelete만 부른다 — 확인 시트는 원문에 없어 만들지 않았다.
import SwiftUI

struct PersonalRecordDetailView: View {
    @State private var state: PersonalRecordDetailState
    /// 부모가 엔진 재계산 결과를 넘기는 곳 — 조건과 함께 받아 지금 조건일 때만 보인다
    var calc: PersonalRecordDetailState.Calc?
    var onBack: () -> Void
    var onDelete: () -> Void
    var onPickStart: () -> Void
    var onPickEnd: () -> Void
    /// 출근 · 퇴근 · 휴게가 바뀌었을 때(서버 재계산용). 메모는 계산과 무관해 저장 때 함께 보낸다.
    var onRecordChange: (PersonalRecordDetailState) -> Void
    /// 저장 — 끝나면 done(성공 여부). 실패(false)면 잠금이 풀린다.
    var onSave: (PersonalRecordDetailState, @escaping (Bool) -> Void) -> Void

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// 시간 칸 최소 너비 — 목업 약 81 (공통 후보: 1af와 같은 시간 칸)
    @ScaledMetric(relativeTo: .title3) private var timeCellMinWidth: CGFloat = 80
    /// 시간 칸 최소 높이 — 목업 36 (터치는 contentShape로 44 이상)
    @ScaledMetric(relativeTo: .title3) private var timeCellMinHeight: CGFloat = 36
    /// 메모 입력 최소 · 최대 높이 — 목업 2줄 본문 기준
    @ScaledMetric(relativeTo: .callout) private var memoMinHeight: CGFloat = 56
    @ScaledMetric(relativeTo: .callout) private var memoMaxHeight: CGFloat = 160

    init(state: PersonalRecordDetailState = .sample,
         calc: PersonalRecordDetailState.Calc? = nil,
         onBack: @escaping () -> Void = {},
         onDelete: @escaping () -> Void = {},
         onPickStart: @escaping () -> Void = {},
         onPickEnd: @escaping () -> Void = {},
         onRecordChange: @escaping (PersonalRecordDetailState) -> Void = { _ in },
         onSave: @escaping (PersonalRecordDetailState, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) { // 연결 전 기본값은 미저장
        var initial = state
        if let calc { initial.calc = calc }
        _state = State(initialValue: initial)
        self.calc = calc
        self.onBack = onBack
        self.onDelete = onDelete
        self.onPickStart = onPickStart
        self.onPickEnd = onPickEnd
        self.onRecordChange = onRecordChange
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: PersonalRecordDetailState.title, onBack: onBack) { deleteButton }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    title
                    card
                    memoCard
                    notice
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .onChange(of: calc) { _, new in state.calc = new }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: "저장", kind: .dark, isLoading: state.isSaving, action: save)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    private func save() {
        guard state.beginSave() else { return }
        onSave(state) { ok in
            if !ok { state.endSave() }
        }
    }

    private func changed(_ edit: (inout PersonalRecordDetailState) -> Void) {
        let before = state.basis
        edit(&state)
        if state.basis != before { onRecordChange(state) } // 메모만 바뀌면 재계산 요청하지 않음
    }

    // MARK: 1. 헤더

    /// 공통 후보: 헤더 오른쪽 텍스트 버튼(2g 삭제 · 빨강)
    private var deleteButton: some View {
        Button(action: onDelete) {
            Text("삭제").pumText(.body, weight: .semibold).foregroundStyle(PumColor.statusDanger)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: 2. 제목

    private var title: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            HStack(alignment: .firstTextBaseline) {
                // 목업 26px → title2(24)
                Text(state.dateText).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PumTokens.Space.s8)
                PumMyRecordTag()
            }
            Text(state.subtitle).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }

    // MARK: 3. 카드

    private var card: some View {
        PumCard {
            timeRow(.start, label: "출근", onPick: onPickStart)
            divider
            timeRow(.end, label: "퇴근", onPick: onPickEnd)
            divider
            breakRow
            divider
            wageRow
            if let recognized = state.recognizedText, let pay = state.payText {
                divider
                valueRow("인정 시간", recognized, PumColor.textPrimary)
                divider
                valueRow("예상 급여", pay, PumColor.statusDone) // 계산값 = 초록
            }
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

    private func timeRow(_ field: PersonalRecordField, label: String, onPick: @escaping () -> Void) -> some View {
        rowLayout {
            rowLabel(label)
        } value: {
            Button(action: onPick) {
                // 목업 20px 700 → title3 bold
                Text(state.timeText(field)).pumText(.title3, weight: .bold)
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(minWidth: timeCellMinWidth, minHeight: timeCellMinHeight)
                    .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .contentShape(Rectangle().inset(by: -PumTokens.Space.s4))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.timeAccessibility(field)))
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("시각을 골라요. 위아래로 쓸어 10분씩 바꿀 수도 있어요"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: changed { $0.step(field, by: PersonalRecordDetailState.stepMinutes) }
                case .decrement: changed { $0.step(field, by: -PersonalRecordDetailState.stepMinutes) }
                @unknown default: break
                }
            }
        }
    }

    private var breakRow: some View {
        let all = PersonalRecordBreak.allCases
        return rowLayout {
            rowLabel("휴게")
        } value: {
            HStack(spacing: PumTokens.Space.s8) {
                ForEach(Array(all.enumerated()), id: \.offset) { index, option in
                    PumChoicePill(title: option.title, isOn: state.breakOption == option, offStyle: .filled,
                                  position: (index, all.count)) {
                        changed { $0.setBreak(option) }
                    }
                }
            }
        }
    }

    private var wageRow: some View {
        rowLayout {
            rowLabel("시급")
        } value: {
            (Text(state.wageText).font(PumFont.font(size: PumTokens.FontToken.headline.size, weight: .semibold, relativeTo: .headline))
                .foregroundStyle(PumColor.textPrimary)
                + Text(" · 내 조건").font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .regular, relativeTo: .caption))
                .foregroundStyle(PumColor.textTertiary))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("시급 \(state.wageText), 내 조건"))
    }

    private func valueRow(_ label: String, _ value: String, _ color: Color) -> some View {
        rowLayout {
            rowLabel(label)
        } value: {
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label) \(value)"))
    }

    // MARK: 4. 메모

    private var memoCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text("메모").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .accessibilityHidden(true)
                TextEditor(text: Binding(get: { state.memo }, set: { new in changed { $0.memo = new } }))
                    .pumText(.callout, weight: .regular) // 목업 14px 400
                    .foregroundStyle(PumTokens.ColorToken.gray800)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: memoMinHeight, maxHeight: memoMaxHeight)
                    .padding(.horizontal, -PumTokens.Space.s4) // TextEditor 기본 안쪽 여백 상쇄
                    .accessibilityLabel(Text("메모"))
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 5. 안내

    private var notice: some View {
        Text(PersonalRecordDetailState.notice)
            .pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s4)
    }
}

#Preview("2g · 캡처 상태") { PersonalRecordDetailView(state: .sample) }
#Preview("2g · 큰 글자") { PersonalRecordDetailView(state: .sample).dynamicTypeSize(.accessibility3) }
