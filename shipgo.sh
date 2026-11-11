#!/usr/bin/env bash
# shipgo v1.0.0
set -uo pipefail

VERSION="1.0.0"
CONFIG_FILE="${SHIPGO_CONFIG:-$HOME/.shipgorc}"

if [ -t 1 ]; then
  RST=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'
  R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'
else RST=; B=; D=; R=; G=; Y=; C=; fi

DEFAULT_REMOTE="origin"
PROTECTED_BRANCHES="main master develop"
CONFIRM_FORCE=true
# shellcheck source=/dev/null
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

info(){ printf '%s %s\n' "${C}[*]${RST}" "$*"; }
ok(){   printf '%s %s\n' "${G}[OK]${RST}" "$*"; }
warn(){ printf '%s %s\n' "${Y}[!]${RST}" "$*"; }
err(){  printf '%s %s\n' "${R}[X]${RST}" "$*" >&2; }
die(){  err "$*"; exit 1; }
title(){ printf '\n%s\n' "${B}${C}== $* ==${RST}"; }
hr(){ printf '%s\n' "${D}------------------------------------------------${RST}"; }

need_repo(){ git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a Git repository."; }
branch(){ git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo HEAD; }
remote_default(){ local b r; b=$(branch); r=$(git config --get "branch.${b}.remote" 2>/dev/null||true); printf '%s' "${r:-$DEFAULT_REMOTE}"; }
upstream(){ git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true; }
ahead(){ git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0; }
behind(){ git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0; }
protected(){ local p; for p in $PROTECTED_BRANCHES; do [ "$1" = "$p" ] && return 0; done; return 1; }
confirm(){ [ "${SHIPGO_YES:-0}" = "1" ] && return 0; local a; printf '%s' "${Y}$1 [y/N]: ${RST}"; read -r a||true; case "${a:-}" in y|Y|yes|YES) return 0;; *) return 1;; esac; }
pause(){ [ -t 0 ] && read -r -p "${D}Press Enter...${RST}" _ || true; }
open_url(){ local u=$1
  command -v xdg-open >/dev/null 2>&1 && { xdg-open "$u" >/dev/null 2>&1; return; }
  command -v open     >/dev/null 2>&1 && { open     "$u" >/dev/null 2>&1; return; }
  warn "Open: $u"
}
web_url(){
  local u; u=$(git config --get remote.origin.url 2>/dev/null)||return 1
  if [[ "$u" =~ ^git@([^:]+):(.+?)(\.git)?$ ]]; then echo "https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$u" =~ ^https?:// ]]; then echo "${u%.git}"
  else echo "$u"; fi
}

