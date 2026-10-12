// UI-IOS-6i · REQ-061 — 입사 준비(직원): 체크리스트 · 서류 업로드. 탭 바 없음.
// 행은 누르지 않는다(원문에 › 없음). 촬영 · 파일 선택은 밖에서 처리(클로저만).
import SwiftUI

struct OnboardingChecklistView: View {
    let state: OnboardingChecklistState
    var onBack: () -> Void
    var onTakePhoto: () -> Void
    var onPickFile: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var circleSize = Local.stepCircle
    @ScaledMetric(relativeTo: .body) private var barHeight = PumTokens.Space.s8

    init(state: OnboardingChecklistState = .sample,
         onBack: @escaping () -> Void = {},
         onTakePhoto: @escaping () -> Void = {},
         onPickFile: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onTakePhoto = onTakePhoto
        self.onPickFile = onPickFile
    }

    fileprivate enum Local {
        /// 상태 원 지름 — 원문 실측 약 24 (21l과 같은 값)
        static let stepCircle: CGFloat = 24
        static let checkRatio: CGFloat = 0.45
        static let dashLine: CGFloat = 1.5
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    titleBlock
                    PumCard {
                        ForEach(Array(state.steps.enumerated()), id: \.element.id) { index, step in
                            stepRow(step, isLast: index == state.steps.count - 1)
                        }
                    }
                    if let upload = state.upload { uploadBox(upload) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
    }

    // MARK: 머리 · 제목 · 진행 막대

    // 원문: 원형 뒤로 버튼 + 가운데 제목(공통 머리)
    private var backRow: some View {
        PumNavHeader(title: OnboardingChecklistState.backTitle, onBack: onBack)
            .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.workplaceLine).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            heading
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.accessibilityTitle))
                .accessibilityAddTraits(.isHeader)
            bar.padding(.top, PumTokens.Space.s8)
                .accessibilityHidden(true) // 제목이 같은 내용을 읽음
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 「입사 준비 6 / 7」 — 6은 파랑, 「/ 7」은 회색
    private var heading: some View {
        let title = Text(OnboardingChecklistState.title).foregroundStyle(PumColor.textPrimary)
        let done = Text("\(state.doneCount)").foregroundStyle(PumColor.accent)
        let total = Text("/ \(state.totalCount)").foregroundStyle(PumTokens.ColorToken.gray300)
        return Text("\(title) \(done) \(total)")
            .pumText(.title2, weight: .bold)
            .tracking(PumTokens.Tracking.title)
    }

    /// 서버가 준 완료 수 / 전체 수 비율만 그린다
    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                Capsule().fill(PumColor.accent)
                    .frame(width: geo.size.width * state.progressFraction)
            }
            .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: state.progressFraction)
        }
        .frame(height: barHeight)
    }

    // MARK: 단계 행

    private func stepRow(_ step: OnboardingStep, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            statusMark(done: step.isDone)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                if step.isDone {
                    Text(step.title).pumText(.body, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    Text(step.detail).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                } else {
                    Text(step.title).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(step.detail).pumText(.caption).foregroundStyle(PumColor.statusAttention)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.accessibilityText))
    }

    @ViewBuilder
    private func statusMark(done: Bool) -> some View {
        if done {
            Circle().fill(PumColor.surfaceFill)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: circleSize * Local.checkRatio, weight: .bold))
                        .foregroundStyle(PumColor.textPrimary)
                }
                .frame(width: circleSize, height: circleSize)
        } else {
            Text("!")
                .pumText(.footnote, weight: .heavy)
                .foregroundStyle(PumColor.statusAttention)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.statusAttentionSoft, in: Circle())
        }
    }

    // MARK: 서류 올리기 상자

    private func uploadBox(_ upload: OnboardingUploadBox) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(upload.title).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s8) { photoButton; fileButton }
            } else {
                HStack(spacing: PumTokens.Space.s12) { photoButton; fileButton } // 받은 폭 1 : 1
            }
            Text(upload.note).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .padding(PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous)
                .strokeBorder(PumColor.textDisabled,
                              style: StrokeStyle(lineWidth: Local.dashLine,
                                                 dash: [PumTokens.Space.s4, PumTokens.Space.s2]))
        }
    }

    private var photoButton: some View {
        uploadButton(icon: "camera", title: OnboardingChecklistState.takePhotoTitle, action: onTakePhoto)
    }

    private var fileButton: some View {
        uploadButton(icon: "photo", title: OnboardingChecklistState.pickFileTitle, action: onPickFile)
            .accessibilityLabel(Text("앨범 또는 파일")) // 「·」를 「점」으로 읽지 않게
    }

    private func uploadButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s6) {
                Image(systemName: icon).accessibilityHidden(true)
                Text(title)
            }
            .pumText(.callout, weight: .semibold)
            .foregroundStyle(PumColor.textPrimary)
            .padding(.vertical, PumTokens.Space.s12)
            .padding(.horizontal, PumTokens.Space.s8)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.buttonHSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(UploadButtonStyle())
    }
}

/// 흰 바탕 · 가는 외곽선 버튼(누르면 회색 바탕 · M1 .97)
private struct UploadButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let radius = PumTokens.Radius.md
        configuration.label
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(configuration.isPressed ? PumColor.surfaceFill : PumColor.surfaceCard))
            .pumRing(.hairline, cornerRadius: radius)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: configuration.isPressed)
    }
}

#Preview("6i") { OnboardingChecklistView(state: .sample) }
#Preview("6i · 큰 글자") { OnboardingChecklistView(state: .sample).dynamicTypeSize(.accessibility3) }
