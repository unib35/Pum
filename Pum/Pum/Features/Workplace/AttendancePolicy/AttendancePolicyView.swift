// UI-IOS-1an · REQ-026 · REQ-093 · REQ-024 · REQ-025 · DEC-004 · DEC-005 — 사업장 설정: 근태 정책(확정). 탭 바 없음.
// 정책 · 기준 선택은 화면 상태 + 변경 클로저(저장 전송은 후속). 퇴근 리마인드는 서버 값 표시만.
import SwiftUI

struct AttendancePolicyView: View {
    var record: AttendancePolicyRecord = .sample
    var onBack: () -> Void = {}
    var onPolicyChange: (OvertimePolicy) -> Void = { _ in }
    var onThresholdChange: (AutoApproveThreshold) -> Void = { _ in }

    @State private var policy: OvertimePolicy
    @State private var threshold: AutoApproveThreshold

    init(record: AttendancePolicyRecord = .sample,
         onBack: @escaping () -> Void = {},
         onPolicyChange: @escaping (OvertimePolicy) -> Void = { _ in },
         onThresholdChange: @escaping (AutoApproveThreshold) -> Void = { _ in }) {
        self.record = record
        self.onBack = onBack
        self.onPolicyChange = onPolicyChange
        self.onThresholdChange = onThresholdChange
        _policy = State(initialValue: record.policy)
        _threshold = State(initialValue: record.threshold)
    }

    /// 안내 상자 강조색 #5B6170 = 토큰 gray700(값 일치)
    private let noteStrongColor = PumTokens.ColorToken.gray700

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근태 정책", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    heading
                    policySection
                    reminderSection
                    note
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
    }

    // 2. 사업장 이름 · 설명
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 원문 제목~설명 4
            Text(record.workplaceName).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 24px 700
            Text(record.subtitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px
        }
    }

    private func sectionHead(_ text: String, suffix: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(text).pumText(.caption, weight: .bold)
            if let suffix { Text(suffix).pumText(.caption, weight: .medium) }
        }
        .foregroundStyle(PumColor.textSecondary)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s4) // 원문 padding 4 4 0
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(suffix == nil ? text : text + ", 직원에게"))
        .accessibilityAddTraits(.isHeader)
    }

    // 3. 연장근무 처리
    private var policySection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            sectionHead("연장근무 처리")
            PumCard {
                let all = OvertimePolicy.allCases
                ForEach(all) { p in
                    policyRow(p, count: all.count)
                        .overlay(alignment: .bottom) {
                            if p != all.last {
                                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                                    .padding(.horizontal, PumTokens.Size.rowPadX)
                            }
                        }
                }
            }
        }
    }

    private func policyRow(_ p: OvertimePolicy, count: Int) -> some View {
        let isOn = policy == p
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                policy = p
                onPolicyChange(p)
            } label: {
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    PumRadioMark(isOn: isOn)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(p.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                        Text(p.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 0
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(p.title.replacingOccurrences(of: " · ", with: ", ")), \(p.detail), \(count)개 중 \((OvertimePolicy.allCases.firstIndex(of: p) ?? 0) + 1)번째"))
            .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)

            if isOn && p.usesThreshold { thresholdPicker }
        }
    }

    /// 자동 인정 기준 — B 선택 시에만. 알약은 B 행 바로 다음에 읽힌다.
    private var thresholdPicker: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 원문 라벨~알약 8
            Text("자동 인정 기준 · 조기퇴근·지각·연장 공통")
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
            let all = AutoApproveThreshold.allCases
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s6) { pills(all) } // 원문 gap 6
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) { pills(all) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 라디오 원 + 간격만큼 안쪽으로(제목 글자 시작에 맞춤)
        .padding(.leading, PumTokens.Size.rowPadX + PumSelectionStyle.markSize + PumTokens.Space.s12)
        .padding(.trailing, PumTokens.Size.rowPadX)
        .padding(.top, -(PumTokens.Space.s14 - PumTokens.Space.s10)) // 원문 설명 아래 10(위 행 아래 padding 14 안으로)
        .padding(.bottom, PumTokens.Space.s14)
        // 알약이 「15분」만 들리지 않게 묶음 이름을 준다
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("자동 인정 기준"))
    }

    @ViewBuilder private func pills(_ all: [AutoApproveThreshold]) -> some View {
        ForEach(Array(all.enumerated()), id: \.element.id) { i, t in
            PumChoicePill(title: t.label, isOn: threshold == t, offStyle: .filled,
                          position: (i, all.count)) {
                threshold = t
                onThresholdChange(t)
            }
        }
    }

    // 4. 퇴근 리마인드 — 서버 값 표시만
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            sectionHead("퇴근 리마인드", suffix: " · 직원에게")
            PumCard {
                let rows = record.reminders
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                    reminderRow(r, isLast: i == rows.count - 1)
                }
            }
        }
    }

    private func reminderRow(_ r: ReminderRow, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                key(r.label)
                Spacer(minLength: 0)
                valueBlock(r).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(r.label)
                valueBlock(r)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.accessibilityText))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    private func valueBlock(_ r: ReminderRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(r.value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
            if let suffix = r.suffix {
                Text(suffix).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .multilineTextAlignment(.leading)
    }

    // 5. 안내 상자
    private var note: some View {
        Text("\(Text(record.noteLead).foregroundStyle(PumColor.textSecondary))\(Text(record.noteStrong).fontWeight(.bold).foregroundStyle(noteStrongColor))\(Text(record.noteTail).foregroundStyle(PumColor.textSecondary))")
            .pumText(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s16) // 원문 padding 12 16
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(record.noteLead + record.noteStrong + record.noteTail))
    }
}

#Preview("1an") { AttendancePolicyView() }
#Preview("1an · 큰 글자") { AttendancePolicyView().dynamicTypeSize(.xxxLarge) }
