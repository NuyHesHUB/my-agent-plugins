# Orca 워크트리 브랜치 자동 네이밍

Orca에서 워크트리를 만들 때는 아직 무슨 작업인지 모른다. 그래서 이름은 비워 두고(또는 임시 이름으로) 만들고,
그 워크트리에 들어온 **첫 실제 작업 프롬프트**를 에이전트가 읽어 `{작업유형}/{작업내용}` 형식으로
git 브랜치명과 Orca 사이드바 이름을 자동으로 정한다.

```
워크트리 생성 (이름 비움 → razorfish)
      │
      ▼
첫 프롬프트: "행사 신청 모바일 레이아웃에서 폼 패딩이 어긋나는 버그 고쳐줘"
      │  UserPromptSubmit 훅이 에이전트에게 네이밍 지시 주입
      ▼
에이전트:  git branch -m fix/event-apply-mobile-padding
          orca-ide worktree set --display-name fix/event-apply-mobile-padding --comment "…"
          "브랜치: razorfish → fix/event-apply-mobile-padding"  ← 한 줄 보고 후 본 작업 진행
```

실측: 프롬프트 전송부터 이름 변경 완료까지 약 10초, 코드 변경 없음, 이후 프롬프트에는 안내가 반복되지 않음.

---

## 0. 설치 (Claude Code 플러그인)

이 폴더(`hooks/orca-branch-naming/`)는 `NuyHesHUB/my-agent-plugins` 마켓플레이스 안의 플러그인 하나다. Claude Code 안에서:

```
/plugin install orca-branch-naming --marketplace NuyHesHUB/my-agent-plugins
```

또는 터미널에서:

```bash
claude plugin marketplace add NuyHesHUB/my-agent-plugins
claude plugin install orca-branch-naming@nuyheshub
```

설치되면 `UserPromptSubmit` 훅과 `/orca-wip` 스킬이 자동으로 들어온다. 터미널에서 `orca-wip` 명령을 쓰려면 한 번만:

```bash
mkdir -p ~/.local/bin && cp scripts/orca-wip-launcher ~/.local/bin/orca-wip && chmod +x ~/.local/bin/orca-wip
```

(런처는 설치된 플러그인 경로를 `~/.claude/plugins/installed_plugins.json` 에서 찾아 실행하므로 플러그인이 업데이트돼도 그대로 동작한다.)

자동 업데이트: `~/.claude/settings.json` 의 마켓플레이스 항목에 `autoUpdate: true` 를 두면 Claude Code 시작 시 마켓플레이스와 플러그인을 갱신한다.

```json
"extraKnownMarketplaces": {
  "nuyheshub": { "source": { "source": "github", "repo": "NuyHesHUB/my-agent-plugins" }, "autoUpdate": true }
}
```

수동 갱신: `claude plugin update orca-branch-naming@nuyheshub` (적용은 재시작 후).

---

## 1. 사용 방법

### 1-1. 워크트리 만들기

세 가지 중 아무거나. 디렉터리명은 나중에 바꿀 수 없으므로(아래 "제약") 겹치지만 않으면 된다.

| 방법 | 브랜치/디렉터리 이름 | 첫 프롬프트 후 |
| --- | --- | --- |
| **Orca UI에서 이름 비우고 생성** | `razorfish`, `alewife` 같은 Orca 랜덤 단어 | 프롬프트로 유형+내용 새로 생성 |
| 터미널에서 `orca-wip` | `wip-1016-105442` (시각 기반) | 위와 같음 |
| 이름을 직접 입력 (`행사-신청`) | 입력한 그대로 | **이름 유지**, 유형 접두어만 추가 → `feat/행사-신청` |

`orca-wip` 옵션:

