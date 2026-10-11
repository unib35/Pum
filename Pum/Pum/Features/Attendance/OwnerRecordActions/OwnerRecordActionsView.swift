// UI-IOS-1ah · REQ-027 · DEC-005 — 근무기록 삭제(사장님): 확정 전 삭제 가능, 확정 후는 정정으로.
// 메뉴 항목 · 취소는 클로저만. 삭제는 실제로 지우지 않는다(사유 입력 · 확인은 디자인 없음 — 후속).
import SwiftUI

struct OwnerRecordActionsView: View {
    var state: OwnerRecordActionsState = .sample
    var onBack: () -> Void = {}
    var onAction: (OwnerRecordAction) -> Void = { _ in }
    var onCancel: () -> Void = {}
    /// 원문 캡처가 시트 열림이라 기본도 열린 상태
    @State private var isSheetOpen = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Local {
        /// 사람 아바타 약 44 → 터치 최소 크기 토큰(44)과 같다
        static let avatarSize: CGFloat = PumTokens.Size.tapMin
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            background.accessibilityHidden(isSheetOpen) // 시트가 열리면 뒤 화면은 읽지 않는다
            if isSheetOpen {
                // 막: 공통 scrim 값. 누름 = 취소
                Button(action: cancel) {
                    PumColor.textPrimary.opacity(PumBottomSheetStyle.scrimOpacity)
                        .ignoresSafeArea().contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(OwnerRecordActionsState.cancelText))
                .transition(.opacity)
                OwnerRecordActionsSheet(state: state, onAction: choose, onCancel: cancel)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    // M22: 동작 줄이기면 올라오는 대신 페이드
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.sheet), value: isSheetOpen) // M3
    }

    private func cancel() {
        isSheetOpen = false
        onCancel()
    }

    private func choose(_ item: OwnerRecordAction) {
        isSheetOpen = false
        onAction(item)
    }

    // A. 뒤 화면
    private var background: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: OwnerRecordActionsState.screenTitle, onBack: onBack) {
                PumIconButton(systemImage: "ellipsis", label: OwnerRecordActionsState.moreLabel) { isSheetOpen = true }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    personRow
                    PumCard {
                        // 원문 값 15px 600 — PumRow 기본 값 글자보다 굵다
                        PumRow(title: OwnerRecordActionsState.recordMethodLabel, isKey: true) {
                            Text(state.recordMethod).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        }
                        PumRow(title: OwnerRecordActionsState.payrollLabel, isKey: true, isLast: true) {
                            // 15px 600. 확정 전 = 주황(처리 필요)
                            Text(state.payrollStatusText).pumText(.body, weight: .semibold)
                                .foregroundStyle(state.isPayrollConfirmed ? PumColor.textPrimary : PumColor.statusAttention)
                        }
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PumColor.bgApp)
    }

    private var personRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { personInfo; badge }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { personInfo; badge }
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.personAccessibilityText))
    }

    private var personInfo: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: state.employeeName, colorIndex: state.colorIndex, size: Local.avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                // 18px 700 → headline(17) bold
                Text(state.personTitle).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(state.subtitleText).pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badge: some View { PumBadge(text: OwnerRecordActionsState.unplannedBadgeText, kind: .waiting) }
}

#Preview("1ah") { OwnerRecordActionsView() }
#Preview("1ah · 큰 글자") { OwnerRecordActionsView().dynamicTypeSize(.xxxLarge) }
