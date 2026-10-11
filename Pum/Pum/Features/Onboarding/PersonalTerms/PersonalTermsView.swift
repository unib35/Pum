// UI-IOS-2e · REQ-005 — 개인 근로조건: 급여 계산기 설정(혼자 쓸 때). 탭 바 없음.
// 예상 월급은 서버 엔진 값을 받아 표시만 한다(조건이 바뀌면 onTermsChange로 알린다).
// 근무 시간 · 휴게 · 급여일 선택 시트는 이번 범위 밖 — 누름 클로저만.
// 비활성 「시작하기」의 이유 문구는 디자인 없음(충돌 #30과 같은 처리: 회색 비활성만).
import SwiftUI

struct PersonalTermsView: View {
    @State private var state: PersonalTermsState
    var onBack: () -> Void
    var onTermsChange: (PersonalTermsState) -> Void
    var onPickTime: () -> Void
    var onPickBreak: () -> Void
    var onPickPayday: () -> Void
    var onStart: (PersonalTermsState) -> Void
    var onLater: () -> Void

    @FocusState private var amountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 요일 칩 지름(원문 실측 30pt) — 큰 글자에서 글자와 함께 커진다. 공통 후보: 요일 원형 칩
    @ScaledMetric(relativeTo: .caption) private var chipSize: CGFloat = 30
    /// 카드 안쪽 좌우 여백(원문 18)
    private let cardPadX = PumTokens.Space.s18

    init(state: PersonalTermsState = .entry,
         onBack: @escaping () -> Void = {},
         onTermsChange: @escaping (PersonalTermsState) -> Void = { _ in },
         onPickTime: @escaping () -> Void = {},
         onPickBreak: @escaping () -> Void = {},
         onPickPayday: @escaping () -> Void = {},
         onStart: @escaping (PersonalTermsState) -> Void = { _ in },
         onLater: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onTermsChange = onTermsChange
        self.onPickTime = onPickTime
        self.onPickBreak = onPickBreak
        self.onPickPayday = onPickPayday
        self.onStart = onStart
        self.onLater = onLater
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                HStack {
                    PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                    Spacer()
                }
                .padding(.bottom, PumTokens.Space.s4)
                heading
                card
                if let text = state.estimateText { estimateBox(text) }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .animation(reduceMotion ? nil : PumMotion.fast, value: state.estimatedMonthly)
        .onChange(of: state) { _, new in onTermsChange(new) }
    }

