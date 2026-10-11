# 병렬 개발 정책 — worktree · 소유 디렉터리 · 통합

에이전트 역할 · 모델은 `docs/conventions/agents.md`, Git 규칙은 `docs/conventions/git.md`.

## 한도

- 병렬 구현 에이전트: **2개로 시작.** 파일럿에서 충돌 · 재작업 · 시뮬레이터 문제가 없을 때만 **최대 3개**.
- 오케스트레이터(메인 세션)는 구현을 맡지 않고 통합 · 검증만 한다.
- 검증이 덜 된 상태(차단 · 재작업이 남음)에서는 병렬 수를 늘리지 않는다.

## 소유 디렉터리

한 작업 = 이슈 하나 = 소유 디렉터리 하나. 에이전트는 자기 소유 디렉터리 안의 파일만 만들고 고친다.

| 영역 | 경로 | 담당 |
|---|---|---|
| 화면 · 기능 | `Pum/Pum/Features/<도메인>/<화면>/` (예: `Features/Attendance/ClockIn/`) | 그 이슈의 ui-implementer |
| 화면 테스트 | `Pum/PumTests/Features/<도메인>/<화면>Tests.swift` | 그 이슈의 ui-implementer |
| 도메인 이름 | `attendance` · `schedule` · `payroll` · `comms` · `org` · `account` · `personal` · `contract` (code.md) | — |

**공통 파일 — 오케스트레이터 한 명만 고친다(단일 담당).** 에이전트가 필요하면 보고에 「공통 변경 요청」으로 적고, 오케스트레이터가 별도 커밋으로 먼저 `main`에 넣은 뒤 다음 작업을 맡긴다.

| 공통 파일 | 이유 |
|---|---|
| `Pum/Pum/DesignSystem/**`(토큰 생성물 포함) · `packages/**` | 모든 화면이 쓴다 |
| `Pum/Pum.xcodeproj/**` · `PumApp.swift` · `ContentView.swift` · 내비게이션 · 탭 | 앱 구조 |
| `Pum/Pum/Core/**` · `Assets.xcassets` · `Resources/**` · 문자열 카탈로그 | 공유 데이터 · 리소스 |
| `docs/**` · `.claude/**` · `.github/**` · `AGENTS.md` · `CLAUDE.md` · `README.md` · `.gitignore` | 규칙 · 설정 |

- Xcode 프로젝트가 폴더 동기화 방식이라 `Features/` 아래에 파일을 추가해도 `project.pbxproj`가 바뀌지 않는다(2026-10-12 worktree에서 빌드로 확인). 그래서 화면 작업끼리 프로젝트 파일 충돌이 없다. 타깃 설정 · 패키지 추가는 공통 변경이다.
- 같은 공통 파일을 고쳐야 하는 작업 두 개는 **순차 처리**한다.

## worktree · 브랜치

- worktree마다 브랜치가 다르다(git이 같은 브랜치를 두 worktree에서 쓰는 것을 막는다 — 확인함).
- `main`에서 직접 작업하지 않는다. 에이전트는 push · 병합하지 않는다.
- 에이전트 worktree: `ui-implementer`의 `isolation: worktree`가 `.claude/worktrees/agent-<id>`(브랜치 `worktree-agent-<id>`)를 원격 `main` 기준으로 만든다.
- 사람이 직접 띄울 때(안전한 명령):
  ```sh
  git fetch origin && git switch main && git pull --ff-only     # main 최신 · 미커밋 변경 없음 확인
  git worktree add .claude/worktrees/12-clock-in -b feat/12-clock-in origin/main
  # 또는 Claude Code로: claude -w 12-clock-in   (브랜치 worktree-12-clock-in)
  ```
  만들기 전에 `git status`가 깨끗하고 `git worktree list`에 같은 이름이 없는지 본다. 이미 있는 브랜치를 `-b`로 다시 만들지 않는다.

## 시뮬레이터 · 빌드 산출물

동시에 같은 시뮬레이터를 쓰면 앱 실행 실패 · 검은 화면이 났다(2026-10-12). 작업마다 나눈다.

| 누가 | `PUM_SIM` |
|---|---|
| 오케스트레이터 · 통합 테스트 | `iPhone 17 Pro Max` (다른 세션의 `verify.sh` 기본값이 `iPhone 17`이라 겹쳐서 테스트 번들 오류가 났다, 2026-10-12) |
| 에이전트 1 | `iPhone Air` |
| 에이전트 2 | `iPhone 17e` |
| 에이전트 3(허용 시) | `iPhone 17` (다른 세션이 쓰지 않을 때만) |

