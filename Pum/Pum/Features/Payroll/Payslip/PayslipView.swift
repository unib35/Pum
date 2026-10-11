// UI-IOS-1m · REQ-074 · REQ-078 · REQ-071 · DEC-005 — 급여명세서(지급 완료)
// 먹색 머리 + 흰 본문 한 장. 공제는 빨강, 확정 금액은 초록. 탭 바 없음(하위 화면).
import SwiftUI

struct PayslipView: View {
    var record: PayslipRecord = .sample
    var onBack: () -> Void = {}
    var onPickMonth: () -> Void = {}
    var onShare: () -> Void = {}
    var onSavePDF: () -> Void = {}
    var onKakao: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize

    // 화면 전용 상수(DEC-005: 토큰에 없는 목업 값에 이름을 붙임)
    /// 디자인 1m의 지급 완료 배지 글자색 green-300 #8FD9B0, 바탕은 같은 색 15%
    private let badgeTint = PumTokens.ColorToken.green300
    private let badgeFillOpacity = 0.15
    /// 공제 합계 위 점선 패턴
    private let dashPattern: [CGFloat] = [PumTokens.Space.s4, PumTokens.Space.s4]
    /// 라벨 색 #3A4150 = gray-800
    private let labelColor = PumTokens.ColorToken.gray800

    var body: some View {
        VStack(spacing: 0) {
            navHeader.padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(spacing: PumTokens.Space.s16) {
                    slip
                    PayslipActions(onSavePDF: onSavePDF, onKakao: onKakao, stacked: typeSize.isAccessibilitySize)
                    Text("명세서는 앱에서 계속 보관돼요 · 문의는 사장님께 직접 또는 앱 메시지로")
                        .pumText(.caption, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 내비 헤더 — 가운데 제목에 아래 화살표(월 선택)가 있어 화면 전용으로 만든다

    private var navHeader: some View {
        ZStack {
            Button(action: onPickMonth) {
                HStack(spacing: PumTokens.Space.s4) {
                    Text(record.monthTitle).pumText(.headline).lineLimit(1)
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold)).accessibilityHidden(true)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minHeight: PumTokens.Size.tapMin)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(record.monthTitle))
            .accessibilityHint(Text("월을 바꿔요"))
            .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                Spacer()
                PumIconButton(systemImage: "square.and.arrow.up", label: "공유", action: onShare)
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }

    // MARK: 명세서 카드

    private var slip: some View {
        let r = PumTokens.Radius.lg
        return VStack(spacing: 0) {
            slipHead
            slipBody
        }
        .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        .pumRing(.hairline, cornerRadius: r)
    }

    private var slipHead: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(record.headerCaption).pumText(.caption, weight: .medium)
                        .foregroundStyle(PumColor.textOnInverseSecondary)
                    // 목업 20px 700 = title3
                    Text(record.workplaceName).pumText(.title3).foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: PumTokens.Space.s8)
                statusBadge
            }
            infoCells
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse)
    }

    private var statusBadge: some View {
        Text(record.statusText).pumText(.caption, weight: .semibold)
            .foregroundStyle(badgeTint)
            .padding(.horizontal, PumTokens.Space.s10)
            .padding(.vertical, PumTokens.Space.s4)
            .background(badgeTint.opacity(badgeFillOpacity), in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
    }

    /// 3칸: 좁으면(큰 글자) 세로로
    private var infoCells: some View {
        let cells: [(String, String)] = [("직원", record.employeeName), ("지급일", record.payDateText), ("근무", record.workSummary)]
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    ForEach(cells, id: \.0) { infoCell($0.0, $0.1) }
                }
            } else {
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    ForEach(cells, id: \.0) { infoCell($0.0, $0.1) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textOnInverseSecondary)
            Text(value).pumText(.callout).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var slipBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("지급 항목")
            ForEach(record.earnings) { line($0, deduction: false) }
            dashedDivider
            total("지급 합계", text: record.grossText, color: PumColor.textPrimary, a11y: "지급 합계 \(record.grossText)원")
            sectionTitle("공제 항목").padding(.top, PumTokens.Space.s18)
            ForEach(record.deductions) { line($0, deduction: true) }
            dashedDivider
            total("공제 합계", text: record.deductionTotalText, color: PumColor.statusDanger,
                  a11y: "공제 합계 \(PumFormat.amount(record.deductionTotal))원")
            netBox.padding(.top, PumTokens.Space.s16)
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceCard)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
            .padding(.bottom, PumTokens.Space.s6)
            .accessibilityAddTraits(.isHeader)
    }

    private func line(_ l: PayslipLine, deduction: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
            // 라벨 15px 400 gray-800 + 작은 회색 근거(큰 글자에서는 아래 줄로)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s6) { labelText(l.label); noteText(l.note) }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) { labelText(l.label); noteText(l.note) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(record.amountText(l, deduction: deduction)).pumText(.body, weight: .semibold)
                .foregroundStyle(deduction ? PumColor.statusDanger : PumColor.textPrimary)
        }
        // 누를 수 없는 표시 행이라 44pt 최소 높이를 두지 않는다(디자인 1m 행 간격)
        .padding(.vertical, PumTokens.Space.s6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.accessibilityText(l, deduction: deduction)))
    }

    private func labelText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(labelColor)
    }

    @ViewBuilder private func noteText(_ s: String?) -> some View {
        if let s { Text(s).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary) }
    }

    private var dashedDivider: some View {
        PayslipDashLine()
            .stroke(PumColor.textDisabled, style: StrokeStyle(lineWidth: 1, dash: dashPattern))
            .frame(height: 1)
            .padding(.vertical, PumTokens.Space.s8)
            .accessibilityHidden(true)
    }

    private func total(_ title: String, text: String, color: Color, a11y: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
            Spacer(minLength: PumTokens.Space.s8)
            Text(text).pumText(.callout, weight: .bold).foregroundStyle(color)
        }
        .padding(.vertical, PumTokens.Space.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(a11y))
    }

    private var netBox: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { netLabel; Spacer(minLength: PumTokens.Space.s8); netValue }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { netLabel; netValue }
        }
        .padding(PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("실지급액 \(PumFormat.amount(record.netPay))원"))
    }

    private var netLabel: some View {
        // 목업 15px 700 green-700 = body bold
        Text("실지급액").pumText(.body, weight: .bold).foregroundStyle(PumTokens.ColorToken.green700)
    }

    private var netValue: some View {
        // 확정 금액 = 초록, 목업 24px 700 = title2
        Text(record.netPayText).pumText(.title2).foregroundStyle(PumColor.statusDone)
    }
}

