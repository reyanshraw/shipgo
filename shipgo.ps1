# shipgo v1.0.0
param(
  [Parameter(Position=0)][string]$Cmd = '',
  [Parameter(Position=1, ValueFromRemainingArguments=$true)][string[]]$Args = @()
)
$ErrorActionPreference = 'Stop'
$VERSION = '1.0.0'
$DEFAULT_REMOTE = 'origin'
$PROTECTED_BRANCHES = @('main','master','develop')

function Write-Info($m){ Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[!] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[X] $m" -ForegroundColor Red }
function Die($m){ Write-Err $m; exit 1 }

function Need-Repo {
  git rev-parse --is-inside-work-tree 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { Die 'Not inside a Git repository.' }
}
function Get-Branch {
  $b = git symbolic-ref --short -q HEAD 2>$null
  if (-not $b) { $b = git rev-parse --short HEAD 2>$null }
  if (-not $b) { $b = 'HEAD' }
  return $b.Trim()
}
function Get-Upstream {
  $u = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
  if ($LASTEXITCODE -ne 0) { return '' }
  return $u.Trim()
}
function Get-DefaultRemote {
  $b = Get-Branch
  $r = git config --get "branch.$b.remote" 2>$null
  if (-not $r) { $r = $DEFAULT_REMOTE }
  return $r.Trim()
}
function Get-Ahead  { $n = git rev-list --count "@{u}..HEAD" 2>$null; if ($LASTEXITCODE -ne 0) { 0 } else { [int]$n } }
function Get-Behind { $n = git rev-list --count "HEAD..@{u}" 2>$null; if ($LASTEXITCODE -ne 0) { 0 } else { [int]$n } }
function Is-Protected($b){ return $PROTECTED_BRANCHES -contains $b }
function Confirm-Action($msg){
  if ($env:SHIPGO_YES -eq '1') { return $true }
  $a = Read-Host "$msg [y/N]"
  return ($a -match '^(y|Y|yes|YES)$')
}

function Cmd-Status {
  Need-Repo
  $b = Get-Branch; $u = Get-Upstream; $a = Get-Ahead; $bh = Get-Behind
  Write-Host ''
  Write-Host '== Status ==' -ForegroundColor Cyan
  "  Repo:     {0}" -f (git rev-parse --show-toplevel)
  "  Branch:   {0}" -f $b
  "  Upstream: {0}" -f $(if ($u) { $u } else { 'none' })
  "  Ahead:    {0}" -f $a
  "  Behind:   {0}" -f $bh
  Write-Host ('-' * 48) -ForegroundColor DarkGray
  git status -sb
}
function Cmd-Push {
  Need-Repo
  $b = Get-Branch; $r = Get-DefaultRemote; $u = Get-Upstream
  if (-not $u) {
    Write-Warn "No upstream for '$b'."
    if (-not (Confirm-Action "Push and set upstream $r/$b")) { Write-Info 'Aborted.'; return }
    git push -u $r $b
    if ($LASTEXITCODE -ne 0) { Die 'push failed' }
    Write-Ok "Tracking $r/$b"
  } else {
    $a = Get-Ahead
    if ($a -eq 0) { Write-Info 'Nothing to push.'; return }
    Write-Info "Pushing $b -> $u ($a commit(s))"
    git push
    if ($LASTEXITCODE -ne 0) { Die 'push failed' }
    Write-Ok 'Push complete.'
  }
}
function Cmd-Up {
  Need-Repo
  $b = Get-Branch
  $r = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { Get-DefaultRemote }
  git push -u $r $b
  if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok "Tracking $r/$b"
}
function Cmd-All {
  Need-Repo
  $r = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { $DEFAULT_REMOTE }
  git push --all $r; if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok 'All branches pushed.'
}
function Cmd-Tags {
  Need-Repo
  $r = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { $DEFAULT_REMOTE }
  git push --tags $r; if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok 'All tags pushed.'
}
function Cmd-Force {
  Need-Repo
  $b = Get-Branch
  if (Is-Protected $b) { Write-Warn "Protected branch: $b" }
  Write-Warn "Force push rewrites '$b' on remote."
  if (-not (Confirm-Action 'Use --force-with-lease')) { Write-Info 'Aborted.'; return }
  git push --force-with-lease; if ($LASTEXITCODE -ne 0) { Die 'force push failed' }
  Write-Ok 'Force-pushed.'
}
function Cmd-Dry {
  Need-Repo
  git push --dry-run @Args
  if ($LASTEXITCODE -ne 0) { Die 'dry run failed' }
  Write-Ok 'Dry run OK.'
}
function Cmd-Del {
  Need-Repo
  $t = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  if (-not $t) { git branch -r; $t = Read-Host 'Remote branch' }
  if (-not $t) { Die 'No branch.' }
  $t = $t -replace '^origin/',''
  if (-not (Confirm-Action "Delete '$t' on origin")) { Write-Info 'Aborted.'; return }
  git push origin --delete $t; if ($LASTEXITCODE -ne 0) { Die 'delete failed' }
  Write-Ok "Deleted $t."
}
function Cmd-Remote {
  Need-Repo
  $r = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { $DEFAULT_REMOTE }
  $s = if ($Args.Count -gt 1 -and $Args[1]) { $Args[1] } else { Get-Branch }
  $d = if ($Args.Count -gt 2 -and $Args[2]) { $Args[2] } else { $s }
  git push $r "${s}:${d}"; if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok 'Done.'
}
function Cmd-Undo {
  Need-Repo
  if (-not (Confirm-Action 'Undo last commit (soft)')) { Write-Info 'Aborted.'; return }
  git reset --soft HEAD~1; if ($LASTEXITCODE -ne 0) { Die 'reset failed' }
  Write-Ok 'Undone. Changes staged.'
}
function Cmd-Sync {
  Need-Repo
  git fetch --all --prune; if ($LASTEXITCODE -ne 0) { Die 'fetch failed' }
  git pull --rebase --autostash; if ($LASTEXITCODE -ne 0) { Die 'pull failed' }
  Cmd-Push
}
function Cmd-Pull {
  Need-Repo
  git pull --rebase --autostash; if ($LASTEXITCODE -ne 0) { Die 'pull failed' }
  Write-Ok 'Pulled.'
}
function Cmd-Fetch {
  Need-Repo
  $r = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { $DEFAULT_REMOTE }
  git fetch --all --prune $r; if ($LASTEXITCODE -ne 0) { Die 'fetch failed' }
  Write-Ok 'Fetched.'
}
function Cmd-Prude { Need-Repo; git fetch --prune --all; Write-Ok 'Pruned.' }
function Cmd-Amend {
  Need-Repo
  $u = Get-Upstream; $a = Get-Ahead
  if ($u -and $a -eq 0) {
    Write-Warn "Already pushed to $u."
    if (-not (Confirm-Action 'Continue (will force push)')) { Write-Info 'Aborted.'; return }
  }
  git commit --amend --no-edit; if ($LASTEXITCODE -ne 0) { Die 'amend failed' }
  git push --force-with-lease; if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok 'Amended and pushed.'
}
function Cmd-Cleanup {
  Need-Repo
  $base = if ($Args.Count -gt 0 -and $Args[0]) { $Args[0] } else { 'main' }
  git show-ref --verify --quiet "refs/heads/$base"
  if ($LASTEXITCODE -ne 0) { $base = 'master' }
  git branch --merged $base | Where-Object { $_ -notmatch '^\*' -and $_.Trim() -ne $base -and $_.Trim() -ne 'master' -and $_.Trim() -ne 'main' } | ForEach-Object {
    $n = $_.Trim(); Write-Host "  - $n"; git branch -d $n
  }
  Write-Ok 'Cleanup done.'
}
function Cmd-Tag {
  Need-Repo
  $n = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  $m = if ($Args.Count -gt 1) { $Args[1] } else { "Release $n" }
  if (-not $n) { Die 'Usage: shipgo tag <name> [msg]' }
  git tag -a $n -m $m; if ($LASTEXITCODE -ne 0) { Die 'tag failed' }
  git push origin $n; if ($LASTEXITCODE -ne 0) { Die 'push failed' }
  Write-Ok "Pushed tag $n."
}
function Cmd-TagList { Need-Repo; git tag --sort=-v:refname | Select-Object -First 50 }
function Cmd-TagDel {
  Need-Repo
  $n = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  if (-not $n) { Die 'Usage: shipgo tag-del <name>' }
  if (-not (Confirm-Action "Delete tag '$n' local+remote")) { return }
  git tag -d $n 2>$null
  git push origin ":refs/tags/$n" 2>$null
  Write-Ok "Deleted $n."
}
function Cmd-Release { Cmd-Tag }
function Cmd-Pr {
  Need-Repo
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Die 'gh not installed' }
  Cmd-Push
  $t = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  if ($t) { gh pr create --title $t --body '' --web } else { gh pr create --fill --web }
}
function Cmd-DraftPr {
  Need-Repo
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Die 'gh not installed' }
  Cmd-Push
  $t = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  if ($t) { gh pr create --draft --title $t --body '' --web } else { gh pr create --draft --fill --web }
}
function Cmd-Mr {
  Need-Repo
  if (-not (Get-Command glab -ErrorAction SilentlyContinue)) { Die 'glab not installed' }
  Cmd-Push
  $t = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  if ($t) { glab mr create --title $t --web } else { glab mr create --fill --web }
}
function Cmd-Info {
  Need-Repo
  Write-Host '== Remotes ==' -ForegroundColor Cyan; git remote -v
  Write-Host ''
  Write-Host '== Branches ==' -ForegroundColor Cyan; git branch -vv
  Write-Host ''
  Write-Host '== Status ==' -ForegroundColor Cyan; git status -sb
}
function Cmd-Log {
  Need-Repo
  $n = if ($Args.Count -gt 0) { $Args[0] } else { 15 }
  git log --oneline --graph --decorate -n $n
}
function Cmd-Branches {
  Need-Repo
  Write-Host '== Local ==' -ForegroundColor Cyan; git branch -vv
  Write-Host ''
  Write-Host '== Remote ==' -ForegroundColor Cyan; git branch -r
}
function Cmd-Ahead  { Need-Repo; Write-Host "$(Get-Ahead) commit(s) ahead" }
function Cmd-Behind { Need-Repo; Write-Host "$(Get-Behind) commit(s) behind" }
function Cmd-Whoami {
  "user.name:  {0}" -f (git config --get user.name)
  "user.email: {0}" -f (git config --get user.email)
  "signing:    {0}" -f (git config --get commit.gpgsign)
  "editor:     {0}" -f (git config --get core.editor)
}
function Cmd-Doctor {
  Write-Host '== Health ==' -ForegroundColor Cyan
  "  git:  {0}" -f ((git --version) -join '')
  $gh   = Get-Command gh   -ErrorAction SilentlyContinue
  $glab = Get-Command glab -ErrorAction SilentlyContinue
  "  gh:   {0}" -f $(if ($gh) { ($gh --version | Select-Object -First 1) } else { 'MISSING' })
  "  glab: {0}" -f $(if ($glab) { ($glab --version | Select-Object -First 1) } else { 'MISSING' })
  "  user: {0}" -f (git config --get user.name)
  git rev-parse --is-inside-work-tree 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    "  repo:   {0}" -f (git rev-parse --show-toplevel)
    "  remote: {0}" -f (git remote get-url origin 2>$null)
  }
}
function Cmd-Ping {
  Need-Repo
  git ls-remote --heads origin 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Ok 'Reachable' } else { Write-Warn 'Unreachable' }
}
function Get-WebUrl {
  $u = git config --get remote.origin.url 2>$null
  if (-not $u) { return '' }
  $u = $u -replace '\.git$',''
  if ($u -match '^git@([^:]+):(.+)$') { return "https://$($Matches[1])/$($Matches[2])" }
  return $u
}
function Cmd-Open {
  Need-Repo
  $u = Get-WebUrl; if (-not $u) { Die 'No origin.' }
  Start-Process $u
}
function Cmd-Compare {
  Need-Repo
  $base = if ($Args.Count -gt 0) { $Args[0] } else { 'main' }
  $u = Get-WebUrl; if (-not $u) { Die 'No origin.' }
  $b = Get-Branch
  Start-Process "$u/compare/$base...$b`?expand=1"
}
function Cmd-Config {
  $k = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  $v = if ($Args.Count -gt 1) { $Args[1] } else { '' }
  if (-not $k) {
    Write-Host "DEFAULT_REMOTE     = $DEFAULT_REMOTE"
    Write-Host "PROTECTED_BRANCHES = $($PROTECTED_BRANCHES -join ' ')"
    return
  }
  if (-not $v) { Die 'Usage: shipgo config <key> <value>' }
  Write-Ok "Set $k = $v"
}
function Cmd-Wip {
  Need-Repo
  git add -A
  git commit -m "WIP: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" --no-verify 2>$null
  Cmd-Push
}
function Cmd-Stash    { Need-Repo; git stash push -u -m shipgo; Write-Ok 'Stashed.' }
function Cmd-StashPop { Need-Repo; git stash pop; Write-Ok 'Popped.' }
function Cmd-Init {
  $d = if ($Args.Count -gt 0) { $Args[0] } else { '.' }
  New-Item -ItemType Directory -Path $d -Force | Out-Null
  Push-Location $d; git init -b main | Out-Null; git commit --allow-empty -m 'Initial commit' | Out-Null; Pop-Location
  Write-Ok "Init in $d"
}
function Cmd-Clone {
  $u = if ($Args.Count -gt 0) { $Args[0] } else { '' }
  $d = if ($Args.Count -gt 1) { $Args[1] } else { '' }
  if (-not $u) { Die 'Usage: shipgo clone <url> [dir]' }
  if ($d) { git clone $u $d } else { git clone $u }
  Write-Ok 'Cloned.'
}