    // 1. 큰 제목 + 안내
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("내 근무 조건을\n알려주세요")
                .pumText(.title1)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("이 조건으로 예상 월급을 계산해요. 나중에 수정 가능")
                .pumText(.body, weight: .regular) // 목업 14px → 가까운 단계 body 15 (DEC-005)
                .foregroundStyle(PumColor.textSecondary)
        }
    }

    // 2. 설정 카드
    private var card: some View {
        PumCard {
            row { workplaceRow }
            divider
            row { payTypeRow }
            divider
            row { amountRow }
            divider
            row { daysRow }
            divider
            valueRow("근무 시간", state.timeRangeText, action: onPickTime)
            divider
            valueRow("휴게", state.breakText, action: onPickBreak)
            divider
            valueRow("급여일", state.paydayText, action: onPickPayday)
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, cardPadX)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, cardPadX)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    /// 키 – 값. 넘치면 세로로(큰 글자)
    private func keyValue<K: View, V: View>(@ViewBuilder key: () -> K, @ViewBuilder value: () -> V) -> some View {
        let k = key(), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { k; Spacer(minLength: PumTokens.Space.s8); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { k; v }
        }
    }

    private var workplaceRow: some View {
        keyValue {
            HStack(spacing: PumTokens.Space.s4) {
                keyText("일하는 곳")
                Text("(선택)").pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary) // 11px 400
            }
            .accessibilityHidden(true)
        } value: {
            TextField("", text: Binding(get: { state.workplace }, set: { state.workplace = $0 }))
                .pumText(.body, weight: .semibold)
                .foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .submitLabel(.done)
                .accessibilityLabel(Text("일하는 곳, 선택"))
        }
    }

    private var payTypeRow: some View {
        keyValue {
            keyText("급여 방식")
        } value: {
            HStack(spacing: PumTokens.Space.s6) {
                ForEach(Array(PersonalTermsState.PayType.allCases.enumerated()), id: \.offset) { i, type in
                    PumChoicePill(title: type.title, isOn: state.payType == type, offStyle: .filled,
                                  position: (i, PersonalTermsState.PayType.allCases.count)) {
                        state.payType = type
                    }
                }
            }
        }
    }

    // 금액: 연파랑 상자 안 파랑 큰 숫자. 숫자만 · 정수 원 · 천 단위 쉼표
    private var amountRow: some View {
        keyValue {
            keyText(state.payType.title)
        } value: {
            HStack(spacing: 0) {
                TextField("0", text: Binding(
                    get: { state.amountText },
                    set: { state.amount = PersonalTermsState.sanitizedAmount($0) }))
                    .keyboardType(.numberPad)
                    .focused($amountFocused)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: PumTokens.Space.s24)
                Text("원")
            }
            .pumText(.title3) // 20px 700
            .foregroundStyle(PumColor.accent)
            .padding(.horizontal, PumTokens.Space.s14)
            .padding(.vertical, PumTokens.Space.s6)
            .background(PumColor.accentSoftStrong, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)) // 원문 #D6DFFB = blue-100
            .contentShape(Rectangle())
            .frame(minHeight: PumTokens.Size.tapMin)
            .onTapGesture { amountFocused = true }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.payType.title))
            .accessibilityValue(Text(state.amountAccessibilityValue))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { amountFocused = true }
        }
    }

    // 근무 요일: 원형 칩 7개, 넘치면 줄바꿈
    private var daysRow: some View {
        keyValue {
            keyText("근무 요일")
        } value: {
            PersonalTermsFlow(spacing: PumTokens.Space.s4) {
                ForEach(PersonalTermsState.weekdays, id: \.id) { d in dayChip(d) }
            }
        }
    }

    private func dayChip(_ d: (id: Int, short: String, long: String)) -> some View {
        let on = state.isSelected(d.id)
        let sunday = d.id == PersonalTermsState.sunday // 일요일 빨강 = 주간 스트립과 같은 statusDanger
        return Button { state.toggleDay(d.id) } label: {
            Text(d.short)
                .pumText(.caption, weight: on ? .bold : .semibold) // 12px 700/600
                .foregroundStyle(on ? Color.white : (sunday ? PumColor.statusDanger : PumColor.textPrimary))
                .frame(width: chipSize, height: chipSize)
                .background(on ? PumColor.surfaceInverse : PumColor.surfaceFill, in: Circle())
                // 보이는 지름은 원문(30), 누름은 위아래로 44까지(옆 칩과 겹치지 않게 가로는 원 크기 그대로)
                .padding(.vertical, max(0, (PumTokens.Size.tapMin - chipSize) / 2))
                .contentShape(Rectangle())
                .padding(.vertical, -max(0, (PumTokens.Size.tapMin - chipSize) / 2))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(d.long))
        .accessibilityValue(Text(on ? "선택됨" : "선택 안 됨"))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func valueRow(_ key: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            row {
                keyValue {
                    keyText(key)
                } value: {
                    Text(value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(key), \(value)"))
        .accessibilityAddTraits(.isButton)
    }

    // 3. 예상 상자(엔진 값 표시만)
    private func estimateBox(_ text: String) -> some View {
        keyValue {
            Text("이 조건이면 한 달 예상").pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
        } value: {
            Text(text).pumText(.headline, weight: .bold).foregroundStyle(PumColor.statusDone) // 17px 700
                .monospacedDigit()
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s14)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // 4. 하단 버튼
    private var actions: some View {
        VStack(spacing: 0) {
            PumButton(title: "시작하기", kind: .primary) { onStart(state) }
                .disabled(!state.canStart)
            Button(action: onLater) {
                Text("나중에 설정").pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 목업 14px → body 15
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

/// 요일 칩 배치 — 한 줄에 들어가면 한 줄, 넘치면 줄바꿈. 공통 후보: 줄바꿈 흐름 배치
private struct PersonalTermsFlow: Layout {
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

#Preview("2e") { PersonalTermsView(state: .sample) }
#Preview("2e · 처음") { PersonalTermsView(state: .entry) }
#Preview("2e · 큰 글자") { PersonalTermsView(state: .sample).dynamicTypeSize(.xxxLarge) }
