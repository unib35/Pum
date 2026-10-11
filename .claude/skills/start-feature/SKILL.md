---
name: start-feature
description: 이슈 하나로 새 작업을 시작할 때 — GitHub 이슈 확인(없으면 초안 작성 후 승인받아 생성), 최신 main에서 feat/fix 브랜치 생성, 관련 REQ·UI·DEC 문서 위치 안내. 사용자가 "작업 시작", "이슈 N 시작", "새 기능 시작"이라고 하거나 /start-feature를 쓸 때 사용.
---

# 작업 시작

입력: `/start-feature <이슈번호> [slug]` 또는 `/start-feature "<할 일 설명>"`(이슈 없음)
출력: 만든 브랜치 이름, 이슈 제목, 이슈에 적힌 REQ · UI · DEC ID와 문서 위치, 다음 할 일. 규칙은 `docs/conventions/git.md`.

1. **이슈 정하기**
   - 번호가 있으면 2로.
   - 설명만 있으면 이슈 초안(제목 · 무엇을 왜 · 관련 REQ/UI/DEC · 완료 기준)을 보여주고 **승인받은 뒤** `gh issue create -R unib35/Pum --title … --body-file …`로 만든다. public 저장소라 만들면 바로 공개된다.
2. **type · slug 정하기** — type은 `feat`(새 기능) · `fix`(버그) · `docs` · `chore`. slug는 영어 소문자 3–5단어(예: `clock-in-qr`). 사용자가 주지 않으면 이슈 제목에서 정하고 보고에 적는다.
3. **실행** — `sh .claude/skills/start-feature/scripts/start.sh <type> <issue> <slug>`
   | 종료 코드 | 뜻 | 할 일 |
   |---|---|---|
   | 0 | 브랜치 생성 | 4로 |
   | 1 | 입력 형식 오류 | 고쳐서 다시 실행 |
   | 2 | 커밋 안 한 변경 있음 | **멈추고** 변경 목록을 보여주며 사용자에게 물음(커밋 · stash · 나중에). 직접 stash · reset · 삭제하지 않는다 |
   | 3 | 이슈 없음 · 닫힘 · gh 실패 | 보고하고 멈춤 |
   | 4 | git 실패(브랜치 중복 · pull 실패 등) | 메시지 그대로 보고. 강제 옵션 쓰지 않음 |
4. **맥락 안내** — 스크립트가 출력한 `refs`의 ID만 문서에서 찾아(`grep -n`) 위치를 알려준다: REQ → `docs/requirements/traceability.md`, UI → `docs/design/screen-index.md`, DEC → `docs/design/decisions.md`. 문서 전체를 읽어 붙이지 않는다. ID가 없으면 "이슈에 연결 ID 없음"이라고 쓰고 추가를 제안한다.
5. **보고** — 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계 순서로 짧게. 마무리는 `/finish-feature`.
