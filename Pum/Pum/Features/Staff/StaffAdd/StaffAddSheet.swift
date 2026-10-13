// UI-IOS-20a · REQ-007 — 직원 추가 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
// 선택 행: 라디오 + 제목(16 600) + 설명(12). 두 행은 한 카드 안에 hairline으로 나눈다.
import SwiftUI

struct StaffAddSheet: View {
    let state: StaffAddState
    var onNext: (StaffAddMethod) -> Void = { _ in }
    @State private var selection: StaffAddMethod?

    init(state: StaffAddState, onNext: @escaping (StaffAddMethod) -> Void = { _ in }) {
        self.state = state
        self.onNext = onNext
        _selection = State(initialValue: state.initialSelection)
    }

    var body: some View {
        // 스크롤은 공통 시트 판이 한다 — 여기서 ScrollView를 겹치면 시트가 화면 끝까지 늘어난다
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(StaffAddState.title).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            PumCard {
                ForEach(Array(StaffAddMethod.allCases.enumerated()), id: \.element.id) { i, m in
                    if i > 0 { Divider().overlay(PumColor.borderHairline) }
                    row(m)
                }
            }
            Text(StaffAddState.notice).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PumTokens.Space.s4)
            PumButton(title: StaffAddState.nextTitle) {
                if let selection { onNext(selection) }
            }
            .disabled(!state.canNext(selection))
            .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    private func row(_ m: StaffAddMethod) -> some View {
        let on = selection == m
        return Button { selection = m } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: on)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(m.title).pumText(.headline, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(m.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(m.readout))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

/// 캡처용 — 기존 직원 목록(1ac) 위에 시트를 올린다. 시트는 값이 있을 때만 연다.
struct StaffAddPreviewHost: View {
    var state: StaffAddState? = .sample
    @State private var open: Bool

    init(state: StaffAddState? = .sample) {
        self.state = state
        _open = State(initialValue: state != nil)
    }

    var body: some View {
        StaffListView()
            .pumBottomSheet(isPresented: $open) {
                if let state { StaffAddSheet(state: state, onNext: { _ in open = false }) }
            }
    }
}

#Preview("20a 시트") { StaffAddPreviewHost() }
