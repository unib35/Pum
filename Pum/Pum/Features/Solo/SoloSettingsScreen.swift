import SwiftData
import SwiftUI

/// 설정 탭(4c MVP판, DEC-032 · DEC-033): 사업장 이름 · 대표 색, 급여일, 상시 5인 이상, 공제 방식.
/// 고르기 화면은 디자인이 없어 시스템 선택(확인 상자 · 휠)을 쓴다.
struct SoloSettingsScreen: View {
    let router: AppRouter
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    @State private var renaming = false
    @State private var newName = ""
    @State private var pickingPayday = false
    @State private var payday = 10
    @State private var pickingFiveOrMore = false
    @State private var pickingDeduction = false
    @State private var failed = false

    var body: some View {
        if let workplace = workplaces.first {
            WorkplaceSettingsView(
                state: Self.state(workplace),
                onBack: nil,
                onOpenInfo: { newName = workplace.name; renaming = true },
                onOpenPayday: { payday = workplace.payday; pickingPayday = true },
                onOpenPremiumRules: { pickingFiveOrMore = true },
                onOpenDeduction: { pickingDeduction = true })
            .id(Self.state(workplace))
            .alert("사업장 이름", isPresented: $renaming) {
                TextField("사업장 이름", text: $newName)
                Button("취소", role: .cancel) {}
                Button("저장") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    save(workplace) { $0.name = name; $0.initial = String(name.prefix(1)) }
                }
            }
            .confirmationDialog("상시 5인 이상", isPresented: $pickingFiveOrMore, titleVisibility: .visible) {
                Button("예 · 연장 · 야간 · 휴일 가산") { save(workplace) { $0.isFiveOrMore = true } }
                Button("아니요") { save(workplace) { $0.isFiveOrMore = false } }
            }
            .confirmationDialog("공제", isPresented: $pickingDeduction, titleVisibility: .visible) {
                Button("없음") { save(workplace) { $0.deduction = .none } }
                Button("사업소득 3.3%") { save(workplace) { $0.deduction = .business3_3 } }
            }
            .pumBottomSheet(isPresented: $pickingPayday) {
                VStack(spacing: PumTokens.Space.s12) {
                    Text("기본 급여일").pumText(.headline).foregroundStyle(PumColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("기본 급여일", selection: $payday) {
                        ForEach(1...31, id: \.self) { Text("매월 \($0)일").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    PumButton(title: "완료") {
                        save(workplace) { $0.payday = Workplace.clampedPayday(payday) }
                        pickingPayday = false
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.bottom, PumTokens.Space.s12)
            }
            .alert("저장하지 못했어요", isPresented: $failed) { Button("확인", role: .cancel) {} }
        }
    }

    private func save(_ workplace: Workplace, _ change: (Workplace) -> Void) {
        do {
            try SwiftDataWorkplaceRepository(context: context).update(workplace, change)
        } catch {
            failed = true
        }
    }

    static func state(_ workplace: Workplace) -> WorkplaceSettingsState {
        WorkplaceSettingsState(
            workplaceName: workplace.name, workplaceInitial: workplace.initial, workplaceColorIndex: workplace.colorIndex,
            category: "", staffCount: (workplace.employees ?? []).filter { $0.leaveDayKey == nil }.count, address: "",
            checkInMethod: "", overtimePolicy: "", reminderValue: "", storeQRAction: "",
            payday: "매월 \(workplace.payday)일", premiumRules: "", reviewRequestSubtitle: "", reviewRequestOn: false,
            contractTemplate: "", admins: [], isSolo: true,
            fiveOrMoreText: workplace.isFiveOrMore ? "예" : "아니요",
            deductionText: workplace.deduction == .business3_3 ? "3.3%" : "없음")
    }
}
