# agent-plugins

NuyHesHUB의 에이전트 플러그인 모음. 지금은 Claude Code 포장(마켓플레이스 `nuyheshub`)이 들어 있고, 스킬 본체는 Agent Skills 규격이라 Codex 등 다른 에이전트에서도 재사용할 수 있다. 이 저장소 하나가 마켓플레이스이고, 플러그인은 종류별 슬라이스 폴더 아래에 하나씩 들어 있다.

```
skills/<name>/   스킬만 있는 플러그인
hooks/<name>/    훅이 들어간 플러그인 (스킬을 같이 가질 수 있음)
```

| 폴더 | 플러그인 | 종류 | 설명 |
| --- | --- | --- | --- |
| `hooks/orca-branch-naming/` | `orca-branch-naming` | 훅 + 스킬 | Orca 워크트리 브랜치를 첫 프롬프트에서 `<type>/<slug>` 로 자동 네이밍. **Orca 전용** |
| `skills/mr-template/` | `mr-template` | 스킬 | origin 두 브랜치 차이로 운영 배포 MR 설명 생성 |
| `skills/orca-checkout/` | `orca-checkout` | 스킬 | Orca 워크스페이스 작업을 워크트리 브랜치명 그대로 로컬 프로젝트에 체크아웃하고, 사용자 확인 후 워크스페이스 삭제. **Orca 전용** |

## 설치

Claude Code 안에서 (2.1.275+):

```
/plugin install orca-branch-naming --marketplace NuyHesHUB/my-agent-plugins
/plugin install mr-template --marketplace NuyHesHUB/my-agent-plugins
/plugin install orca-checkout --marketplace NuyHesHUB/my-agent-plugins
```

터미널에서:

```bash
claude plugin marketplace add NuyHesHUB/my-agent-plugins
claude plugin install orca-branch-naming@nuyheshub
claude plugin install mr-template@nuyheshub
claude plugin install orca-checkout@nuyheshub
```

자동 업데이트는 `~/.claude/settings.json` 의 마켓플레이스 항목에 `"autoUpdate": true`:

```json
"extraKnownMarketplaces": {
  "nuyheshub": { "source": { "source": "github", "repo": "NuyHesHUB/my-agent-plugins" }, "autoUpdate": true }
}
```

수동 업데이트: `claude plugin update <plugin>@nuyheshub` 후 Claude Code 재시작.

## 플러그인 추가하는 법

1. 종류에 맞는 슬라이스(`skills/` 또는 `hooks/`) 아래에 폴더를 만들고 `.claude-plugin/plugin.json` (`name`, `version`, `description`) 을 둔다.
2. 기능은 그 폴더 안의 `skills/<name>/SKILL.md`, `hooks/hooks.json`, `scripts/` 등에 넣는다. 훅·스킬에서 자기 파일은 `${CLAUDE_PLUGIN_ROOT}` 로 참조한다.
3. 루트 `.claude-plugin/marketplace.json` 의 `plugins` 에 `{ name, source: "./hooks/<폴더>" 또는 "./skills/<폴더>", version }` 을 추가한다.
4. `claude plugin validate .` 통과 확인 후 커밋·push.

## 버전 올리기

플러그인을 고치면 그 폴더의 `plugin.json` 과 루트 `marketplace.json` 의 `version` 을 **같이** 올린다. 버전이 같으면 업데이트로 인식되지 않는다.

## 로컬에서 테스트

```bash
claude plugin marketplace add /path/to/agent-plugins   # 디렉터리 마켓플레이스
claude plugin install orca-branch-naming@nuyheshub
```