cmd_status(){ need_repo; title "Status"
  local b u a bh; b=$(branch); u=$(upstream); a=$(ahead); bh=$(behind)
  printf '  %-10s %s\n' Repo: "$(git rev-parse --show-toplevel)"
  printf '  %-10s %s\n' Branch: "$b"
  printf '  %-10s %s\n' Upstream: "${u:-none}"
  printf '  %-10s %s\n' Ahead: "$a"
  printf '  %-10s %s\n' Behind: "$bh"
  hr; git status -sb
}
cmd_push(){ need_repo; local b r u a; b=$(branch); r=$(remote_default); u=$(upstream); a=$(ahead)
  if [ -z "$u" ]; then
    warn "No upstream for '$b'."
    confirm "Push and set upstream to '$r/$b'?" || { info "Aborted."; return; }
    git push -u "$r" "$b" || die "push failed"; ok "Tracking $r/$b"
  else
    [ "$a" -eq 0 ] && { info "Nothing to push."; return; }
    info "Pushing $b -> $u ($a commit(s))"; git push || die "push failed"; ok "Push complete."
  fi
}
cmd_up(){ need_repo; local b r; b=$(branch); r="${1:-$(remote_default)}"
  info "Setting upstream: $r/$b"; git push -u "$r" "$b" || die "push failed"; ok "Tracking $r/$b"
}
cmd_all(){ need_repo; local r="${1:-$DEFAULT_REMOTE}"; info "Push all branches to '$r'"; git push --all "$r"||die "push failed"; ok Done.; }
cmd_tags(){ need_repo; local r="${1:-$DEFAULT_REMOTE}"; info "Push tags to '$r'"; git push --tags "$r"||die "push failed"; ok Done.; }
cmd_force(){ need_repo; local b; b=$(branch)
  protected "$b" && warn "Protected branch: $b"
  warn "Force push rewrites '$b' on remote."
  [ "$CONFIRM_FORCE" = true ] && { confirm "Use --force-with-lease?" || { info "Aborted."; return; }; }
  git push --force-with-lease || die "force push failed"; ok "Force-pushed."
}
cmd_dry(){ need_repo; info "Dry run."; git push --dry-run "$@"||die "dry run failed"; ok Done.; }
cmd_del(){ need_repo; local b="${1:-}"
  [ -z "$b" ] && { git branch -r; read -r -p "Remote branch: " b; }
  [ -z "$b" ] && die "No branch."; b="${b#origin/}"
  confirm "Delete '$b' on origin?" || { info "Aborted."; return; }
  git push origin --delete "$b"||die "delete failed"; ok "Deleted $b."
}
cmd_remote(){ need_repo; local r="${1:-$DEFAULT_REMOTE}" s="${2:-$(branch)}" d="${3:-}"; [ -z "$d" ] && d="$s"
  info "Push $s -> $r/$d"; git push "$r" "$s:$d"||die "push failed"; ok Done.
}
cmd_undo(){ need_repo; warn "git reset --soft HEAD~1"
  confirm "Undo last commit?" || { info "Aborted."; return; }
  git reset --soft HEAD~1||die "reset failed"; ok "Undone. Changes staged."
}
cmd_sync(){ need_repo; info "Fetch"; git fetch --all --prune||die "fetch failed"
  info "Pull --rebase"; git pull --rebase --autostash||die "pull failed"
  cmd_push
}
cmd_pull(){ need_repo; info "Pull --rebase --autostash"; git pull --rebase --autostash||die "pull failed"; ok Done.; }
cmd_fetch(){ need_repo; git fetch --all --prune "${1:-$DEFAULT_REMOTE}"||die "fetch failed"; ok Done.; }
cmd_prune(){ need_repo; git fetch --prune --all||die "prune failed"; ok Done.; }
cmd_amend(){ need_repo; local u a; u=$(upstream); a=$(ahead)
  [ -n "$u" ] && [ "$a" -eq 0 ] && { warn "Already pushed to $u."; confirm "Continue (will force push)?"||{ info "Aborted."; return; }; }
  git commit --amend --no-edit||die "amend failed"
  git push --force-with-lease||die "push failed"; ok "Amended and pushed."
}
cmd_cleanup(){ need_repo; local base="${1:-main}"
  git show-ref --verify --quiet "refs/heads/$base" || base="master"
  title "Delete merged branches into $base"
  git branch --merged "$base" | grep -vE "^\*|^\s*$base$|^\s*master$|^\s*main$|develop" | xargs -r git branch -d
  ok Done.
}
cmd_tag(){ need_repo; local n="${1:-}" m="${2:-}"; [ -z "$n" ] && die "Usage: shipgo tag <name> [msg]"
  git tag -a "$n" -m "${m:-Release $n}"||die "tag failed"; git push origin "$n"||die "push failed"; ok "Pushed tag $n."
}
cmd_tag_list(){ need_repo; git tag --sort=-v:refname | head -50; }
cmd_tag_del(){ need_repo; local n="${1:-}"; [ -z "$n" ] && die "Usage: shipgo tag-del <name>"
  confirm "Delete tag '$n' local+remote?"||return
  git tag -d "$n" 2>/dev/null||warn "Local tag missing"
  if git push origin ":refs/tags/$n" 2>/dev/null; then ok "Remote deleted"; else warn "Remote missing"; fi
}
cmd_release(){ cmd_tag "$@"; }
cmd_pr(){ need_repo; command -v gh >/dev/null||die "gh not installed"; cmd_push; local t="${1:-}"
  if [ -n "$t" ]; then gh pr create --title "$t" --body "" --web; else gh pr create --fill --web; fi; }
cmd_draft_pr(){ need_repo; command -v gh >/dev/null||die "gh not installed"; cmd_push; local t="${1:-}"
  if [ -n "$t" ]; then gh pr create --draft --title "$t" --body "" --web; else gh pr create --draft --fill --web; fi; }
cmd_mr(){ need_repo; command -v glab >/dev/null||die "glab not installed"; cmd_push; local t="${1:-}"
  if [ -n "$t" ]; then glab mr create --title "$t" --web; else glab mr create --fill --web; fi; }
cmd_info(){ need_repo; title Remotes; git remote -v; echo; title Branches; git branch -vv; echo; title Status; git status -sb; }
cmd_log(){ need_repo; git log --oneline --graph --decorate -n "${1:-15}"; }
cmd_branches(){ need_repo; title Local; git branch -vv; title Remote; git branch -r; }
cmd_ahead(){ need_repo; echo "$(ahead) commit(s) ahead"; }
cmd_behind(){ need_repo; echo "$(behind) commit(s) behind"; }
cmd_whoami(){ echo "user.name:  $(git config --get user.name||echo NOT SET)"
  echo "user.email: $(git config --get user.email||echo NOT SET)"
  echo "signing:    $(git config --get commit.gpgsign||echo false)"
  echo "editor:     $(git config --get core.editor||echo default)"; }