DerivedData는 worktree 경로마다 따로 생긴다(충돌 없음). 디스크가 쌓이면 정리 단계에서 지운다.

## 통합 순서

1. 공통 변경이 있으면 먼저: 오케스트레이터가 별도 이슈 · PR로 `main`에 병합.
2. 화면 작업은 **의존이 적은 것부터, 한 번에 하나씩** `main`에 병합한다.
3. 각 작업마다:
   1. 에이전트 보고 확인 → diff가 소유 디렉터리 안인지 확인(`git diff --stat origin/main...<branch>`)
   2. 이슈 브랜치로 옮김: `git branch feat/<issue>-<slug> worktree-agent-<id>`
   3. 최신 `main` 위로 올림: `git switch feat/… && git merge origin/main` (공유 브랜치는 rebase · force 금지)
   4. 검증: `verify.sh ios` + 디자인 비교 + `qa-reviewer` 리뷰
   5. PR → CI 통과 확인 → squash 병합
4. 다음 작업은 방금 병합된 `main`을 다시 받아 3번을 반복한다.

## 충돌 처리

- 소유 디렉터리 규칙을 지켰다면 충돌은 공통 파일에서만 난다 → 규칙 위반으로 보고, 공통 변경을 따로 빼서 먼저 병합한 뒤 다시 합친다.
- 충돌이 나면 바로 `git merge --abort`로 되돌리고(확인함) 원인 작업을 순차 처리로 돌린다. 충돌을 AI가 임의로 풀어 디자인 · 로직을 바꾸지 않는다.
- 같은 화면을 두 작업이 건드리면 나중 작업을 취소하고 다시 맡긴다.

## 병합 후 테스트

`main`에서 `verify.sh ios tokens claude` 전체를 다시 돌리고(PR CI는 iOS를 돌리지 않음) 결과를 PR · 이슈에 남긴다. 실패하면 다음 병합을 멈춘다.

## 정리

```sh
git worktree list
git worktree remove .claude/worktrees/<name>      # 변경이 남아 있으면 실패 — 먼저 회수했는지 확인
git worktree prune
git branch -d worktree-agent-<id>                  # 병합된 것만 -d (강제 -D는 로컬 시험 브랜치에만)
```

에이전트 worktree는 변경이 없으면 자동 삭제된다. 변경이 남은 것은 정기 정리로 지워질 수 있으니 회수를 미루지 않는다.

## 시험 기록 (2026-10-12, 로컬 전용 브랜치 · 원격 push 없음)

| 단계 | 명령 | 결과 |
|---|---|---|
| 시험 통합 브랜치 | `git branch drill/integration main` | OK |
| worktree 2개 | `git worktree add <dir> -b drill/a-… drill/integration` ×2 | OK, 서로 다른 브랜치 |
| 같은 브랜치 중복 | `git worktree add <dir> drill/a-…` | 거부됨 `already checked out` |
| 소유 디렉터리에만 커밋 | A: `Features/Attendance/ClockIn/`, B: `Features/Payroll/Payslip/` | OK |
| 순서 통합 | `merge --no-ff A` → `merge --no-ff B` | 충돌 없음 |
| 공통 파일 충돌 | 두 브랜치가 `README.md` 수정 → 순서 병합 | 두 번째에서 CONFLICT → `merge --abort`로 원상복구 |
| worktree 안 iOS 빌드 | `xcodebuild … iPhone 17e -derivedDataPath <별도> build` | BUILD SUCCEEDED 29초, 새 파일 자동 포함 · pbxproj 변경 없음 |
| 정리 | `worktree remove` ×2 · `prune` · `branch -D drill/*` | OK, `main`(f5f6eba) 그대로 |

## Agent Teams

공식 문서 기준: 실험 기능 · 기본 꺼짐(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), 대화형 세션 전용(`-p`에서는 팀원이 생기지 않음), 세션당 팀 하나, 중첩 불가, `/resume` · `/rewind`가 팀원을 복원하지 않음, 작업 상태 지연, 팀원별 권한 모드 지정 불가, 토큰 비용이 크게 늘어남. 최소 버전은 문서에 없다(현재 Claude Code 2.1.296). **쓰지 않고 Subagents + worktree를 유지한다.** 쓰려면 별도 시험과 승인 후.