function Show-Menu {
  while ($true) {
    Clear-Host
    $b = if ((git rev-parse --is-inside-work-tree 2>$null)) { Get-Branch } else { '-' }
    Write-Host ''
    Write-Host " shipgo $VERSION  [$b]" -ForegroundColor Cyan
    Write-Host ('-' * 60) -ForegroundColor DarkGray
    @'
   CORE                        SYNC / ADV
    1) Push                     13) Sync
    2) First push (-u)          14) Pull --rebase
    3) All branches             15) Fetch --prune
    4) Tags                     16) Prune
    5) Force push               17) Amend + force
    6) Dry run                  18) Cleanup merged
    7) Delete remote branch
    8) Push remote/branch     TAGS / PR
    9) Undo last commit         19) Create tag
                                20) List tags
   INFO                         21) Delete tag
   10) Status                   22) Release
   11) Info                     23) GitHub PR
   12) Log                      24) Draft PR
                                25) GitLab MR
   ENV
   26) Whoami                   28) Open browser
   27) Doctor                   29) Branches
    0) Exit
'@ | Write-Host
    $s = Read-Host '  Choose'
    switch ($s) {
      '0'  { return }
      '1'  { Cmd-Push }   '2'  { Cmd-Up }     '3'  { Cmd-All }
      '4'  { Cmd-Tags }   '5'  { Cmd-Force }  '6'  { Cmd-Dry }
      '7'  { Cmd-Del }    '8'  { Cmd-Remote } '9'  { Cmd-Undo }
      '10' { Cmd-Status } '11' { Cmd-Info }   '12' { Cmd-Log }
      '13' { Cmd-Sync }   '14' { Cmd-Pull }   '15' { Cmd-Fetch }
      '16' { Cmd-Prude }  '17' { Cmd-Amend }  '18' { Cmd-Cleanup }
      '19' { Cmd-Tag }    '20' { Cmd-TagList }'21' { Cmd-TagDel }
      '22' { Cmd-Release }'23' { Cmd-Pr }     '24' { Cmd-DraftPr }
      '25' { Cmd-Mr }     '26' { Cmd-Whoami } '27' { Cmd-Doctor }
      '28' { Cmd-Open }   '29' { Cmd-Branches }
      default { Write-Warn 'Invalid.' }
    }
    Read-Host 'Press Enter' | Out-Null
  }
}

