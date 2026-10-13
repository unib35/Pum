// UI-IOS-8c · REQ-028 · REQ-070 — 근무 마감 확인: 뒤 화면(마감 가능 상태) 위에 공통 바텀시트(C9).
// 마감은 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다. 처리 중에는 취소 · 막 누름 · 두 손가락 닫기도 막는다.
// 색: 초록 = 모든 기록 확인(뒤 카드) · 파랑 = 주 버튼. 합계는 계산하지 않는다(서버 값).
import SwiftUI

struct WorkClosingConfirmView: View {
    var state: WorkClosingConfirmState = .sample
    var onBack: () -> Void = {}
    var onCancel: () -> Void = {}
    /// 마감 실행. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onConfirm: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var sheetOpen: Bool
    @State private var lock = WorkClosingLock()
    @ScaledMetric(relativeTo: .body) private var badgeSize = PumTokens.Space.s24 + PumTokens.Space.s8 // 원문 원 약 32pt

    init(state: WorkClosingConfirmState = .sample, sheetOpen: Bool = true,
         onBack: @escaping () -> Void = {}, onCancel: @escaping () -> Void = {},
         onConfirm: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        _sheetOpen = State(initialValue: sheetOpen)
    }

    private var isClosing: Bool { lock.isClosing }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: guardedOpen, onDismiss: dismissed) { sheet }
    }

    /// 처리 중에는 막 누름 · 두 손가락 닫기로 닫히지 않게 한다
    private var guardedOpen: Binding<Bool> {
        Binding(get: { sheetOpen }, set: { newValue in
            if WorkClosingConfirmState.allowsSheetChange(to: newValue, isClosing: isClosing) { sheetOpen = newValue }
        })
    }

    private func dismissed() {
        guard !isClosing else { return }
        onCancel()
    }

    // MARK: 뒤 화면

    private var background: some View {
        VStack(spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
            PumNavHeader(title: "근무 마감", onBack: onBack) { EmptyView() }
            checkedCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var checkedCard: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Image(systemName: "checkmark").pumText(.footnote, weight: .bold).foregroundStyle(.white)
                .frame(width: badgeSize, height: badgeSize)
                .background(PumTokens.ColorToken.green700, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.checkedTitle).pumText(.body, weight: .bold).foregroundStyle(PumTokens.ColorToken.green700)
                Text(state.checkedSubtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.statusDone)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 16
        .padding(.horizontal, PumTokens.Space.s16)
        .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: 시트

    private var sheet: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(state.sheetTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 22px 700
                .accessibilityAddTraits(.isHeader)
            summaryCard
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                bullet {
                    Text("\(state.lockNoticePrefix)\(Text(state.lockNoticeStrong).fontWeight(.bold))\(state.lockNoticeSuffix)")
                }
                .accessibilityLabel(Text(state.lockNoticeSpoken))
                bullet { Text(state.calcNotice) }
            }
            VStack(spacing: PumTokens.Space.s4) {
                PumButton(title: state.confirmTitle, kind: .primary, isLoading: isClosing, loadingTitle: "마감하는 중", action: confirm)
                    .disabled(isClosing || !state.canClose)
                PumButton(title: "취소", kind: .text, action: cancel)
                    .disabled(isClosing)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 − 안전 영역 34
    }

    private var summaryCard: some View {
        PumCard {
            termRow("직원", state.employeeText, weight: .semibold, isLast: false)
            termRow("근무기록", state.recordText, weight: .semibold, isLast: false)
            termRow("총 근무", state.totalWorkText, weight: .semibold, isLast: false)
            termRow("예상 인건비", state.laborCostText, weight: .bold, isLast: true)
        }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로. 행 사이 선은 좌우 여백 안쪽
    private func termRow(_ label: String, _ value: String, weight: Font.Weight, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                val(value, weight).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                val(value, weight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(value)"))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private func val(_ s: String, _ weight: Font.Weight) -> some View {
        Text(s).pumText(.body, weight: weight).foregroundStyle(PumColor.textPrimary)
    }

    /// 공통 후보: 점 목록 행(원문 점 + 13px 400 gray800)
    private func bullet<C: View>(@ViewBuilder _ text: () -> C) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s10) { // 원문 점~글 10
            Circle().fill(PumColor.textPrimary).frame(width: PumTokens.Space.s4, height: PumTokens.Space.s4)
                .accessibilityHidden(true)
            text().pumText(.footnote, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .combine)
    }

    // MARK: 동작

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func confirm() {
        guard lock.begin(canClose: state.canClose) else { return }
        onConfirm { success in lock.finish(success: success) }
    }

    private func cancel() {
        guard !isClosing else { return }
        sheetOpen = false
        onCancel()
    }
}

#Preview("8c") { WorkClosingConfirmView(state: .sample) }
#Preview("8c · 큰 글자") { WorkClosingConfirmView(state: .sample).dynamicTypeSize(.xxxLarge) }
