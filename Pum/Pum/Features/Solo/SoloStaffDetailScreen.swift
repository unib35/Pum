import SwiftData
import SwiftUI
import UIKit

/// 20e · 20f — 직원 한 명의 이번 달 근무. 열 때 근로조건대로 이번 달을 채우고, 날짜를 눌러 고친다.
struct SoloStaffDetailScreen: View {
    let router: AppRouter
    let employeeID: PersistentIdentifier
    /// 있으면 그날이 있는 달을 보이고 그날 시트를 연다
    var focusDayKey: Int? = nil
    @Environment(\.modelContext) private var context
    @State private var sheet: DayFixState?
    @State private var requestedDayID: String?
    @State private var pickingOtherDay = false
    @State private var otherDayKey = SeoulDayKey.from(.now)
    @State private var showingPhotos = false

    private var today: Int { SeoulDayKey.from(.now) }
    private var shownMonth: Int { focusDayKey ?? today }

    var body: some View {
        if let employee = context.model(for: employeeID) as? Employee, employee.modelContext != nil {
            AppLessStaffView(
                state: SoloWorkMonth.staffState(employee, year: SeoulDayKey.year(shownMonth), month: SeoulDayKey.month(shownMonth), today: today),
                sheet: sheet,
                requestedDayID: requestedDayID,
                onBack: router.back,
                onEditDay: { id in
                    if let key = SoloWorkMonth.dayKey(id) { sheet = SoloWorkMonth.sheetState(employee, dayKey: key) }
                },
                onFixOtherDay: { pickingOtherDay = true },
                onContract: { if !(employee.contractPhotos ?? []).isEmpty { showingPhotos = true } },
                onInputsChanged: { input in
                    guard let current = sheet else { return }
                    sheet = current.with(preview: SoloWorkMonth.preview(input, employee: employee))
                },
                onCancel: { requestedDayID = nil },
                onSave: { input, done in
                    let ok = save(input, employee: employee)
                    done(ok)
                    if ok { sheet = nil; requestedDayID = nil }
                })
            .task {
                fillShownMonth(employee)
                if let focusDayKey { requestedDayID = SoloWorkMonth.dayID(focusDayKey) }
            }
            .soloDaySheet(isPresented: $pickingOtherDay, title: AppLessStaffState.fixOtherTitle, dayKey: $otherDayKey)
            .onChange(of: pickingOtherDay) { _, open in
                if !open { requestedDayID = SoloWorkMonth.dayID(otherDayKey) }
            }
            .fullScreenCover(isPresented: $showingPhotos) {
                SoloContractPhotos(photos: (employee.contractPhotos ?? []).sorted { $0.createdAt < $1.createdAt })
            }
        }
    }

    private func fillShownMonth(_ employee: Employee) {
        let repository = SwiftDataWorkDayRepository(context: context)
        _ = try? repository.fillScheduled(for: employee, year: SeoulDayKey.year(shownMonth), month: SeoulDayKey.month(shownMonth))
    }

    private func save(_ input: DayFixInput, employee: Employee) -> Bool {
        guard let key = SoloWorkMonth.dayKey(input.dayID) else { return false }
        let kind: WorkDayFixUseCase.Kind
        switch input.kind {
        case .worked:
            guard let start = input.start.flatMap(DayFixState.minutes), let end = input.end.flatMap(DayFixState.minutes)
            else { return false }
            kind = .worked(start: start, end: end, breakMinutes: input.breakMinutes ?? 0)
        case .absent: kind = .absent
        case .dayOff: kind = .dayOff
        }
        let useCase = WorkDayFixUseCase(workDays: SwiftDataWorkDayRepository(context: context))
        return (try? useCase.execute(kind, reason: input.reason, for: employee, on: key)) != nil
    }
}

/// 계약서 사진 보기 — 디자인 없음, 시스템 넘겨 보기
private struct SoloContractPhotos: View {
    let photos: [ContractPhoto]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            ForEach(photos) { photo in
                if let image = UIImage(data: photo.imageData ?? Data()) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .accessibilityLabel(Text("계약서 사진"))
                }
            }
        }
        .tabViewStyle(.page)
        .background(PumColor.surfaceInverse)
        .overlay(alignment: .topTrailing) {
            PumIconButton(systemImage: "xmark", label: "닫기") { dismiss() }
                .foregroundStyle(.white)
                .padding(PumTokens.Space.s8)
        }
    }
}

extension DayFixState {
    func with(preview: DayFixPreview?) -> DayFixState {
        DayFixState(dayID: dayID, dateTitle: dateTitle, plannedText: plannedText, initialKind: initialKind,
                    initialStart: initialStart, initialEnd: initialEnd, initialBreakMinutes: initialBreakMinutes,
                    initialReason: initialReason, preview: preview, isSolo: isSolo)
    }
}
