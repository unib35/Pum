// UI-IOS-2i · REQ-010 — 사업장 만들기: 사장님 첫 설정(1 / 3). 탭 바 없음.
// 대표 글자·색 · 업종 · 주소(반경) · 사업자등록번호 · 급여일을 고르는 시트는 디자인 없음 — 누름 클로저만(만들지 않음).
// 비활성 「다음」의 이유 문구는 디자인 없음(충돌 #30과 같은 처리: 회색 비활성만).
// MVP(DEC-033, state.isSolo): 단계 · 초대 안내 · 업종 · 주소 · 사업자번호 · 출퇴근 방식을 숨기고 5인 이상 · 공제 줄을 더한다.
import SwiftUI

struct WorkplaceCreateView: View {
    @State private var state: WorkplaceCreateState
    var onBack: () -> Void
    var onPickMark: () -> Void
    var onPickCategory: () -> Void
    var onPickAddress: () -> Void
    var onPickBusinessNumber: () -> Void
    var onPickPayday: () -> Void
    /// 만들 값과 끝 알림 — 실패(또는 아직 연결 전)면 done(false)로 다시 누를 수 있게
    var onNext: (WorkplaceCreateState, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void

    /// 대표 글자 네모 한 변(원문 약 64) — 큰 글자에서 글자와 함께 커진다. 공통 후보: 사업장 색 큰 네모
    @ScaledMetric(relativeTo: .title2) private var markSize: CGFloat = 64
    private let cardPadX = PumTokens.Space.s18

    init(state: WorkplaceCreateState = .entry,
         onBack: @escaping () -> Void = {},
         onPickMark: @escaping () -> Void = {},
         onPickCategory: @escaping () -> Void = {},
         onPickAddress: @escaping () -> Void = {},
         onPickBusinessNumber: @escaping () -> Void = {},
         onPickPayday: @escaping () -> Void = {},
         onNext: @escaping (WorkplaceCreateState, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onPickMark = onPickMark
        self.onPickCategory = onPickCategory
        self.onPickAddress = onPickAddress
        self.onPickBusinessNumber = onPickBusinessNumber
        self.onPickPayday = onPickPayday
        self.onNext = onNext
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                if !state.isSolo {
                    HStack {
                        PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                        Spacer()
                        Text("1 / 3").pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
                            .accessibilityLabel(Text("3단계 중 1단계"))
                    }
                }
                heading
                markRow
                infoCard
                settingCard
                if !state.isSolo {
                    Text("다음 단계: 근태 정책(연장·조기퇴근 기준) → 직원 초대")
                        .pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px 400
                        .padding(.horizontal, PumTokens.Space.s4)
                }
            }
            .padding(.top, state.isSolo ? PumTokens.Space.s16 : 0)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("사업장을 만들어요")
                .pumText(.title1) // 목업 26px 700 → 가까운 단계 title1 28 (DEC-005)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if !state.isSolo {
                Text("직원은 여기서 만든 초대로만 들어올 수 있어요")
                    .pumText(.callout, weight: .regular) // 14px 400
                    .foregroundStyle(PumColor.textSecondary)
            }
        }
    }

    // 대표 글자 · 색
    private var markRow: some View {
        Button(action: pickMark) {
            HStack(spacing: PumTokens.Space.s14) { // 원문 gap 14
                Text(state.markText).pumText(.title2).foregroundStyle(.white) // 24px 700
                    .frame(width: markSize, height: markSize)
                    .background(PumAvatarPalette.stores[state.markColorIndex % PumAvatarPalette.stores.count],
                                in: RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous))
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text("대표 글자·색").pumText(.callout).foregroundStyle(PumColor.textPrimary) // 14px 600
                    if !state.isSolo {
                        Text("직원 앱에서 사업장을 구분하는 표시예요").pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px 400
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.isSolo ? "대표 글자·색" : "대표 글자·색, 직원 앱에서 사업장을 구분하는 표시예요"))
        .accessibilityValue(Text(state.markText.isEmpty ? "입력 안 됨" : state.markText)) // 지금 대표 글자
        .accessibilityAddTraits(.isButton)
    }

    // 사업장 정보 카드
    private var infoCard: some View {
        PumCard {
            row { nameRow }
            if !state.isSolo {
                divider
                valueRow("업종", state.category, action: onPickCategory)
                divider
                addressRow
                divider
                businessNumberRow
            }
        }
    }

    // 급여일 · 출퇴근 방식 카드
    private var settingCard: some View {
        PumCard {
            if state.isSolo {
                paydayMenuRow
                divider
                row { choiceRow("5인 이상 사업장", options: ["아니요", "예"], selected: state.isFiveOrMore ? 1 : 0) { state.isFiveOrMore = $0 == 1 } }
                divider
                row { choiceRow("공제", options: ["없음", "3.3%"], selected: state.withholds3_3 ? 1 : 0) { state.withholds3_3 = $0 == 1 } }
            } else {
                valueRow("기본 급여일", state.paydayText, action: onPickPayday)
                divider
                row { methodRow }
            }
        }
    }

    /// 급여일 고르기 시트는 디자인 없음 — 20f 휴게처럼 시스템 메뉴
    private var paydayMenuRow: some View {
        Menu {
            Picker("기본 급여일", selection: Binding(get: { state.payday }, set: { state.payday = $0 })) {
                ForEach(1...31, id: \.self) { Text("매월 \($0)일").tag($0) }
            }
        } label: {
            row {
                keyValue { keyText("기본 급여일") } value: { valueText(state.paydayText) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("기본 급여일, \(state.paydayText)"))
    }

    private func choiceRow(_ key: String, options: [String], selected: Int, onSelect: @escaping (Int) -> Void) -> some View {
        keyValue {
            keyText(key)
        } value: {
            HStack(spacing: PumTokens.Space.s6) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, title in
                    PumChoicePill(title: title, isOn: selected == i, offStyle: .filled, position: (i, options.count)) {
                        onSelect(i)
                    }
                }
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, cardPadX)
            .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 0
            .frame(minHeight: PumTokens.Size.tapMin)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, cardPadX)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    /// 키 – 값. 넘치면 값이 키 아래로(큰 글자), 같은 왼쪽 선
    private func keyValue<K: View, V: View>(@ViewBuilder key: () -> K, @ViewBuilder value: () -> V) -> some View {
        let k = key(), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { k; Spacer(minLength: PumTokens.Space.s8); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { k; v }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nameRow: some View {
        keyValue {
            keyText("사업장 이름").accessibilityHidden(true)
        } value: {
            TextField("", text: Binding(get: { state.name }, set: { state.name = $0 }))
                .pumText(.body, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .submitLabel(.done)
                .accessibilityLabel(Text("사업장 이름"))
        }
    }

    private func valueText(_ value: String, placeholder: String? = nil) -> some View {
        Group {
            if value.isEmpty, let placeholder {
                Text(placeholder).pumText(.body, weight: .regular).foregroundStyle(PumColor.textTertiary) // 15px 400 연회색
            } else {
                Text(value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
            }
        }
        .multilineTextAlignment(.trailing)
    }

    private func valueRow(_ key: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            row {
                keyValue { keyText(key) } value: { valueText(value) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(key), \(value.isEmpty ? "입력 안 됨" : value)"))
        .accessibilityAddTraits(.isButton)
    }

    private var addressRow: some View {
        Button(action: onPickAddress) {
            row {
                keyValue {
                    keyText("주소")
                } value: {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) { // 원문: 반경 줄은 주소와 왼쪽 맞춤
                        valueText(state.address)
                        if let r = state.radiusText {
                            Text(r).pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px 400
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("주소, \(state.address.isEmpty ? "입력 안 됨" : state.address)"))
        .accessibilityValue(Text(state.radiusText ?? ""))
        .accessibilityAddTraits(.isButton)
    }

    private var businessNumberRow: some View {
        Button(action: onPickBusinessNumber) {
            row {
                keyValue {
                    HStack(spacing: PumTokens.Space.s4) {
                        keyText("사업자등록번호")
                        Text("(선택)").pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary) // 11px 400
                    }
                } value: {
                    valueText(state.businessNumber, placeholder: "나중에")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("사업자등록번호, 선택, \(state.hasBusinessNumber ? state.businessNumber : "나중에")"))
        .accessibilityAddTraits(.isButton)
    }

    private var methodRow: some View {
        keyValue {
            keyText("출퇴근 방식")
        } value: {
            HStack(spacing: PumTokens.Space.s6) {
                ForEach(Array(WorkplaceCreateState.CheckMethod.allCases.enumerated()), id: \.offset) { i, m in
                    PumChoicePill(title: m.title, isOn: state.method == m, offStyle: .filled,
                                  position: (i, WorkplaceCreateState.CheckMethod.allCases.count)) {
                        state.method = m
                    }
                }
            }
        }
    }

    // 하단 「다음」
    private var actions: some View {
        PumButton(title: "다음", kind: .primary, isLoading: state.isSubmitting, action: next)
            .disabled(!state.canProceed && !state.isSubmitting)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    /// MVP는 고르기 시트(디자인 없음) 대신 누를 때마다 다음 사업장 색
    private func pickMark() {
        if state.isSolo {
            state.markColorIndex = (state.markColorIndex + 1) % PumAvatarPalette.stores.count
        } else {
            onPickMark()
        }
    }

    /// 연속으로 눌러도 한 번만 보낸다
    private func next() {
        guard state.beginSubmit() else { return }
        onNext(state) { succeeded in
            if !succeeded { state.failSubmit() }
        }
    }
}

#Preview("2i") { WorkplaceCreateView(state: .sample) }
#Preview("2i · MVP") { WorkplaceCreateView(state: .soloEntry) }
#Preview("2i · 처음") { WorkplaceCreateView() }
#Preview("2i · 큰 글자") { WorkplaceCreateView(state: .sample).dynamicTypeSize(.xxxLarge) }
