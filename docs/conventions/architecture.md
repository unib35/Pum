# 아키텍처

이 프로젝트는 **Feature-based Lightweight Clean Architecture**를 쓴다(2026-10-13 사용자 지정). TCA는 쓰지 않는다.

```text
SwiftUI View
    ↓
ViewModel
    ↓
UseCase
    ↓
Repository
    ↓
API / Database
```

| 구성 | 맡는 일 |
|---|---|
| MVVM | UI와 화면 상태 분리 |
| UseCase | 근태 · 급여 등 비즈니스 로직 |
| Repository | 서버 · DB 데이터 접근 추상화 |
| DI | 의존성 주입 |
| Router | SwiftUI 내비게이션 관리 |
| State Machine | 근태 · 급여 상태 전이 |

최종 구성: **Feature-based Lightweight Clean Architecture + MVVM + UseCase + Repository + DI + Router + Domain State Machine**

## 폴더

기술 계층보다 **기능(Feature) 중심**으로 나눈다.

```text
Features/
├── Auth
├── Workplace
├── Employee
├── Schedule
├── Attendance
├── Payroll
└── Settings
```

지금 저장소의 `Pum/Pum/Features/`는 Account · Attendance · Comms · Contract · Home · Onboarding · Payroll · Schedule · Staff · Workplace 10개다. 위 이름(Auth · Employee · Settings)과 맞출지는 아직 정하지 않았다 — 정해지기 전에는 폴더를 옮기지 않는다.

## 내비게이션

화면 이동은 **Router 패턴**을 쓴다. View는 내비게이션 구조를 직접 다루지 않고 Router에 목적지를 요청한다.

```text
View
  └── router.navigate(.attendance(.clockIn))
                ↓
             AppRouter
                ↓
         NavigationStack
```

기능마다 Route를 나눈다.

```text
AppRoute (Pum/Pum/App/AppRoute.swift)
├── AttendanceRoute (Features/Attendance/AttendanceRoute.swift)
├── PayrollRoute
├── StaffRoute
└── …
```

- `AppRouter`(`Pum/Pum/App/AppRouter.swift`): 탭마다 쌓인 화면을 따로 기억하고 `navigate` · `back` · `backToRoot` · `replace` · `select(tab)`을 제공한다.
- 각 `…Route`는 화면 ID(screen-index)를 원시값으로 갖고, `view(router)`에서 화면의 버튼을 다음 목적지에 잇는다. 이은 화면은 `connected`에 넣는다. 잇지 않은 화면은 예시 데이터로 열린다.
- 화면 사이 순서의 기준은 디자인 원문의 흐름 지도(J1–J15)다. 연결 현황은 앱의 「개발용 시작 화면 → 연결 현황」과 `docs/navigation/`에 남긴다.

## 에이전트 오케스트레이션

한 에이전트가 모든 일을 하지 않고 **Orchestrator + 전문 에이전트**로 나눈다.

```text
             Orchestrator
                  │
      ┌───────────┼───────────┐
      ↓           ↓           ↓
 Feature Agent  Domain Agent  Data Agent
      │           │           │
      └───────────┼───────────┘
                  ↓
             Review/Test
```

| 역할 | 맡는 일 |
|---|---|
| Orchestrator | 요구사항 · 기존 코드 분석, 작업 분해, 에이전트 배정, 결과 통합, 최종 검증 |
| Feature Agent | SwiftUI View, ViewModel, 기능 컴포넌트, Router 연결 |
| Domain Agent | 근태 · 급여 계산, UseCase, 비즈니스 규칙, State Machine |
| Data Agent | Repository, API, DB, DTO · 매핑 |
| Review/Test Agent | 아키텍처 위반 확인, 회귀 · 오류 검사, Domain 단위 테스트, 빌드 검증 |

## 에이전트 운영 원칙

- 모든 에이전트는 기존 아키텍처와 코드를 먼저 확인한다.
- 수정 영역이 겹치지 않는 작업만 병렬로 돌린다.
- 기존 패턴을 먼저 재사용한다.
- 새 아키텍처나 라이브러리를 임의로 들이지 않는다.
- View · ViewModel에 급여 · 근태 비즈니스 로직을 넣지 않는다.
- 단순 작업은 빠르고 저렴한 모델, 아키텍처 · 복잡한 Domain · 리뷰는 추론 성능이 높은 모델을 쓴다.

## 지금 상태와의 차이(2026-10-13)

- 화면은 `…State`(서버 값 묶음) + View로 만들어져 있고 ViewModel · UseCase · Repository는 아직 없다. 서버 연결을 시작할 때 이 구조로 들인다.
- 내비게이션은 위 Router 구조로 바꿨다(개발용 시작 화면 → 직원 앱 · 사장님 앱).
