# Data — MVP 저장 계층

결정: DEC-030(SwiftData 기기 저장 + iCloud(CloudKit) 백업, 서버 · 로그인 없음) · DEC-028 · DEC-031. 계획: `docs/mvp/README.md` 2단계.

구조: 화면(View) → ViewModel → UseCase → **Repository(프로토콜)** → SwiftData. 화면 · ViewModel은 `Repositories/Repositories.swift`의 프로토콜만 안다. 계산은 `Domain/Payroll`이 하고, 여기는 확정 명세서 스냅숏을 저장만 한다.

## 폴더

| 위치 | 내용 |
|---|---|
| `Models/` | `@Model` 7개 + `SeoulDayKey`(날짜 키 도우미) |
| `Repositories/Repositories.swift` | 프로토콜 4개 · 입력 값(`WorkDayEdit` · `PayslipDraft`) |
| `Repositories/SwiftDataRepositories.swift` | SwiftData 구현 |
| `Schedule/WorkScheduleFiller.swift` | 「근로조건대로 자동 채움」 순수 계산 |
| `PumModelContainer.swift` | `makeShared()`(앱, iCloud 자동) · `makeInMemory()`(테스트 · 미리보기) |

## 모델 관계

```text
Workplace ─┬─< Employee ─┬─< WorkTerms      (근로조건 이력, 적용 시작일별)
           │             ├─< WorkDay        (하루 근무, 직원 · 날짜당 1건)
           │             ├─< ContractPhoto  (계약서 사진, 파일 저장)
           │             └─< Payslip ·····  (nullify: 직원을 지워도 명세서는 남음)
           └─< PayrollMonth ─< Payslip      (월 마감 · 확정 명세서 스냅숏)

─< : 일대다, 부모를 지우면 자식도 지움(cascade)   ····· : 연결만 끊음(nullify)
```

- 사업장을 지우면 직원 · 근무 · 근로조건 · 사진 · 월 마감 · 명세서가 모두 지워진다.
- 직원을 지우면 근로조건 · 근무 · 사진은 지워지고, 확정 명세서는 남는다(`employeeName`에 이름 보존 — 임금대장 보존 목적).

## 값 규칙

- **날짜**: `yyyyMMdd` 정수(`SeoulDayKey`). 기준 시간대 Asia/Seoul. 기기 시간대가 바뀌어도 날짜가 밀리지 않는다. 입사 · 퇴사 · 생년월일 · 적용 시작일 · 근무일 모두 같은 방식.
- **요일**: ISO 번호 1 = 월 … 7 = 일.
- **시각**: 그날 0시부터의 분(09:00 = 540). 자정을 넘기면 끝이 1440보다 크다(22:00–02:00 = 1320–1560). 끝 ≤ 시작으로 넣으면 저장할 때 +1440으로 고친다.
- **돈**: 정수 원(`Int`). 부동소수점 없음.
- **명세서**: 확정한 값(항목 · 실지급액 · 계산 근거 줄)을 그대로 보관한다. 근무를 고쳐도 다시 계산하지 않는다. 같은 달 같은 직원을 다시 확정하면 새 스냅숏으로 바꾼다.
- **자동 채움**: 그날 적용되는 근로조건의 근무 요일이고, 재직 기간 안이며, 아직 기록이 없는 날만 「예정대로」로 만든다. 고친 날 · 결근 · 추가 근무는 건드리지 않는다. 몇 번 실행해도 중복이 생기지 않는다.
- 개인정보(이름 · 휴대폰 · 생년월일)는 로그에 남기지 않는다. 이 계층은 로그를 쓰지 않는다.

## CloudKit 호환 규칙(iCloud 동기화 조건)

| 규칙 | 지키는 방법 |
|---|---|
| 모든 속성은 기본값이 있거나 Optional | 저장 속성마다 `= 기본값` 또는 `?` |
| `@Attribute(.unique)` 금지 | 쓰지 않음. 「직원 · 날짜당 1건」, 「사업장 · 월당 1건」은 Repository가 찾아서 있으면 고친다 |
| 관계는 Optional + inverse | 자식 쪽 `var parent: Parent?`, 부모 쪽 `@Relationship(deleteRule:, inverse:)` `[Child]? = []` (inverse는 한쪽에만 적는다) |
| enum은 원시값으로 저장 | `…Raw: String` 저장 + 계산 속성(`status` · `wageType` · `deduction`) |
| 큰 데이터는 파일로 | `ContractPhoto.imageData`는 `@Attribute(.externalStorage)` |
| 배열은 기본 타입만 | `[Int]` · `[String]`만 사용(명세서 항목은 이름 · 금액 두 배열) |

스키마를 바꿀 때: iCloud에 한 번 올라간 뒤에는 속성 · 모델을 **추가만** 할 수 있다(이름 바꾸기 · 지우기 · 타입 변경 불가). 출시 전 CloudKit 콘솔에서 스키마를 Production에 배포해야 한다.

## 사용자 할 일(1회)

1. Apple 개발자 계정 → Certificates, Identifiers & Profiles → iCloud Containers에서 컨테이너 만들기(예: `iCloud.kr.co.lee.Pum` — 번들 ID 확정 뒤).
2. Xcode → Pum 타깃 → Signing & Capabilities에서
   - **iCloud** 추가 → CloudKit 체크 → 위 컨테이너 선택
   - **Background Modes** 추가 → Remote notifications 체크
3. 출시 전: CloudKit Console에서 Development 스키마를 Production으로 배포.

이 작업에서는 entitlement를 추가하지 않았다. 권한이 없으면 `makeShared()`는 기기에만 저장한다(`cloudKitDatabase: .automatic`).

## 테스트

`Pum/PumTests/Data/` — 메모리 컨테이너로 23건(Swift Testing).
