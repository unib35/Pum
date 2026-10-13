# 화면 연결 현황

앱을 실행해 화면을 이어서 확인하기 위한 연결(Router 패턴 — `docs/conventions/architecture.md`). 기준은 디자인 원문 흐름 지도(J1–J15). 모든 값은 예시 데이터.

## 실행

- 앱을 켜면 **개발용 시작 화면**: 직원 앱으로 보기 · 사장님 앱으로 보기 · 앱 처음부터(2a) · 연결 현황 · 화면 목록 · 컴포넌트 갤러리.
- 앱 안에서 화면 맨 위 가운데 작은 ×를 누르면 시작 화면으로 돌아온다.
- 탭 바를 누르면 탭이 바뀐다(탭마다 쌓인 화면을 따로 기억).
- 확인용 실행 인자: `-PumApp employee|owner -PumPath 1e,10v`(그 화면들이 쌓인 상태로 연다), `-PumScreen 1at`(그 화면 하나를 예시로).

## 기능별

| 기능 | 연결 / 전체 | 상세 |
|---|---|---|
| Account | 16 / 16 | [Account-Comms.md](Account-Comms.md) |
| Attendance | 27 / 28 | [Attendance.md](Attendance.md) |
| Comms | 5 / 5 | [Account-Comms.md](Account-Comms.md) |
| Contract | 8 / 8 | [Onboarding-Contract.md](Onboarding-Contract.md) |
| Home | 11 / 15 | [Home-Workplace.md](Home-Workplace.md) |
| Onboarding | 15 / 15 | [Onboarding-Contract.md](Onboarding-Contract.md) |
| Payroll | 27 / 29 | [Payroll.md](Payroll.md) |
| Schedule | 16 / 18 | [Schedule.md](Schedule.md) |
| Staff | 20 / 20 | [Staff.md](Staff.md) |
| Workplace | 12 / 12 | [Home-Workplace.md](Home-Workplace.md) |
| **합계** | **157 / 166** | |

## 아직 연결 안 된 화면

화면 목록 · 연결 현황에서 예시 데이터로 열어 볼 수 있다.

| ID | 이름 | 기능 |
|---|---|---|
| C13 | 시간 고르기 시트 | Attendance |
| 1ar | 사장님 홈 · 할 일 0건 | Home |
| 21j | 사장님 홈 로딩 | Home |
| 21k | 직원 홈 로딩 | Home |
| 21n | 사장님 홈 불러오기 실패 | Home |
| 1l | 예상 급여 | Payroll |
| 1n | 여러 사업장 | Payroll |
| 1j | 내 스케줄 · 대타 요청 | Schedule |
| 17b | 근무 추가 시트 | Schedule |

## 화면 코드에 버튼 동작이 없어 잇지 못한 곳(화면 수정 필요)

- 1t 사업장 스케줄: 화면의 버튼 동작(클로저)이 하나도 없음 — 9a 필요 인력 등으로 갈 수 없음
- 1aq · 1ar 사장님 홈 인건비 카드 → 1u 급여
- 17e 게시 후 내 스케줄 → 9d, 2k 추가 근무 요청 받음 → 10i
- 1ab 계약서 보관함 → 10q 연차 현황
- 흐름 지도에서만 이어지는 다음 화면(버튼 없음): 21l → 1v, 8b → 8c, 21b → 6n, 19f → 19g, 3b → 3d

## 짐작으로 이은 곳(확인 필요)

기능별 문서의 「판단으로 이은 곳」. 대표:

- 2a 카카오 · Apple · 휴대폰 → 모두 2b, 2c 혼자 → 2e · 코드 → 2d · 사장님 → 2i
- 1aa 서명 완료: 직원이면 6i, 사장님이면 홈 / 1ab 변경 확인 → 19c
- 17e 이번 주 · 대타 요청 → 1j, 2k 수락 · 거절 → 뒤로
- 4a 사장님 모드 시작 → 2i, 6b 대표 넘기기 → 17j, 6w 퇴근 → 1f · 출근 → 1e
- 1r 수정 → 1s, 직접 입력 → 1af, 2l 수정 → 6j, 17i · 17k 수락 → 17j · 6h
- 5a 출근 방식 단계 → 10m

## 앱에 없는 화면(흐름 지도에는 있음)

웹(15b · 20j · 20k · 21h), 알림 · 잠금화면(1aj · 15a · 20i), 지난 안(2m–2q 등) — 연결하지 않는다.
