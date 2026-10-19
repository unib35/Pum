import PhotosUI
import SwiftData
import SwiftUI

// MVP 직원 탭(DEC-032 · DEC-033): 1ac 목록 → 20b · 20c · 20d 직접 등록. 화면은 확정 디자인 그대로, 값만 저장소에서.

/// 1ac — 저장된 직원
struct SoloStaffListScreen: View {
    let router: AppRouter
    @Environment(SoloRegisterFlow.self) private var flow
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    @Query(sort: \Employee.createdAt) private var employees: [Employee]

    var body: some View {
        StaffListView(roster: roster, onMember: { _ in }, onAdd: {
            flow.reset()
            router.navigate(.solo(.registerBasic))
        })
    }

    private var roster: StaffRoster {
        let workplace = workplaces.first
        let today = SeoulDayKey.from(.now)
        let members = employees
            .filter { $0.workplace?.persistentModelID == workplace?.persistentModelID }
            .filter { $0.leaveDayKey.map { $0 >= today } ?? true }
            .map { Self.member($0, today: today) }
        return StaffRoster(
            workplaceName: workplace?.name ?? "", workplaceInitial: workplace?.initial ?? "",
            headcount: members.count, contractedCount: 0, awaitingCount: 0, invitedCount: 0,
            members: members, isSolo: true)
    }

    static func member(_ employee: Employee, today: Int) -> StaffMember {
        let terms = employee.terms(on: today) ?? employee.terms(on: .max)
        return StaffMember(
            id: "\(employee.persistentModelID)", name: employee.name, colorIndex: employee.colorIndex,
            status: .contracted, daysText: terms.map { SoloFormat.weekdays($0.workWeekdays) },
            startHour: 0, endHour: 0, note: employee.memo.isEmpty ? nil : employee.memo,
            healthCertDaysLeft: nil, healthCertWarning: false, hourlyWage: terms?.amount, showsCallButton: false,
            hoursTextOverride: terms.map { SoloFormat.hours(start: $0.startMinute, end: $0.endMinute) },
            wageUnit: terms?.wageType == .monthly ? "원/월" : "원/h",
            showsStatus: false)
    }
}

/// 20b — 이름 · 휴대폰(선택) · 입사일
struct SoloRegisterBasicScreen: View {
    let router: AppRouter
    @Environment(SoloRegisterFlow.self) private var flow
    @State private var pickingHireDate = false

    var body: some View {
        DirectRegisterBasicView(
            state: DirectRegisterBasicState(name: flow.name, phone: flow.phone, birthDate: "",
                                            startDate: SoloFormat.date(flow.hireDayKey), isSolo: true),
            onBack: router.back,
            onPickStartDate: { pickingHireDate = true },
            onNext: { value, done in
                flow.name = value.name
                flow.phone = value.phone
                done()
                router.navigate(.solo(.registerTerms))
            })
        .soloDaySheet(isPresented: $pickingHireDate, title: DirectRegisterBasicState.startDateTitle,
                      dayKey: Binding(get: { flow.hireDayKey }, set: { flow.hireDayKey = $0 }))
    }
}

/// 20c — 시급 · 월급, 요일, 시간
struct SoloRegisterTermsScreen: View {
    let router: AppRouter
    @Environment(SoloRegisterFlow.self) private var flow
    @State private var editingHours = false

    var body: some View {
        let minimum = MinimumWage.hourly(year: SeoulDayKey.year(flow.hireDayKey))
        DirectRegisterTermsView(
            state: DirectRegisterTermsState(
                hourlyWage: flow.amount, weekdays: flow.weekdays, minimumWage: minimum,
                minimumWageText: "\(SeoulDayKey.year(flow.hireDayKey)) 최저 \(DirectRegisterTermsState.won(minimum))",
                timeRangeText: PumFormat.timeRange(SoloFormat.clock(flow.hours.startMinutes), SoloFormat.clock(flow.hours.endMinutes)),
                breakAndDurationText: SoloFormat.breakAndDuration(
                    start: flow.hours.startMinutes, end: flow.hours.endMinutes, breakMinutes: flow.hours.breakMinutes),
                paydayText: "", deductionText: "", accountValueText: "",
                isSolo: true, isMonthly: flow.isMonthly),
            onBack: router.back,
            onEditHours: { editingHours = true },
            onNext: { value, done in
                flow.amount = value.hourlyWage
                flow.weekdays = Set(value.weekdays)
                flow.isMonthly = value.isMonthly
                done()
                router.navigate(.solo(.registerContract))
            })
        .pumTimeRangeSheet(
            isPresented: $editingHours,
            value: Binding(get: { flow.hours }, set: { flow.hours = $0 }),
            options: PumTimeRangeOptions(showsDate: false, showsRepeat: false, showsEndDate: false))
    }
}

/// 20d — 계약서 사진(선택) → 등록
struct SoloRegisterContractScreen: View {
    let router: AppRouter
    @Environment(SoloRegisterFlow.self) private var flow
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.createdAt) private var workplaces: [Workplace]
    @State private var picking = false
    @State private var picked: [PhotosPickerItem] = []
    @State private var failed = false

    var body: some View {
        DirectRegisterContractView(
            state: DirectRegisterContractState(
                photos: flow.photos.enumerated().map { i, p in .init(id: p.id.uuidString, name: "계약서 \(i + 1)쪽") },
                method: .photo, copyGiven: false, isSolo: true),
            onBack: router.back,
            onAddPhoto: { picking = true },
            onRegister: { _, done in
                if register() {
                    flow.reset()
                    router.backToRoot()
                } else {
                    failed = true
                    done()
                }
            })
        .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            picked = []
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        flow.photos.append(.init(data: data))
                    }
                }
            }
        }
        .alert("저장하지 못했어요", isPresented: $failed) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("잠시 후 다시 눌러 주세요")
        }
    }

    private func register() -> Bool {
        guard let workplace = workplaces.first else { return false }
        let useCase = RegisterEmployeeUseCase(
            employees: SwiftDataEmployeeRepository(context: context),
            workDays: SwiftDataWorkDayRepository(context: context))
        return (try? useCase.execute(flow.registration, in: workplace)) != nil
    }
}

// MARK: - 날짜 고르기(디자인 없음 — 시스템 달력)

extension View {
    func soloDaySheet(isPresented: Binding<Bool>, title: String, dayKey: Binding<Int>) -> some View {
        pumBottomSheet(isPresented: isPresented) {
            SoloDaySheet(title: title, dayKey: dayKey) { isPresented.wrappedValue = false }
        }
    }
}

private struct SoloDaySheet: View {
    let title: String
    @Binding var dayKey: Int
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(title).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            DatePicker(title, selection: Binding(
                get: { SeoulDayKey.date(dayKey) ?? .now },
                set: { dayKey = SeoulDayKey.from($0) }), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.timeZone, SeoulDayKey.timeZone)
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .tint(PumColor.accent)
            PumButton(title: "완료", action: onDone)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s12)
    }
}