private struct PayslipDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

/// 아래 버튼 2개(1 : 1). 좁으면(큰 글자) 세로로.
private struct PayslipActions: View {
    let onSavePDF: () -> Void
    let onKakao: () -> Void
    let stacked: Bool

    // 디자인 1m 값 #FAE100(카카오 공식 노랑 #FEE500과 다름 — 디자인 결정 필요). 바탕만 이 값, 글자는 먹색.
    private let kakaoYellow = Color(.sRGB, red: 250.0 / 255, green: 225.0 / 255, blue: 0, opacity: 1)
    /// 카카오 로고 자리의 검은 원 지름(로고 에셋 없음 — 원으로 대체)
    private let logoDot: CGFloat = PumTokens.Space.s16

    var body: some View {
        if stacked {
            VStack(spacing: PumTokens.Space.s8) { pdf; kakao }
        } else {
            HStack(spacing: PumTokens.Space.s8) { pdf; kakao }
        }
    }

    private var pdf: some View { PumButton(title: "PDF 저장", kind: .outline, action: onSavePDF) }

    private var kakao: some View {
        Button(action: onKakao) {
            HStack(spacing: PumTokens.Space.s8) {
                Circle().fill(PumColor.textPrimary).frame(width: logoDot, height: logoDot).accessibilityHidden(true)
                Text("카카오톡으로 받기").pumText(.headline).lineLimit(2).minimumScaleFactor(0.8)
            }
            .foregroundStyle(PumColor.textPrimary)
            .padding(.horizontal, PumTokens.Space.s12)
            .frame(maxWidth: .infinity)
            .frame(height: PumTokens.Size.buttonH)
            .background(kakaoYellow, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("1m") { PayslipView() }
#Preview("1m · 큰 글자") { PayslipView().dynamicTypeSize(.accessibility2) }
