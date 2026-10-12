// UI-IOS-10t · REQ-022 — 출근 판정 · QR + 위치 통과. 기록이 끝난 뒤 결과 표시(보내는 동작 없음). 탭 바 없음.
// 확인은 onDone 하나. 닫기(✕)도 같은 onDone.
import SwiftUI

struct CheckInPassedView: View {
    var state: CheckInPassedState = .sample
    var onDone: () -> Void = {}

    @AccessibilityFocusState private var titleFocused: Bool

    /// 화면 전용: 확인 행 체크 원 지름(원문 약 24)
    private let checkCircle: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    title
                    checksSection
                    timeCard
                    clockOutCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: CheckInPassedState.doneTitle, kind: .dark, action: onDone)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
        .task { titleFocused = true } // 화면이 뜨면 제목에 포커스
    }

    // 닫기 · 가운데 제목. 공통 PumNavHeader는 뒤로(<)라 화면 전용 — 공통 후보: 닫기(✕) 변형
    private var header: some View {
        ZStack {
            Text(CheckInPassedState.screenTitle)
                .pumText(.headline)
                .foregroundStyle(PumColor.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onDone)
                Spacer()
            }
        }
        .padding(.top, PumTokens.Space.s8)
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.subtitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            Text(CheckInPassedState.headline).pumText(.title2)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var checksSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: CheckInPassedState.sectionTitle)
            PumCard {
                ForEach(Array(state.checks.enumerated()), id: \.element.id) { index, check in
                    checkRow(check, isLast: index == state.checks.count - 1)
                }
            }
        }
    }

    private func checkRow(_ check: CheckInPassedCheck, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s14) {
            // 체크리스트 규칙: 회색 원 + 먹색 체크
            Circle().fill(PumColor.surfaceFill)
                .overlay { Image(systemName: "checkmark").pumText(.caption2, weight: .bold).foregroundStyle(PumColor.textPrimary) }
                .frame(width: checkCircle, height: checkCircle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(check.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(check.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 카드 끝까지
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(check.accessibilityText))
    }

    private var timeCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(CheckInPassedState.clockInLabel).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                // 목업 44px 700 → display(52)가 가장 가깝다(DEC-005)
                Text(state.clockInText).pumText(.display)
                    .foregroundStyle(PumColor.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(state.plannedLine).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(state.clockInAccessibility), \(state.plannedLine)"))
        }
    }

    /// 키–값: 한 줄에 들어가면 가로, 글자가 커지면 세로
    private var clockOutCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) { clockOutKey; clockOutValue }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { clockOutKey; clockOutValue }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .combine)
        }
    }

    private var clockOutKey: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(CheckInPassedState.clockOutTitle).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
            Text(state.clockOutNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var clockOutValue: some View {
        Text(state.clockOutHow).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }
}

#Preview("10t") { CheckInPassedView(state: .sample) }
#Preview("10t · 큰 글자") { CheckInPassedView(state: .sample).dynamicTypeSize(.accessibility1) }
