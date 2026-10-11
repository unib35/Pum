# 에이전트 오케스트레이션 — 최소 구성

메인 세션 = **오케스트레이터**. 범위 · 의존성 · 모델 · 완료 기준을 정하고, 일을 나눠 맡기고, 결과를 검증 · 통합한다. 에이전트 정의: `.claude/agents/`.

## 역할

| 에이전트 | 모델 | 도구 | 격리 | 맡기는 일 | 맡기지 않는 일 |
|---|---|---|---|---|---|
| 오케스트레이터(메인 세션) | Sonnet 권장(현재 사용자 설정 Opus) | 전체 | 저장소 본체 | 이슈 · 브랜치 · 범위 결정, 공통 파일 수정, 검증 스크립트 실행, 커밋 · push · PR · 병합 | — |
| `ui-implementer` | sonnet | Read · Grep · Glob · Edit · Write · Bash | **worktree** (`.claude/worktrees/agent-<id>`, 브랜치 `worktree-agent-<id>`) | 화면 · 컴포넌트 하나 구현, 지정 시뮬레이터로 `verify.sh ios`, worktree 브랜치에 커밋 | 공통 파일 수정, push · PR · 병합, 디자인 판단 |
| `qa-reviewer` | sonnet | Read · Grep · Glob (읽기 전용) | 없음 | 디자인 · 토큰 · 접근성 · 규칙 · 테스트 관점 독립 리뷰 | 고치기, 명령 실행 |
| `utility` | haiku | Read · Grep · Glob (읽기 전용) | 없음 | 파일 찾기, 문서에서 ID · 값 뽑기, 짧은 요약 | 판단 · 설계 · 명령 실행 |

**읽기 전용은 도구 목록으로 보장한다.** 이 프로젝트의 메인 세션은 bypass 권한 모드라서 에이전트 파일의 `permissionMode`보다 메인 세션 모드가 우선한다(공식 문서). 그래서 `permissionMode`에 기대지 않고 `tools`에서 쓰기 · Bash를 뺐다.

## 모델 라우팅 · Opus 승격

| 일 | 기본 | 승격 |
|---|---|---|
| 화면 구현 · 리뷰 | Sonnet | 아래 조건일 때만 Opus |
| 조회 · 요약 · 목록 | Haiku | 결과가 틀렸거나 판단이 필요하면 Sonnet |
| git · 빌드 · 테스트 · 린트 · 토큰 생성 | **스크립트**(`verify.sh` · `check.sh` · `start.sh` · `npm run`) | AI에 맡기지 않는다 |

Opus로 올리는 조건(하나라도 해당하면 오케스트레이터가 Opus로 직접 하거나 `model: opus`로 일회 호출):
1. 설계 문서끼리 충돌해 해석이 필요한 일(DEC 초안 작성 등 — 결정 자체는 사용자)
2. 같은 작업이 Sonnet으로 **2번 실패**(검증 FAIL 또는 QA 「수정 필요」 반복)
3. 여러 도메인을 가로지르는 구조 변경(상태 머신, 급여 엔진, DB 스키마)
4. 보안 · 돈 · 개인정보가 걸린 코드의 최종 리뷰

승격은 작업 기록에 「승격: 이유」로 남긴다. 승격 없이 끝낼 수 있으면 승격하지 않는다.

## 맡길 때 넘기는 것 (필요한 것만)

```
작업: <이슈 #N · 화면 ID>
원문 요약: <screen-index 행 · 디자인 메모 · 관련 REQ/DEC — 전문을 붙이지 않는다>
소유 디렉터리: <예: Pum/Pum/Features/Attendance/ClockIn/>
쓰면 안 되는 파일: 공통 파일(DesignSystem · xcodeproj · packages · docs · .claude)
시뮬레이터: <PUM_SIM 값 — 작업마다 다르게>
완료 기준: <체크 목록>
```

설계 문서 전체 · 대화 기록을 넘기지 않는다. 에이전트가 더 필요하면 「막힌 것」으로 묻게 한다.

## 돌려받는 것

각 에이전트 파일에 정한 짧은 구조화 보고(상태 · 바꾼 파일 · 검증 · 디자인 차이 · 공통 변경 요청 · 막힌 것). 오케스트레이터는 보고를 믿지 않고 **직접 검증한다**: diff 확인 → `verify.sh` 재실행 → `qa-reviewer` 리뷰.

## worktree 결과 회수

- ui-implementer의 커밋은 `worktree-agent-<id>` 브랜치에 남는다. 오케스트레이터가 보고를 받은 즉시 이슈 브랜치로 옮긴다: `git branch feat/<issue>-<slug> worktree-agent-<id>` → 검증 → push · PR.
- 변경 없는 worktree는 끝나면 자동 삭제된다(시험에서 확인). 변경이 남은 worktree는 정기 정리(`cleanupPeriodDays`)로 지워질 수 있으니 **회수를 미루지 않는다**.
- worktree는 원격 기본 브랜치(`main`) 기준으로 만들어진다(`worktree.baseRef` 기본 `fresh`). 의존하는 작업이 `main`에 병합되기 전에는 그 작업을 맡기지 않는다.

## 시험 호출 (2026-10-12, 각 1회 · 읽기 전용)

`claude -p … --model sonnet --output-format json`으로 새 세션에서 호출. 비용은 API 정가 기준 추정값(`total_cost_usd`).

| 에이전트 | 과제 | 결과 | 실제 모델 | 시간 | 비용(오케스트레이터 포함) |
|---|---|---|---|---|---|
| utility | decisions.md에서 DEC 번호 · 제목 뽑기 | 정확(8개, 줄 근거) | haiku | 10.5초 | $0.082 (haiku $0.0017) |
| qa-reviewer | PumBadge.swift를 C2 · 토큰 기준 리뷰 | 「수정 필요」 — 실제 결함 1건(가로 여백 `9` 토큰 없음) · 낮음 3건 | sonnet | 26.7초 | $0.146 |
| ui-implementer | worktree에서 pwd · 브랜치 · 파일 목록만 | worktree `.claude/worktrees/agent-…`, 브랜치 `worktree-agent-…`, 변경 없음 → 자동 삭제 확인 | sonnet | 12.3초 | $0.106 |

비용 대부분은 세션 시작 시 캐시 쓰기(규칙 · 도구 정의)다. 에이전트 수를 늘리기 전에 이 표에 실제 작업 기록을 쌓고 실패 원인을 본다.

## 확대 규칙

- 병렬 구현 에이전트: 처음 **2개**, 검증 후 최대 **3개**(`docs/conventions/parallel.md`).
- 새 에이전트 종류는 같은 일이 3번 이상 반복되고 기존 에이전트로 부족할 때만 추가한다.
- Agent Teams는 쓰지 않는다(실험 기능 · 기본 꺼짐 · 대화형 세션 전용 · 세션당 팀 하나 · 재개 시 팀원 복원 안 됨). Subagents로 충분하다.

## 기존 설정과 충돌 확인

| 항목 | 결과 |
|---|---|
| 기존 `.claude/agents/` | 없었음 — 새로 만듦 |
| 프로젝트 `.claude/settings.json` (SessionStart hook) | 영향 없음 |
| 사용자 전역 hook(Orca) · bypass 모드 | 에이전트에도 적용된다. 읽기 전용은 도구 목록으로 보장 |
| 스킬(`start-feature` · `finish-feature` · `design-sync`) | 오케스트레이터가 쓴다. 에이전트에게는 맡기지 않는다 |
| 시뮬레이터 | 에이전트마다 `PUM_SIM`을 달리 준다(동시 사용 시 실패 이력) |