cmd_doctor(){ title "Health"
  printf '  %-10s %s\n' git "$(git --version 2>/dev/null||echo MISSING)"
  printf '  %-10s %s\n' gh "$(gh --version 2>/dev/null|head -1||echo MISSING)"
  printf '  %-10s %s\n' glab "$(glab --version 2>/dev/null|head -1||echo MISSING)"
  printf '  %-10s %s\n' ssh "$([ -f ~/.ssh/id_ed25519.pub ]||[ -f ~/.ssh/id_rsa.pub ] && echo present || echo MISSING)"
  printf '  %-10s %s\n' user "$(git config --get user.name||echo NOT SET)"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 && {
    printf '  %-10s %s\n' repo "$(git rev-parse --show-toplevel)"
    printf '  %-10s %s\n' remote "$(git remote get-url origin 2>/dev/null||echo none)"
  }
}
cmd_ping(){ need_repo; local u; u=$(git remote get-url origin 2>/dev/null)||die "No origin."
  info "Testing $u"; if git ls-remote --heads "$u" >/dev/null 2>&1; then ok Reachable; else warn Unreachable; fi; }
cmd_open(){ need_repo; local u; u=$(web_url)||die "No origin."; open_url "$u"; }
cmd_compare(){ need_repo; local base="${1:-main}" u br; u=$(web_url)||die "No origin."; br=$(branch)
  open_url "$u/compare/$base...$br?expand=1"; }
cmd_config(){ local k="${1:-}" v="${2:-}"
  if [ -z "$k" ]; then title Config
    echo "  DEFAULT_REMOTE     = $DEFAULT_REMOTE"
    echo "  PROTECTED_BRANCHES = $PROTECTED_BRANCHES"
    echo "  CONFIRM_FORCE      = $CONFIRM_FORCE"
    echo "  Config: $CONFIG_FILE"; return; fi
  [ -z "$v" ] && die "Usage: shipgo config <key> <value>"
  [ -f "$CONFIG_FILE" ]||echo "# shipgo config" > "$CONFIG_FILE"
  grep -q "^${k}=" "$CONFIG_FILE" && sed -i.bak "s|^${k}=.*|${k}=\"${v}\"|" "$CONFIG_FILE" && rm -f "${CONFIG_FILE}.bak" || echo "${k}=\"${v}\"" >> "$CONFIG_FILE"
  ok "Set $k = $v"
}
cmd_init_config(){ [ -f "$CONFIG_FILE" ] && { confirm "$CONFIG_FILE exists. Overwrite?"||return; }
  cat > "$CONFIG_FILE" <<'EOF'
DEFAULT_REMOTE="origin"
PROTECTED_BRANCHES="main master develop"
CONFIRM_FORCE=true
EOF
  ok "Wrote $CONFIG_FILE"
}
cmd_wip(){ need_repo; info "WIP commit"
  git add -A; git commit -m "WIP: $(date '+%Y-%m-%d %H:%M:%S')" --no-verify||warn "Nothing to commit"
  cmd_push
}
cmd_stash(){ need_repo; git stash push -u -m "shipgo $(date +%s)"; ok Stashed.; }
cmd_stash_pop(){ need_repo; git stash pop; ok Popped.; }
cmd_init(){ local d="${1:-.}"; mkdir -p "$d" || die "Cannot create $d"; cd "$d" || die "Cannot create $d"
  git init -b main >/dev/null; git commit --allow-empty -m "Initial commit" >/dev/null; ok "Init in $d"; }
cmd_clone(){ local u="${1:-}" d="${2:-}"; [ -z "$u" ] && die "Usage: shipgo clone <url> [dir]"
  if [ -n "$d" ]; then git clone "$u" "$d"; else git clone "$u"; fi; ok Cloned.; }

menu(){ while true; do clear 2>/dev/null||true
  local b; b=$(branch)
  printf '\n%s\n' "${B}${C} shipgo ${VERSION}${RST}  ${D}[$b]${RST}"; hr
  cat <<'EOF'
  CORE                       SYNC / ADV
   1) Push                    13) Sync (fetch+pull+push)
   2) First push (-u)         14) Pull --rebase
   3) All branches            15) Fetch --prune
   4) Tags                    16) Prune
   5) Force push              17) Amend + force
   6) Dry run                 18) Cleanup merged
   7) Delete remote branch
   8) Push remote/branch    TAGS / PR
   9) Undo last commit        19) Create + push tag
                              20) List tags
  INFO                        21) Delete tag
  10) Status                  22) Release
  11) Info                    23) GitHub PR
  12) Log                     24) Draft PR
                              25) GitLab MR
  ENV
  26) Whoami                  28) Open in browser
  27) Doctor                  29) Branches
   0) Exit
