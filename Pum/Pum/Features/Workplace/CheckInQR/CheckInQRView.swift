// UI-IOS-10m · REQ-020 — 사장님 「출근 QR」: QR → 새로 만들기 · 스캔 기록 → 안내 → 인쇄용 PDF 저장. 탭 바 없음(하위 화면).
// 「QR 새로 만들기」는 기존 QR을 바로 못 쓰게 하는 일인데 확인 창 원문이 없어 클로저만 부른다(결정 필요).
// PDF 저장은 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다. 크기(A4 · A5 · 스티커) 고르기 화면 원문 없음 — 클로저만.
import SwiftUI

struct CheckInQRView: View {
    var state: CheckInQRState
    var onBack: () -> Void
    var onRegenerate: () -> Void
    var onOpenScanLog: () -> Void
    /// 인쇄용 PDF 저장. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSavePDF: (_ done: @escaping (Bool) -> Void) -> Void

    @State private var lock = CheckInQRSaveLock()
    @State private var qrImage: CGImage?

    init(state: CheckInQRState = .sample,
         onBack: @escaping () -> Void = {},
         onRegenerate: @escaping () -> Void = {},
         onOpenScanLog: @escaping () -> Void = {},
         onSavePDF: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onRegenerate = onRegenerate
        self.onOpenScanLog = onOpenScanLog
        self.onSavePDF = onSavePDF
        _qrImage = State(initialValue: CheckInQRImage.make(token: state.token))
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// QR 흰 네모 한 변 — 원문 약 200 (글자가 커져도 그대로)
    private let qrBox: CGFloat = 200
    /// QR 그림 한 변 — 원문 흰 네모 안 약 176
    private let qrSide: CGFloat = 176

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: CheckInQRState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(spacing: PumTokens.Space.s10) {
                    qrCard
                    actionCard
                    Text(CheckInQRState.guide)
                        .pumText(.caption)
                        .foregroundStyle(PumColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .padding(.top, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .onChange(of: state.token) { _, token in qrImage = CheckInQRImage.make(token: token) }
    }

    // MARK: QR 카드

    private var qrCard: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s4) {
                qrBoxView
                    .padding(.bottom, PumTokens.Space.s10)
                Text(state.workplaceName)
                    .pumText(.headline, weight: .bold) // 원문 17px 700
                    .foregroundStyle(PumColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(state.subtitle)
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.vertical, PumTokens.Space.s20)
        }
    }

    private var qrBoxView: some View {
        let shape = RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous)
        return ZStack {
            if let qrImage {
                Image(decorative: qrImage, scale: 1)
                    .resizable()
                    .interpolation(.none) // 픽셀이 흐려지지 않게
                    .frame(width: qrSide, height: qrSide)
            } else {
                // 불러오는 중 — 원문 없음. 같은 크기 회색 칸
                RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                    .fill(PumColor.surfaceFill)
                    .frame(width: qrSide, height: qrSide)
            }
        }
        .frame(width: qrBox, height: qrBox)
        .background(PumColor.surfaceCard, in: shape)
        .pumRing(.hairline, cornerRadius: PumTokens.Radius.xl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.qrAccessibilityLabel)) // 토큰은 읽지 않는다
        .accessibilityAddTraits(.isImage)
    }

    // MARK: 행 카드

    private var actionCard: some View {
        PumCard {
            VStack(spacing: 0) {
                row(label: state.regenerateAccessibilityLabel, isLast: false, action: onRegenerate) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(CheckInQRState.regenerateTitle)
                            .font(PumTextStyle.body.font) // 원문 15px 600
                            .fontWeight(.semibold)
                            .tracking(PumTokens.Tracking.body)
                            .foregroundStyle(PumColor.textPrimary)
                        Text(CheckInQRState.regenerateSubtitle)
                            .pumText(.caption)
                            .foregroundStyle(PumColor.textSecondary)
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                row(label: state.scanLogAccessibilityLabel, isLast: true, action: onOpenScanLog) {
                    HStack(spacing: PumTokens.Space.s12) {
                        Text(CheckInQRState.scanLogTitle)
                            .font(PumTextStyle.body.font) // 원문 15px 400
                            .fontWeight(.regular)
                            .tracking(PumTokens.Tracking.body)
                            .foregroundStyle(PumTokens.ColorToken.gray800)
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(state.scanCountText)
                            .font(PumTextStyle.body.font) // 원문 15px 600
                            .fontWeight(.semibold)
                            .tracking(PumTokens.Tracking.body)
                            .foregroundStyle(PumColor.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    /// 공통 후보 — 안쪽 구성을 받는 › 이동 행(공통 PumRow는 굵은 제목 + 회색 부제 + 값 조합을 못 해 화면 전용).
    private func row<C: View>(label: String, isLast: Bool, action: @escaping () -> Void,
                              @ViewBuilder content: () -> C) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                content()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
    }

    // MARK: 바닥

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: CheckInQRState.saveTitle, kind: .primary, isLoading: lock.isSaving,
                      loadingTitle: CheckInQRState.savingTitle, action: save)
            Text(CheckInQRState.sizeHint)
                .pumText(.caption)
                .foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s8)
        .background(PumColor.bgApp)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func save() {
        guard lock.begin() else { return }
        onSavePDF { success in lock.finish(success: success) }
    }
}

#Preview("10m") { CheckInQRView(state: .sample) }
#Preview("10m · 불러오는 중") { CheckInQRView(state: .loading) }
#Preview("10m · 큰 글자") { CheckInQRView(state: .sample).dynamicTypeSize(.xxxLarge) }