```bash
orca-wip                                  # 현재 Orca 워크트리의 repo에, claude 에이전트와 함께, 독립 워크트리로
orca-wip --repo name:korea-ai-school-fe   # 다른 repo
orca-wip --agent codex                    # 다른 에이전트
orca-wip --agent none                     # 쉘만
orca-wip --child                          # 현재 워크트리의 자식으로
orca-wip --setup skip                     # 나머지 인자는 `orca worktree create` 에 그대로 전달
```

### 1-2. 첫 프롬프트 보내기

평소처럼 작업 요청을 보내면 된다. 에이전트가 본 작업에 앞서 브랜치명을 정하고 한 줄로 알린다.

- 인사·단순 질문·모호한 프롬프트면 에이전트가 네이밍을 건너뛰고, 다음 프롬프트에서 다시 안내된다.
- 프롬프트에 브랜치명을 직접 적으면 그 이름을 쓴다. (`브랜치는 feat/member-school 로 해줘`)
- "이름 바꾸지 마" 라고 하면 에이전트가 이 워크트리의 안내를 끈다.

### 1-3. 결과 확인

```bash
git branch --show-current                                   # fix/event-apply-mobile-padding
orca-ide worktree show --worktree active --json             # displayName, comment 확인
```

### 1-4. 끄기 / 건너뛰기 / 수동 처리

| 하고 싶은 것 | 방법 |
| --- | --- |
| 전역으로 끄기 | 환경변수 `ORCA_BRANCH_NAMING=off` |
| 직접 지은 이름은 손대지 않기 (랜덤·wip만 자동) | `ORCA_BRANCH_NAMING=placeholder-only` |
| 이 워크트리만 끄기 | `touch "$(git rev-parse --git-dir)/orca-branch-naming.skip"` |
| 처음부터 건드리지 않게 만들기 | 생성 시 이름에 `/` 를 넣는다 (`feat/행사-신청`) |
| 수동으로 이름 짓기 | `git branch -m <type>/<slug>` + `orca-ide worktree set --worktree active --display-name <type>/<slug> --json` |
| 완전히 제거 | `claude plugin uninstall orca-branch-naming@nuyheshub` |

---

## 2. 브랜치명 규칙

형식: **`<type>/<slug>`**

| type | 용도 |
| --- | --- |
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변화 없는 구조 개선 |
| `chore` | 설정·의존성·빌드 잡일 |
| `test` | 테스트 추가/수정 |
| `docs` | 문서 |
| `style` | 포맷·스타일 (동작 변화 없음) |
| `perf` | 성능 |
| `ci` | CI 파이프라인 |
| `build` | 빌드 시스템 |

slug 규칙 (자동 생성 시):

- 영문 소문자 + 숫자 + 하이픈(kebab-case), 2~4단어, 최대 32자
- 화면/도메인 + 동작 조합으로 무엇을 하는지 바로 보이게
- 예: `fix/event-apply-mobile-padding`, `feat/member-school-field`, `chore/eslint-upgrade`, `refactor/apply-form-state`

사용자가 직접 지은 이름은 번역·수정하지 않고 그대로 slug가 된다 (`feat/행사-신청`).

---

## 3. 생성 시 이름에 따른 동작

| 생성 시 브랜치명 | 판정 | 첫 프롬프트 후 |
| --- | --- | --- |
| `razorfish` (Orca 랜덤, 소문자 한 단어) | 임시 이름 | 프롬프트로 유형+slug 생성 → `fix/event-apply-mobile-padding` |
| `wip-1016-1430` (`orca-wip`) | 임시 이름 | 위와 같음 |
| `login` (영문 소문자 한 단어) | 임시 이름으로 간주 | 위와 같음. 한 단어를 유지하고 싶으면 `login-page` 처럼 하이픈을 넣는다 |
| `행사-신청`, `3차-개발-계획`, `member-page` | 사용자 지정 | 이름 유지, 유형만 추가 → `feat/행사-신청` |
| `fix-login-form`, `feat_member_page` | 유형으로 시작 | 분류 없이 형식만 정규화 → `fix/login-form` |
| `feat/login-form` | 이미 컨벤션 | 아무것도 안 함 |
| `main`, `develop` 등 보호 브랜치 | 제외 | 아무것도 안 함 |
| 이미 push 된 브랜치 | 제외 | 아무것도 안 함 |

