# Environment Audit — Pum

- 진단일: 2026-10-11
- 방식: 읽기 전용 진단 (설치·설정 변경 없음)
- 진단 도구: Claude Code 2.1.296

## 1. 시스템·도구

| 항목 | 결과 | 비고 |
|---|---|---|
| OS | macOS 26.5 (25F71), arm64 | |
| Git | 2.40.1 | 2023년 버전, 업그레이드 권장(선택) |
| gh | 2.80.0, 계정 `unib35` 로그인 | scopes: repo, workflow, gist, read:org |
| Claude Code | 2.1.296 native, 자동 업데이트(latest) | `claude doctor`: 문제 없음 |
| Node / npm / pnpm | v26.5.0 / 11.17.0 / 10.17.1 | yarn·bun·deno 없음 |
| Python | python3 3.13.7 | ⚠ pip3가 python3.11을 가리킴(버전 불일치) |
| 기타 | rustc 1.94.0, OpenJDK 24.0.2, Docker 28.3.2, Homebrew 7.0.7 | go·uv 없음 |

## 2. 저장소 상태

| 항목 | 결과 |
|---|---|
| 디렉터리 | 진단 시점에 비어 있음 |
| Git | 진단 후 `git init` 실행 (2026-10-11). 기본 브랜치 `main`. 첫 커밋에 이 문서 포함 |
| remote | GitHub `unib35/Pum` (public) |
| 스택·CI·테스트 | 없음 (판단할 코드 없음) |
| 프로젝트 MCP(`.mcp.json`)·`CLAUDE.md`·`.claude/` | 없음 |

## 3. Claude Code 기능 (2.1.296 기준)

| 기능 | 상태 | 근거 |
|---|---|---|
| 모델 alias | `fable`, `opus`, `sonnet` | `claude --help`의 `--model` 설명. 사용자 기본값 `model: opus` |
| Subagents | 사용 가능 | `--agents` 플래그, `claude agents` 명령, 세션 Agent 도구. 사용자 정의 에이전트 없음 |
| Skills | 사용 가능 | 플러그인 document-skills, example-skills, swift-lsp, claude-dashboard와 `~/.claude/skills/synced` |
| Hooks | 사용 중(전역) | 10개 이벤트가 모두 외부 hook 스크립트 호출 |
| Worktree | 사용 가능 | `-w/--worktree`, `--tmux` 플래그 있음. 저장소·첫 커밋 준비 완료 |
| Agent Teams | 미검증 | help에 직접적인 플래그 없음. 관련 환경변수 미설정. `TeammateIdle` 훅 등록만 확인 |
| MCP | claude.ai 커넥터 4개 연결 | Claude Docs, Gmail, Google Drive, Google Calendar. 로컬 `mcpServers` 없음 |

## 4. 위험·주의 사항

1. **권한**: `skipDangerousModePermissionPrompt: true`이고 bypass 모드를 쓰고 있음. 파괴적 변경을 확인하는 절차가 도구로 강제되지 않고 지침에만 의존함.
2. **전역 autoMode 설정**: `autoMode.environment`에 다른 로컬 저장소 경로가 신뢰 저장소로 기록되어 있음. Pum과 관계없는 설정이 전역에 남아 있음.
3. **외부 Hook**: 모든 도구 호출이 외부 hook 스크립트를 거침. 스크립트 내용은 검토하지 않음.
4. **Python**: pip3와 python3의 버전 불일치로 다른 인터프리터에 패키지가 설치될 수 있음. `python3 -m pip` 사용 권장.

## 5. 설치·조치 권장 (모두 무료)

| 항목 | 필요성 | 방법 | 상태 |
|---|---|---|---|
| Git 저장소 초기화 | 필수 | `git init` | ✅ 완료 |
| Python 패키지 관리 | 권장 | `python3 -m pip` 또는 `brew install uv` | 미실행 |
| Git 업그레이드 | 선택 | `brew install git` | 미실행 |
| 스택별 도구 | 스택 확정 후 | — | 대기 |

## 6. 사용자 결정 필요

- ~~GitHub 원격 저장소 생성 여부와 공개 범위~~ → public으로 결정 (2026-10-11)
- ~~bypass 권한 모드 유지 여부~~ → 유지로 결정 (2026-10-11)
- 전역 `autoMode.environment`의 다른 저장소 설정 정리 여부
- Agent Teams 사용 여부 (사용하려면 공식 문서로 활성화 방법 확인)