EOF
  local s; read -r -p "  Choose> " s||exit 0
  case "$s" in
    0|q|Q|exit) exit 0;;
    1) cmd_push;; 2) cmd_up;; 3) cmd_all;; 4) cmd_tags;; 5) cmd_force;; 6) cmd_dry;;
    7) cmd_del;; 8) cmd_remote;; 9) cmd_undo;;
    10) cmd_status;; 11) cmd_info;; 12) cmd_log;; 13) cmd_sync;; 14) cmd_pull;;
    15) cmd_fetch;; 16) cmd_prune;; 17) cmd_amend;; 18) cmd_cleanup;;
    19) cmd_tag;; 20) cmd_tag_list;; 21) cmd_tag_del;; 22) cmd_release;;
    23) cmd_pr;; 24) cmd_draft_pr;; 25) cmd_mr;;
    26) cmd_whoami;; 27) cmd_doctor;; 28) cmd_open;; 29) cmd_branches;;
    *) warn "Invalid.";;
  esac; pause
done; }

usage(){ cat <<EOF
${B}shipgo ${VERSION}${RST} — Git Push Tool

${B}USAGE${RST}  shipgo [cmd] [args]

${B}CORE${RST}
  push|p            Push current branch
  up|first          Push + set upstream
  all [remote]      Push all branches
  tags [remote]     Push all tags
  force|f           Force push (--force-with-lease)
  dry               Dry run
  del [branch]      Delete remote branch
  remote [r] [s] [d] Push s -> r/d
  undo              Undo last commit (soft)

${B}SYNC${RST}
  sync              fetch + pull --rebase + push
  pull              pull --rebase --autostash
  fetch [remote]    fetch --all --prune
  prune             prune stale refs
  amend             Amend + force push
  cleanup [base]    Delete merged local branches

${B}TAGS${RST}
  tag <n> [m]       Create + push annotated tag
  tag-list          List tags
  tag-del <n>       Delete tag local+remote
  release <v> [m]   Alias for tag

${B}PR/MR${RST}
  pr [title]        GitHub PR
  draft-pr [title]  GitHub draft PR
  mr [title]        GitLab MR

${B}INFO${RST}
  status|st  info  log [n]  branches  ahead  behind
  whoami  doctor  ping  open  compare [base]

${B}CONFIG${RST}
  config [k] [v]    Show / set config
  init-config       Write ~/.shipgorc

${B}MISC${RST}
  wip  stash  stash-pop  init [dir]  clone <url> [dir]
  menu  help  version

${B}ENV${RST}  SHIPGO_YES=1  skip confirmations
EOF
}

main(){ local c="${1:-}"; [ -n "$c" ]&&shift
  case "$c" in
    ""|menu|-i|--interactive) need_repo; menu;;
    help|-h|--help) usage;;
    version|-v|--version) echo "shipgo $VERSION";;
    status|st) cmd_status;;
    push|p) cmd_push;;
    up|first) cmd_up "$@";;
    all) cmd_all "$@";;
    tags) cmd_tags "$@";;
    force|f) cmd_force;;
    dry|dry-run) cmd_dry "$@";;
    del|delete|rm) cmd_del "$@";;
    remote|to) cmd_remote "$@";;
    undo) cmd_undo;;
    sync) cmd_sync;;
    pull) cmd_pull;;
    fetch) cmd_fetch "$@";;
    prune) cmd_prune;;
    amend) cmd_amend;;
    cleanup) cmd_cleanup "$@";;
    tag) cmd_tag "$@";;
    tag-list) cmd_tag_list;;
    tag-del|tag-delete) cmd_tag_del "$@";;
    release) cmd_release "$@";;
    pr) cmd_pr "$@";;
    draft-pr) cmd_draft_pr "$@";;
    mr) cmd_mr "$@";;
    info) cmd_info;;
    log) cmd_log "$@";;
    branches) cmd_branches;;
    ahead) cmd_ahead;;
    behind) cmd_behind;;
    whoami) cmd_whoami;;
    doctor) cmd_doctor;;
    ping) cmd_ping;;
    open) cmd_open;;
    compare) cmd_compare "$@";;
    config) cmd_config "$@";;
    init-config) cmd_init_config;;
    wip) cmd_wip;;
    stash) cmd_stash;;
    stash-pop) cmd_stash_pop;;
    init) cmd_init "$@";;
    clone) cmd_clone "$@";;
    *) die "Unknown: $c  (shipgo help)";;
  esac
}
main "$@"
