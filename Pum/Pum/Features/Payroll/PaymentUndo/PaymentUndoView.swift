// UI-IOS-21a · 21b · REQ-076 · DEC-003 — 지급 화면에서 「지급 완료」를 되돌린다. 탭 바 없음.
// 시트는 서버 값(undoTarget)이 있을 때만 열린다. 되돌리기는 한 번만 — 처리 중은 그 버튼에만, 성공 뒤엔 잠근 채.
import SwiftUI

struct PaymentUndoView: View {
    var state: PaymentUndoState = .sample
    var startsWithSheetOpen = false
    var onBack: () -> Void = {}
    /// 「지급 완료」 행 — 호출자가 되돌릴 대상 정보(undoTarget)를 채워 다시 그리게 한다
    var onRequestUndo: (_ id: String) -> Void = { _ in }
    /// 「지급 대기로 되돌리기」 — 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패.
    var onUndo: (_ id: String, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }

    @State private var sheetOpen: Bool
    @State private var pendingID: String?
    @State private var lock = PaymentUndoLock()
    @State private var toast: String?
    @ScaledMetric(relativeTo: .body) private var avatarSize = PumLayout.avatar - PumTokens.Space.s2 // 원문 34

    init(state: PaymentUndoState = .sample, startsWithSheetOpen: Bool = false,
         onBack: @escaping () -> Void = {},
         onRequestUndo: @escaping (_ id: String) -> Void = { _ in },
         onUndo: @escaping (_ id: String, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.startsWithSheetOpen = startsWithSheetOpen
        self.onBack = onBack
        self.onRequestUndo = onRequestUndo
        self.onUndo = onUndo
        _sheetOpen = State(initialValue: startsWithSheetOpen && state.undoTarget != nil)
        _toast = State(initialValue: state.toastText)
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    titleBlock
                    payCard
                    if !state.activities.isEmpty { activityCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .pumToast($toast) // 서버가 준 문구가 있을 때만 · 3초 · 알림으로 읽음 · 동작 줄이기는 공통 규칙
        .pumBottomSheet(isPresented: $sheetOpen, onDismiss: dismissed) {
            if let target = state.undoTarget {
                PaymentUndoSheet(target: target, lock: lock, onCancel: cancel, onUndo: { undo(target) })
            }
        }
        .onChange(of: state.undoTarget) { _, new in
            if let new, pendingID == new.id { pendingID = nil; sheetOpen = true }
            if new == nil { sheetOpen = false }
        }
        .onChange(of: state.toastText) { _, new in toast = new }
    }

    // MARK: 위

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s8) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(PaymentUndoState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(PaymentUndoState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.monthText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(PaymentUndoState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 26px 700 → 24px 근사
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 지급 카드

    private var payCard: some View {
        PumCard {
            HStack {
                Text(state.countText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 15px 700
                Spacer(minLength: PumTokens.Space.s8)
                Text(state.amountHeader).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.top, PumTokens.Space.s14)
            .padding(.bottom, PumTokens.Space.s4)
            .accessibilityHidden(true) // 행마다 읽기 문구가 있다
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { index, person in
                if index > 0 { divider }
                row(person)
            }
        }
    }

    @ViewBuilder private func row(_ person: PaymentUndoState.Row) -> some View {
        if person.isPaid {
            // 지급 완료 행 전체가 버튼 — 누르면 되돌릴지 묻는다
            Button { request(person.id) } label: { rowContent(person) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(person.spokenText))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(named: Text(PaymentUndoState.undoActionName)) { request(person.id) }
        } else {
            rowContent(person)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(person.spokenText))
        }
    }

    private func rowContent(_ person: PaymentUndoState.Row) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                PumAvatar(name: person.name, colorIndex: person.colorIndex, size: avatarSize)
                texts(person)
                Text(person.amountText).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                badge(person)
            }
            // 넘치면 금액 · 배지가 이름 아래로
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                PumAvatar(name: person.name, colorIndex: person.colorIndex, size: avatarSize)
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    texts(person)
                    Text(person.amountText).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    badge(person)
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func texts(_ person: PaymentUndoState.Row) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(person.name).pumText(.callout).foregroundStyle(PumColor.textPrimary)
            Text(person.accountText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 보이는 모양만 — 누름은 행 전체가 받는다(배지에 최소 높이를 씌워 행을 키우지 않음)
    private func badge(_ person: PaymentUndoState.Row) -> some View {
        Text(person.statusText).pumText(.caption, weight: .semibold)
            .foregroundStyle(person.isPaid ? PumColor.statusDone : PumTokens.ColorToken.gray700) // 대기 원문 #5B6170
            .padding(.horizontal, PumTokens.Space.s10) // 원문 9
            .padding(.vertical, PumTokens.Space.s4)
            .background(person.isPaid ? PumColor.statusDoneSoft : PumColor.surfaceFill,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            .fixedSize()
    }

    // MARK: 활동 기록(21b)

    private var activityCard: some View {
        PumCard {
            Text(PaymentUndoState.activityTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Space.s14)
                .padding(.bottom, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(state.activities.enumerated()), id: \.element.id) { index, item in
                if index > 0 { divider }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(item.title).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    Text(item.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.spokenText))
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    // MARK: 동작

    private func request(_ id: String) {
        if let target = state.undoTarget, target.id == id { sheetOpen = true } else { pendingID = id }
        onRequestUndo(id)
    }

    private func cancel() {
        guard !lock.isSending else { return }
        sheetOpen = false
        lock.reset()
    }

    private func dismissed() {
        guard !lock.isSending else { return }
        lock.reset()
    }

    /// 한 번만 — 누르는 즉시 잠그고, 성공이면 잠근 채 둔다
    private func undo(_ target: PaymentUndoState.UndoTarget) {
        guard lock.begin() else { return }
        onUndo(target.id) { success in lock.finish(success: success) }
    }
}

#Preview("21a") { PaymentUndoView(state: .sample, startsWithSheetOpen: true) }
#Preview("21a · 큰 글자") { PaymentUndoView(state: .sample, startsWithSheetOpen: true).dynamicTypeSize(.xxxLarge) }
#Preview("21b") { PaymentUndoView(state: .reverted) }
#Preview("21b · 큰 글자") { PaymentUndoView(state: .reverted).dynamicTypeSize(.xxxLarge) }