판정 정규식(훅 상단 `placeholder_re`): `^(wip([-_].*)?|[a-z]{3,})$` → 맞으면 임시 이름, 아니면 사용자 지정.

---

## 4. 동작 원리

### 훅

플러그인의 `UserPromptSubmit` 훅 `scripts/orca-branch-naming.sh` 가 **매 프롬프트마다** 실행된다.
git 명령 몇 개로 조건을 검사하고(조용히 끝날 때 약 20ms), 모두 만족할 때만 에이전트 컨텍스트에 네이밍 지시를 넣는다.

동작 조건 (전부 만족해야 함):

1. Orca 터미널 안 (`ORCA_WORKTREE_ID` 설정됨)
2. git 워크트리이고 **메인 워크트리가 아님** (폴더 기반 Orca 프로젝트 제외)
3. 현재 브랜치명에 `/` 가 없음
4. 보호 브랜치가 아님: `main` `master` `develop` `dev` `development` `staging` `production` `prod` `release` `trunk`
5. 원격 upstream 이 없음 (push 된 브랜치는 건드리지 않음)
6. 프롬프트가 비어 있지 않고 `/` 로 시작하는 슬래시 명령이 아님
7. opt-out 마커 파일이 없음

훅은 이름을 **직접 짓지 않는다.** 분류와 slug 작성은 어차피 프롬프트를 읽어야 하는 에이전트가 하고,
훅은 "지금 이 브랜치는 임시 이름이니 본 작업 전에 이렇게 바꿔라"는 지시와 정확한 명령만 준다.
그래서 추가 모델 호출이 없고 에이전트의 첫 턴 안에서 끝난다.

### 에이전트가 실행하는 명령

```bash
git branch -m "<새 브랜치명>"
orca-ide worktree set --worktree active --display-name "<새 브랜치명>" --comment "<작업 한 줄 요약>" --json
```

`orca-ide` 부분은 훅이 `ORCA_CLI_COMMAND` 환경변수에서 읽어 넣는다 (WSL 터미널에서는 `orca-ide`, 그 외 `orca`).

### 왜 디렉터리명은 그대로인가

Orca 워크트리 ID는 `<repoId>::<path>` 로 경로 기반이다. 디렉터리를 옮기면 Orca 추적·터미널·에이전트 세션이 끊긴다.
그래서 git 브랜치와 Orca 표시 이름(`--display-name`)만 바꾸고 디렉터리(`~/orca/workspaces/<repo>/razorfish`)는 둔다.
Orca 자체의 Auto-rename 기능도 같은 방식으로 동작한다.

---

## 5. Orca 자체 기능과의 관계 (중요)

Orca에는 비슷한 기능이 내장돼 있다. 설정 → **Git** 탭.

### 5-1. "Auto-rename branch & worktree" (기본 켜짐)

Orca 설명: *"When an agent starts working in a new workspace, Orca renames its auto-generated branch (e.g. `Nautilus`)
to a short name summarizing the task. Only branches Orca named itself are renamed, and never after they have been pushed."*

코드로 확인한 동작 조건:

- 워크트리를 **이름 비우고 + 에이전트와 함께** 만든 경우에만 (`pendingFirstAgentMessageRename`)
- 현재 브랜치의 마지막 세그먼트가 Orca 랜덤 단어일 때만
- upstream 없을 때만
- 에이전트가 첫 프롬프트로 `working` 상태가 되면, 별도의 모델 호출로 이름을 생성
- 생성 결과는 **하이픈 형식** `fix-login-flow` (`/` 포함 불가 — `[^a-z0-9]` 는 전부 `-` 로 치환됨), 여기에 Branch Prefix 설정이 붙음
- 생성 중 브랜치가 바뀌었으면 포기 (`branch changed during generation`)

