#!/bin/sh
# SessionStart hook — 세션 시작 시 git 상태를 두세 줄로 알린다. 읽기 전용 · 네트워크 없음.
# 어떤 경우에도 exit 0 (세션 시작을 막지 않는다). 끄는 법: docs/conventions/automation.md
cat >/dev/null 2>&1 || :   # hook 입력(JSON)은 쓰지 않음
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

br=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
st=$(git status --porcelain 2>/dev/null)
staged=$(printf '%s\n' "$st" | grep -c '^[AMDRC]')
unstaged=$(printf '%s\n' "$st" | grep -c '^.[MD]')
untracked=$(printf '%s\n' "$st" | grep -c '^??')

echo "[pum] branch=$br staged=$staged unstaged=$unstaged untracked=$untracked"
if [ "$br" = main ] && [ -n "$st" ]; then
  echo "[pum] main에 커밋하지 않은 변경이 있다. 사용자 작업일 수 있으니 되돌리거나 stash하지 말 것. 새 작업은 /start-feature."
fi
issue=$(echo "$br" | sed -nE 's#^(feat|fix|docs|chore)/([0-9]+)-.*#\2#p')
[ -n "$issue" ] && echo "[pum] 이슈 #$issue 작업 중. 마무리는 /finish-feature."
exit 0
