// UI-IOS-5c · REQ-011 — 사업자 확인: 등록번호 · 대표자 · 개업일 → 국세청 조회(확정). 탭 바 없음.
// 조회 실패 · 휴업/폐업 결과 디자인은 없다(만들지 않음). 비활성 버튼의 이유 문구도 없음(충돌 #30).
// 개업일 선택(날짜 휠) · 사업자등록증 촬영은 디자인 · 연결이 없어 누름 클로저만.
import SwiftUI

struct BusinessVerifyView: View {
    @State private var state: BusinessVerifyState
    var onBack: () -> Void
    var onPickOpenDate: () -> Void
    var onScanCertificate: () -> Void
    /// 조회 요청. 끝나면 done(성공 여부) — 실패(false)일 때만 버튼이 풀린다. 연결 전 기본값은 미전송(false).
    var onSubmit: (BusinessVerifyState, @escaping (Bool) -> Void) -> Void

    private enum Field { case number, name }
    @FocusState private var focus: Field?
    /// 카드 안쪽 좌우 여백(원문 18)
    private let cardPadX = PumTokens.Space.s18
    /// 등록번호 큰 숫자 22px 700 · 자간 넓음(원문 실측 약 +1.3) · 아이콘 칸 36. 공통 후보: 숫자 입력 큰 글자
    private enum Layout {
        static let numberSize: CGFloat = 22
        static let numberTracking: CGFloat = 1.3
        static let iconTile: CGFloat = 36
    }
    @ScaledMetric(relativeTo: .body) private var iconTile = Layout.iconTile

    init(state: BusinessVerifyState = .entry,
         onBack: @escaping () -> Void = {},
         onPickOpenDate: @escaping () -> Void = {},
         onScanCertificate: @escaping () -> Void = {},
         onSubmit: @escaping (BusinessVerifyState, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onPickOpenDate = onPickOpenDate
        self.onScanCertificate = onScanCertificate
        self.onSubmit = onSubmit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                topBar
                heading
                Group { // 확인하는 동안은 입력 잠금(보낸 값과 화면 값이 어긋나지 않게)
                    card
                    scanRow
                }
                .disabled(state.isSubmitting)
                Text("국세청 사업자등록 상태를 조회해 실제 영업 중인 사업자인지 확인해요. 대표자가 아니어도 다음 단계에서 관리 권한을 확인할 수 있어요.")
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s8)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .task { focus = .number }
        // 등록번호 10자리를 다 채우면 대표자명으로
        .onChange(of: state.registrationNumber) { _, new in
            if new.count == 10, focus == .number { focus = .name }
        }
    }

    // 1. 뒤로 · 단계
    private var topBar: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
            Spacer(minLength: PumTokens.Space.s8)
            Text("사업장 인증 2 / 3").pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, PumTokens.Space.s4)
    }

    // 2. 제목
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("사업자 정보를 입력해주세요")
                .pumText(.title2) // 24px 700
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("사업자등록증에 있는 내용 그대로").pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
        }
    }

    // 3. 입력 카드
    private var card: some View {
        PumCard {
            numberField
            divider
            keyValue {
                keyText("대표자명")
            } value: {
                TextField("", text: $state.representative)
                    .focused($focus, equals: .name)
                    .pumText(.body, weight: .semibold) // 15px 600
                    .foregroundStyle(PumColor.textPrimary)
                    .tint(PumColor.accent)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .accessibilityLabel(Text("대표자명"))
            }
            divider
            keyValue {
                keyText("개업일")
            } value: {
                Button(action: onPickOpenDate) {
                    // 비어 있을 때 보일 문구는 디자인에 없어 「선택」만 흐리게 둔다
                    Text(state.openDate.isEmpty ? "선택" : state.openDate)
                        .pumText(.body, weight: .semibold)
                        .foregroundStyle(state.openDate.isEmpty ? PumColor.textTertiary : PumColor.textPrimary)
                        .frame(minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("개업일"))
                .accessibilityValue(Text(state.openDate.isEmpty ? "선택 안 함" : state.openDate))
                .accessibilityHint(Text("날짜를 골라요"))
            }
        }
    }

    // 큰 등록번호 입력 — 숫자 키패드 · 숫자만 10자리 · 3-2-5 하이픈 자동
    private var numberField: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text("사업자등록번호").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary) // 원문 12px 600 → 13 근사
                .accessibilityHidden(true)
            TextField("", text: Binding(
                get: { state.formattedNumber },
                set: { state.registrationNumber = BusinessVerifyState.sanitized($0) }))
                .focused($focus, equals: .number)
                .keyboardType(.numberPad)
                .font(PumFont.font(size: Layout.numberSize, weight: .bold, relativeTo: .title3))
                .monospacedDigit()
                .tracking(Layout.numberTracking)
                .foregroundStyle(PumColor.textPrimary)
                .tint(PumColor.accent) // 파랑 커서
                .frame(minHeight: PumTokens.Size.tapMin)
                .accessibilityLabel(Text("사업자등록번호"))
                .accessibilityValue(Text(state.numberAccessibilityValue)) // 하이픈 없이 숫자 하나씩
        }
        .padding(.horizontal, cardPadX)
        .padding(.vertical, PumTokens.Space.s12)
    }

    // 4. 사업자등록증 촬영 행
    private var scanRow: some View {
        Button(action: onScanCertificate) {
            HStack(spacing: PumTokens.Space.s12) {
                Image(systemName: "photo")
                    .font(.system(size: PumLayout.navIcon, weight: .regular))
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(width: iconTile, height: iconTile)
                    .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text("사업자등록증 촬영으로 자동 입력").pumText(.callout).foregroundStyle(PumColor.textPrimary) // 14px 600
                    Text("사진은 확인 후 저장되지 않아요").pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px 400
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Space.s14)
            .padding(.vertical, PumTokens.Space.s12)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
            .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // 5. 사업자 확인(키보드 위에 붙는다)
    private var actions: some View {
        PumButton(title: "사업자 확인", kind: .primary, isLoading: state.isSubmitting, loadingTitle: "확인하는 중") { submit() }
            .disabled(!state.isReady)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    private func submit() {
        guard state.canSubmit else { return } // 한 번만
        state.isSubmitting = true
        onSubmit(state) { success in
            // 실패일 때만 풀린다(성공이면 다음 화면으로 넘어간다)
            if !success { state.isSubmitting = false }
        }
    }

    // MARK: 조각
    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, cardPadX)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
            .accessibilityHidden(true)
    }

    /// 키 – 값. 넘치면 세로로(큰 글자)
    private func keyValue<K: View, V: View>(@ViewBuilder key: () -> K, @ViewBuilder value: () -> V) -> some View {
        let k = key(), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { k; v.frame(maxWidth: .infinity, alignment: .trailing) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { k; v.frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding(.horizontal, cardPadX)
        .padding(.vertical, PumTokens.Space.s6)
        .frame(minHeight: PumTokens.Size.tapMin)
    }
}

#Preview("5c") { BusinessVerifyView(state: .sample) }
#Preview("5c · 빈 값") { BusinessVerifyView() }
#Preview("5c · 큰 글자") { BusinessVerifyView(state: .sample).dynamicTypeSize(.xxxLarge) }
