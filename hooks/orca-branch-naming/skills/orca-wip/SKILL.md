---
name: orca-wip
description: 이름을 아직 정할 수 없는 작업용 Orca 워크트리를 임시 이름(wip-MMDD-HHMMSS)으로 만든다. "/orca-wip", "임시 워크트리 만들어줘", "wip 워크트리" 요청 시 사용. 실제 브랜치명은 첫 프롬프트에서 orca-branch-naming 훅이 정한다.
---

# orca-wip

아래 스크립트를 실행해 Orca 워크트리를 만든다. 사용자가 준 인자를 그대로 넘긴다.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/orca-wip" $ARGUMENTS
```

옵션: `--repo name:<repo>` (현재 Orca 워크트리 밖이면 필수), `--agent claude|codex|none` (기본 claude), `--child` (현재 워크트리의 자식), 그 외 인자는 `orca worktree create` 에 그대로 전달 (예: `--setup skip`).

결과 JSON에서 `worktree.id`, `worktree.path`, `agentTerminalHandle` 을 한 줄로 보고한다.