Advanced → "Branch name command template" 에서 생성 프롬프트를 바꿀 수 있다 (`{basePrompt}`, `{firstPrompt}`, `{assistantMessage}`).

**이 훅과의 관계:** 둘 다 켜 두면 랜덤 이름 워크트리에서 두 쪽이 동시에 이름을 지으려 한다.
훅 쪽이 먼저 바꾸면 Orca는 "auto-generated name이 아님"으로 물러나고, Orca가 먼저 바꿔도 훅 쪽 에이전트가 다시 `type/slug` 로 바꾼다.
최종 결과는 항상 훅 쪽 이름이지만 모델 호출이 한 번 낭비되고 사이드바 이름이 잠깐 두 번 바뀐다.

**권장:** 이 훅을 쓰면 Orca의 Auto-rename 은 **끈다** (설정 → Git → Auto-rename branch & worktree 토글).

반대로 **`/` 없는 하이픈 형식으로 충분하고 이름 비운 워크트리만 다루면** 훅 없이 Orca 기능만 써도 된다.
그때는 Advanced 템플릿에 예를 들어 아래처럼 적는다.

```
{basePrompt}

Start the name with one of: feat, fix, refactor, chore, test, docs, style, perf, ci, build.
Use kebab-case, 2-4 words, e.g. fix-login-form-validation.
```

### 5-2. "Branch Prefix" — 이름을 고정으로 적어 두는 Orca 방식

설정 → Git → **Branch Prefix**: `Git Username` / `Custom` / `None`. *"Prefix added to branch names when creating worktrees."*

- `Custom` 에 `jaiden` 을 넣으면 새 워크트리 브랜치가 전부 `jaiden/<이름>` 으로 만들어진다 (자동 이름이면 `jaiden/razorfish`).
- 현재 설정은 `Git Username` 인데 이 PC의 git username 이 비어 있어 사실상 `None` 과 같다.

**이 훅과의 관계:** 접두어가 붙으면 브랜치에 `/` 가 생겨 훅이 "이미 이름이 정해진 브랜치"로 보고 아무것도 하지 않는다.
`{type}/{slug}` 컨벤션은 유형이 곧 접두어 역할이므로 **Branch Prefix 는 `None`(또는 username 비움)** 으로 둔다.
팀 규칙상 사용자명 접두어가 꼭 필요하면 훅의 `placeholder_re` 와 명령을 `jaiden/<type>/<slug>` 형태로 손봐야 한다.

### 5-3. "이름을 고정" 이라는 말의 세 가지 뜻과 답

| 원하는 것 | 답 |
| --- | --- |
| 새 브랜치에 항상 같은 접두어 | Orca Branch Prefix → Custom. 단, 이 훅과는 같이 못 씀 (위 참고) |
| 항상 같은 이름(예: `wip`)으로 생성 | 불가. 디렉터리가 겹치므로 Orca는 빈 이름에 랜덤 단어를 준다. 같은 *패턴*이 필요하면 `orca-wip` (`wip-MMDD-HHMMSS`) |
| 내가 지은 이름을 아무도 못 바꾸게 | 생성 시 `/` 포함 이름(`feat/행사-신청`)으로 만들면 훅·Orca 모두 건드리지 않음. 또는 `ORCA_BRANCH_NAMING=placeholder-only` |

---

## 6. 저장소 구성과 릴리스

```
.claude-plugin/plugin.json       플러그인 매니페스트 (name, version)
(마켓플레이스 목록은 상위 저장소 루트의 .claude-plugin/marketplace.json, version 동일하게 유지)
hooks/hooks.json                 UserPromptSubmit → scripts/orca-branch-naming.sh
scripts/orca-branch-naming.sh    훅 본체 (판정 + 임시/지정/정규화 모드별 지시 주입)
scripts/orca-wip                 임시 이름 워크트리 생성 스크립트
scripts/orca-wip-launcher        ~/.local/bin/orca-wip 로 복사해 쓰는 런처
skills/orca-wip/SKILL.md         /orca-wip 스킬
README.md
```

