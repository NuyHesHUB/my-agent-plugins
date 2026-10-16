# orca-checkout

Claude Code 스킬 플러그인. Orca 워크스페이스(git worktree)에서 끝낸 작업을 그 워크트리의 브랜치명 그대로 로컬 "진짜" 프로젝트 경로에 체크아웃하고, 사용자가 결과를 확인한 뒤 승인하면 해당 Orca 워크스페이스를 삭제한다.

> 수동으로 하던 커밋 → 브랜치 점유 해제 → 로컬 프로젝트에서 `git checkout` → 확인 후 `git worktree remove` → Orca 메타데이터 정리 과정을 `/orca-checkout` 한 번으로 끝낸다.

## 설치

요구 사항

- Claude Code 2.1 이상
- git, 그리고 Orca(워크스페이스를 git worktree로 관리하는 환경). Orca 메타데이터 정리에는 `orca-ide` CLI가 필요하다.

### 방법 1. 마켓플레이스에서 설치 (권장)

```
/plugin install orca-checkout --marketplace NuyHesHUB/my-agent-plugins
```

터미널에서 하거나 두 단계로 나누려면 다음과 같다.

```bash
claude plugin marketplace add NuyHesHUB/my-agent-plugins
claude plugin install orca-checkout@nuyheshub
```

세션 안에서는 `/plugin marketplace add NuyHesHUB/my-agent-plugins` 다음에 `/plugin install orca-checkout@nuyheshub`를 입력하면 된다. 설치 범위(user / project / local)는 설치 시 선택할 수 있다.

업데이트는 다음 명령으로 한다.

```bash
claude plugin marketplace update nuyheshub
claude plugin update orca-checkout@nuyheshub
```

### 방법 2. 클론 후 심볼릭 링크 (개발용)

```bash
git clone https://github.com/NuyHesHUB/my-agent-plugins.git ~/projects/code/my-agent-plugins
ln -s ~/projects/code/my-agent-plugins/skills/orca-checkout/skills/orca-checkout ~/.claude/skills/orca-checkout
```

한 컴퓨터에서 방법 1과 2를 동시에 쓰면 같은 스킬이 두 번 로드되니 하나만 쓴다.

## 사용법

Orca 워크스페이스 폴더에서 열린 Claude Code 세션에서 입력한다.

```
/orca-checkout
```

"브랜치 옮겨줘", "로컬 프로젝트로 체크아웃해줘", "워크스페이스 정리해줘" 같은 자연어 요청으로도 호출된다. 플러그인으로 설치하면 정식 이름은 `/orca-checkout:orca-checkout`이고, 같은 이름의 다른 명령이 없으면 `/orca-checkout`로도 호출된다.

`/orca-checkout` 호출 자체가 커밋·브랜치 이동에 대한 승인으로 간주되어 매 단계마다 되묻지 않는다. 단 **워크스페이스 삭제는 호출만으로 승인되지 않는다** — 체크아웃 결과를 보고한 뒤 삭제 여부를 프롬프트로 물어보고, 승인 응답을 받은 뒤에만 삭제한다. 아래 "중단 조건"에 해당하면 그 외 단계에서도 멈추고 사용자에게 확인한다.

## 동작 과정

### 0. 선행 확인

`git worktree list`로 현재 cwd가 Orca 워크스페이스(`/orca/workspaces/` 포함 경로)인지 확인하고, 나머지 워크트리 중 로컬 프로젝트 경로를 찾는다. 후보가 0개거나 2개 이상이면 자동 선택하지 않고 사용자에게 물어본다. (**중단 조건**)

### 1. 워크스페이스 커밋

미커밋 변경이 있으면 저장소 최근 커밋 스타일에 맞춰 커밋한다. 이미 전부 커밋돼 있으면 건너뛴다.

### 2. 로컬 프로젝트 상태 점검

로컬 프로젝트 경로에 미커밋 변경이 있으면, 옮기려는 브랜치와 무관한 별개 작업일 때만 `git stash push -u -m "orca-checkout-<timestamp>"`로 태그를 붙여 보관하고 SHA를 기록한다. 변경이 애매하거나 크면 멈추고 확인한다. (**중단 조건**)

### 3. 브랜치 이동 (워크스페이스는 아직 지우지 않음)

1. 워크스페이스에서 `git checkout --detach` — 폴더와 파일은 그대로 두고 브랜치 점유만 푼다.
2. 로컬 프로젝트 경로에서 `git checkout <워크스페이스 브랜치명>` — 점유가 풀렸으므로 성공한다.
3. 로컬 경로·브랜치명·커밋 메시지·stash SHA(만들었다면)를 사용자에게 보고한다.

### 4. 사용자 확인 후 워크스페이스 삭제

로컬에서 결과를 확인한 뒤 워크스페이스를 삭제할지 **프롬프트로 물어보고 응답을 기다린다.** 승인하면 아래를 전부 **로컬 프로젝트 경로에서** 실행한다 (워크스페이스 안에서 자기 경로를 지우면 셸 cwd가 사라져 이후 명령이 실패한다):

1. `git worktree remove <워크스페이스 경로>` — untracked 파일 때문에 거부되면 내용을 확인한 뒤에만 `--force`를 쓰고, 중요한 파일이 있으면 멈춘다. (**중단 조건**)
2. `orca-ide worktree rm --worktree path:<워크스페이스 경로> --force --json` — Orca 쪽 카드/워크스페이스 메타데이터를 정리한다. 브랜치가 이미 로컬에 체크아웃돼 있어 git이 브랜치 삭제를 막아주므로 안전하다.

거부하면 워크스페이스를 그대로 두고 detached HEAD 상태임을 안내한다.

### 5. 마무리 보고

삭제가 실행되면 **세션 자신의 cwd(워크스페이스 폴더)가 사라지므로**, 이후 이 세션에서는 쉘 명령을 추가로 실행하지 않는다. 최종 보고에 로컬 프로젝트 경로·체크아웃된 브랜치명·stash SHA(만들었다면 복원 방법 포함)와 "이 세션은 종료하거나 다른 워크스페이스로 전환해 달라"는 안내를 명시한다.

## 파일 구성

```
skills/orca-checkout/
├── .claude-plugin/
│   └── plugin.json            # 플러그인 메타데이터
├── skills/
│   └── orca-checkout/
│       └── SKILL.md           # 스킬 정의. 체크아웃 절차와 중단 조건
└── README.md
```

## 라이선스

[MIT](../../LICENSE)
