---
name: finish-feature
description: 작업 브랜치를 마무리할 때 — 브랜치 이름 · 커밋 메시지 · 비밀값 검사, 바뀐 영역의 빌드 · 테스트 실행, PR 본문 작성, 승인 후 push와 PR 생성. 사용자가 "작업 끝", "PR 올려줘", "마무리해줘"라고 하거나 /finish-feature를 쓸 때 사용.
---

# 작업 마무리

입력: `/finish-feature` (현재 브랜치) · 선택: `--draft`(초안 PR), `--no-pr`(검사 · 테스트만)
출력: 검사 결과, 실행한 테스트 명령과 결과, PR 링크(또는 만들지 않은 이유). 규칙은 `docs/conventions/git.md`.

1. **사전 검사** — `sh .claude/skills/finish-feature/scripts/check.sh`
   - `FAIL`이 있으면 멈추고 보고한다. 미커밋 변경은 `WARN` — 이 작업의 파일이 빠졌으면 커밋할지 묻는다. 커밋 메시지 수정(`rebase`/`amend`)·미커밋 변경 처리는 **사용자 승인 후**. 비밀값 의심이 나오면 값을 출력하지 말고 파일 위치만 알린다. 이미 push된 비밀값이면 폐기 · 재발급이 먼저다(git.md).
   - 마지막 줄 `areas:`를 2에 넘긴다.
2. **검증** — `sh .claude/skills/finish-feature/scripts/verify.sh <areas>`
   - 핵심 흐름(화면 이동 · 출퇴근 등)을 바꿨으면 `ios` 대신 `ios-ui`.
   - `FAIL`이면 PR을 만들지 않고 실패 로그 요약과 원인 추정을 보고한다.
   - `SKIP` 영역은 PR 본문에 "미실행 — 이유"로 적는다.
3. **PR 본문 초안** — `.github/pull_request_template.md` 형식 그대로. 채우는 값:
   - 무엇을 · 왜: `git log origin/main..HEAD`와 이슈 제목(`gh issue view <n> -R unib35/Pum --json title,body`)에서. `Closes #<n>`
   - 연결: 커밋 · 이슈 본문의 REQ/UI/DEC ID
   - 테스트: 2에서 **실제 실행한 명령과 PASS/FAIL 줄** 그대로. 실행 안 한 것은 "미실행"
   - 확인 항목: 1 · 2 결과로 체크할 수 있는 것만 체크. 디자인 차이 · 고위험은 diff를 보고 판단, 모르면 체크하지 않고 사용자에게 물음
4. **승인 후 게시** — 브랜치 · 커밋 수 · PR 제목 · 본문 초안을 보여주고 "push하고 PR을 열까요?"라고 묻는다(public 저장소). 승인되면:
   ```sh
   git push -u origin HEAD
   gh pr create -R unib35/Pum --base main --title "<첫 커밋 요약 또는 이슈 제목>" --body-file <초안 파일> [--draft]
   ```
   - `--force` 금지. push가 거부되면 원인을 보고하고 멈춘다.
   - 결제 · 운영 배포 · 권한 · 데이터 삭제가 diff에 있으면 PR에 `고위험` 라벨을 붙이자고 제안한다(라벨이 없으면 만들지 묻는다).
   - 머지는 하지 않는다(Squash and merge는 사용자가 수동 검토 후).
5. **보고** — 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계. PR 링크 포함.