새 버전 내는 순서:

1. 스크립트/스킬 수정
2. `.claude-plugin/plugin.json` 과 `marketplace.json` 의 `version` 을 같이 올린다 (예: 0.1.0 → 0.2.0). 버전이 같으면 업데이트로 인식되지 않는다.
3. `claude plugin validate .` 로 검사
4. 커밋 → GitHub push
5. 각 PC에서 `claude plugin update orca-branch-naming@nuyheshub` 또는 autoUpdate 로 반영, Claude Code 재시작

로컬에서 바로 테스트하려면 이 폴더를 디렉터리 마켓플레이스로 추가해 설치한다:

```bash
claude plugin marketplace add /path/to/this/repo
claude plugin install orca-branch-naming@nuyheshub
```

GitHub로 옮길 때는 디렉터리 마켓플레이스를 지우고 다시 추가한다:

```bash
claude plugin uninstall orca-branch-naming@nuyheshub
claude plugin marketplace remove nuyheshub
claude plugin marketplace add NuyHesHUB/my-agent-plugins
claude plugin install orca-branch-naming@nuyheshub
```

Orca 업데이트가 `~/.claude/settings.json` 의 hooks 블록을 다시 써도 플러그인 훅은 영향을 받지 않는다 (훅이 플러그인 안에 있음).

## 7. 직접 검증하는 법

```bash
# 1) 임시 이름 워크트리 생성 (setup 스크립트 생략)
orca-wip --repo name:korea-ai-school-fe --setup skip
# 2) 뜬 Claude 에 첫 프롬프트를 보낸다. 코드 수정 없이 이름만 확인하려면:
#    "테스트: 로그인 폼 유효성 검사 버그를 고칠 거야. 브랜치 이름만 정하고 코드는 건드리지 말고 대기해줘."
# 3) 확인
git branch --show-current
orca-ide worktree show --worktree active --json
# 4) 정리
orca-ide worktree rm --worktree 'branch:fix/login-form-validation' --force --json
```

훅 로직만 빠르게 확인하려면 아무 git 워크트리에서:

```bash
printf '%s' '{"prompt":"로그인 폼 유효성 검사 버그 고쳐줘"}' | ORCA_WORKTREE_ID=x bash scripts/orca-branch-naming.sh
# 임시 이름 브랜치면 JSON 지시가, 아니면 아무것도 출력되지 않는다
```

---

## 8. 제약과 FAQ

- **Claude Code 세션에서만 자동 동작한다.** Codex 등 다른 에이전트 워크트리는 4절의 두 명령을 수동 실행한다.
- **워크트리 디렉터리명은 바뀌지 않는다.** 사이드바 이름만 바뀐다.
- **매 프롬프트마다 훅이 실행되지만** git 명령 몇 개뿐이라 조용한 경로 약 20ms, 안내 경로 약 80ms.
- **영문 한 단어 이름은 임시 이름으로 오인한다.** (`login`) 유지하려면 하이픈을 넣는다.
- **훅이 안 도는 것 같을 때:** Orca 터미널인지(`echo $ORCA_WORKTREE_ID`), 메인 워크트리가 아닌지, 브랜치에 `/` 가 없는지, upstream 이 없는지(`git rev-parse --abbrev-ref @{u}`) 순서로 확인한다. `claude --debug` 로 훅 로그를 볼 수 있다.
- **이름이 마음에 안 들면** 그냥 `git branch -m` 으로 바꾸고 `orca-ide worktree set --display-name` 을 맞춰 주면 된다. `/` 가 있으니 훅은 더 이상 개입하지 않는다.