function Show-Usage {
  @"
shipgo $VERSION - Git Push Tool

USAGE  shipgo [cmd] [args]

CORE
  push|p  up|first  all [r]  tags [r]  force|f  dry
  del [br]  remote [r] [s] [d]  undo

SYNC
  sync  pull  fetch [r]  prune  amend  cleanup [base]

TAGS
  tag <n> [m]  tag-list  tag-del <n>  release <v> [m]

PR/MR
  pr [title]  draft-pr [title]  mr [title]

INFO
  status|st  info  log [n]  branches  ahead  behind
  whoami  doctor  ping  open  compare [base]

CONFIG
  config [k] [v]  init-config

MISC
  wip  stash  stash-pop  init [dir]  clone <url> [dir]
  menu  help  version

ENV  SHIPGO_YES=1  skip confirmations
"@ | Write-Host
}

switch ($Cmd.ToLower()) {
  ''           { Need-Repo; Show-Menu }
  'menu'       { Need-Repo; Show-Menu }
  'help'       { Show-Usage }
  '-h'         { Show-Usage }
  '--help'     { Show-Usage }
  'version'    { Write-Host "shipgo $VERSION" }
  '-v'         { Write-Host "shipgo $VERSION" }
  '--version'  { Write-Host "shipgo $VERSION" }
  'status'     { Cmd-Status }
  'st'         { Cmd-Status }
  'push'       { Cmd-Push }
  'p'          { Cmd-Push }
  'up'         { Cmd-Up }
  'first'      { Cmd-Up }
  'all'        { Cmd-All }
  'tags'       { Cmd-Tags }
  'force'      { Cmd-Force }
  'f'          { Cmd-Force }
  'dry'        { Cmd-Dry }
  'dry-run'    { Cmd-Dry }
  'del'        { Cmd-Del }
  'delete'     { Cmd-Del }
  'rm'         { Cmd-Del }
  'remote'     { Cmd-Remote }
  'to'         { Cmd-Remote }
  'undo'       { Cmd-Undo }
  'sync'       { Cmd-Sync }
  'pull'       { Cmd-Pull }
  'fetch'      { Cmd-Fetch }
  'prune'      { Cmd-Prude }
  'amend'      { Cmd-Amend }
  'cleanup'    { Cmd-Cleanup }
  'tag'        { Cmd-Tag }
  'tag-list'   { Cmd-TagList }
  'tag-del'    { Cmd-TagDel }
  'release'    { Cmd-Release }
  'pr'         { Cmd-Pr }
  'draft-pr'   { Cmd-DraftPr }
  'mr'         { Cmd-Mr }
  'info'       { Cmd-Info }
  'log'        { Cmd-Log }
  'branches'   { Cmd-Branches }
  'ahead'      { Cmd-Ahead }
  'behind'     { Cmd-Behind }
  'whoami'     { Cmd-Whoami }
  'doctor'     { Cmd-Doctor }
  'ping'       { Cmd-Ping }
  'open'       { Cmd-Open }
  'compare'    { Cmd-Compare }
  'config'     { Cmd-Config }
  'init-config'{ Cmd-Config }
  'wip'        { Cmd-Wip }
  'stash'      { Cmd-Stash }
  'stash-pop'  { Cmd-StashPop }
  'init'       { Cmd-Init }
  'clone'      { Cmd-Clone }
  default      { Write-Err "Unknown: $Cmd  (shipgo help)"; exit 1 }
}