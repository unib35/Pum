// 칸 나눠 입력 — 인증번호(2b) · 초대 코드(2d). 2b 화면 전용이던 것을 모았다.
// 실제 입력은 숨은 TextField 하나, 칸은 그 값을 나눠 그린다.
// 칸 높이 60 · 커서 28 · 현재 칸 테두리 2는 목업 실측(토큰 밖 크기라 이름 상수, DEC-005).
import SwiftUI

enum PumCodeFieldStyle {
    /// 칸 높이(목업 약 60) — 큰 글자에서 글자와 함께 커진다
    static let cellHeight: CGFloat = 60
    /// 커서 높이
    static let caretHeight: CGFloat = 28
    /// 현재 칸 파랑 테두리 · 커서 두께
    static let activeBorder: CGFloat = 2
    /// 커서 깜박임 간격(iOS 기본 커서와 비슷하게) — 동작 줄이기면 고정
    static let blinkInterval: Duration = .milliseconds(530)
}

struct PumCodeField: View {
    enum Characters: Sendable {
        /// 숫자만 · 숫자 키패드 · 인증번호 자동 채움
        case digits
        /// 영문 대문자 + 숫자(초대 코드)
        case alphanumeric
    }

    @Binding var code: String
    var length: Int = 6
    var characters: Characters = .digits
    /// VoiceOver 이름 — 「인증번호」 「초대 코드」
    var label: String
    var focus: FocusState<Bool>.Binding
    /// 틀린 코드(15e) — 모든 칸 빨간 테두리. 문구는 화면이 칸 아래에 둔다(색만으로 알리지 않게)
    var isError: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretOn = true
    @ScaledMetric(relativeTo: .title2) private var cellHeight = PumCodeFieldStyle.cellHeight
    @ScaledMetric(relativeTo: .title2) private var caretHeight = PumCodeFieldStyle.caretHeight

    /// 허용 글자만 · 최대 길이까지(영문은 대문자로)
    static func sanitized(_ raw: String, length: Int, characters: Characters) -> String {
        let kept: [Character]
        switch characters {
        case .digits:
            kept = raw.filter { $0.isASCII && $0.isNumber }
        case .alphanumeric:
            kept = raw.uppercased().filter { $0.isASCII && ($0.isNumber || $0.isLetter) }
        }
        return String(kept.prefix(length))
    }

    static func accessibilityText(label: String, count: Int, length: Int) -> String {
        "\(label), \(length)자리 중 \(count)자리 입력됨"
    }

    var body: some View {
        HStack(spacing: PumTokens.Space.s6) { // 목업 칸 사이 약 6
            ForEach(0..<length, id: \.self) { i in cell(i) }
        }
        .overlay { hiddenInput }
        .contentShape(Rectangle())
        .onTapGesture { focus.wrappedValue = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.accessibilityText(label: label, count: code.count, length: length)))
        .accessibilityValue(Text(isError ? "코드가 맞지 않음" : "")) // 칸에 머물러도 틀림을 알 수 있게(색만으로 알리지 않기)
        .accessibilityHint(Text("두 번 탭하면 입력해요"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { focus.wrappedValue = true }
        .task(id: reduceMotion) { await blink() }
    }

    private var activeIndex: Int? { code.count < length ? code.count : nil }

    private func character(at i: Int) -> String {
        guard i < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: i)])
    }

    private func cell(_ i: Int) -> some View {
        let isActive = focus.wrappedValue && activeIndex == i && !isError
        let radius = PumTokens.Radius.lg
        return ZStack {
            // 목업 26px 700 → title2(24px 700) 근사(26 단계 없음)
            Text(character(at: i))
                .pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.5)
            if isActive {
                Rectangle().fill(PumColor.accent)
                    .frame(width: PumCodeFieldStyle.activeBorder, height: caretHeight)
                    .opacity(caretOn ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cellHeight) // 한 줄 유지: 폭은 나눠 갖고 높이만 커진다
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(isError ? PumColor.statusDanger : (isActive ? PumColor.accent : PumColor.borderHairline),
                              lineWidth: isError || isActive ? PumCodeFieldStyle.activeBorder : 1)
        }
    }

    @ViewBuilder private var hiddenInput: some View {
        let field = TextField("", text: Binding(
            get: { code },
            set: { code = Self.sanitized($0, length: length, characters: characters) }
        ))
        .focused(focus)
        .foregroundStyle(.clear) // 입력한 글자가 첫 칸 뒤로 비치지 않게
        .tint(.clear)
        .opacity(0.011) // 눈에는 안 보이고 입력만 받는다
        .accessibilityHidden(true)
        .allowsHitTesting(false)

        switch characters {
        case .digits:
            field.keyboardType(.numberPad).textContentType(.oneTimeCode)
        case .alphanumeric:
            field.keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
        }
    }

    // 커서 깜박임(동작 줄이기면 고정)
    private func blink() async {
        caretOn = true
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: PumCodeFieldStyle.blinkInterval)
            if Task.isCancelled { return }
            caretOn.toggle()
        }
    }
}
