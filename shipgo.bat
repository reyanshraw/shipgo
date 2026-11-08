@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Enable ANSI colors in Windows CMD
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

set "VERSION=1.0.0"
set "DEFAULT_REMOTE=origin"
set "PROTECTED_BRANCHES=main master develop"

where git >nul 2>&1 || (echo [91m[X][0m git not found. & exit /b 1)

set "CMD=%~1"
if not "%CMD%"=="" shift
if "%CMD%"==""              goto :menu
if /i "%CMD%"=="menu"       goto :menu
if /i "%CMD%"=="help"       goto :usage
if /i "%CMD%"=="version"    goto :version
if /i "%CMD%"=="-v"         goto :version
if /i "%CMD%"=="push"       goto :do_push
if /i "%CMD%"=="p"          goto :do_push
if /i "%CMD%"=="up"         goto :do_up
if /i "%CMD%"=="first"      goto :do_up
if /i "%CMD%"=="all"        goto :do_all
if /i "%CMD%"=="tags"       goto :do_tags
if /i "%CMD%"=="force"      goto :do_force
if /i "%CMD%"=="f"          goto :do_force
if /i "%CMD%"=="dry"        goto :do_dry
if /i "%CMD%"=="del"        goto :do_del
if /i "%CMD%"=="rm"         goto :do_del
if /i "%CMD%"=="remote"     goto :do_remote
if /i "%CMD%"=="to"         goto :do_remote
if /i "%CMD%"=="info"       goto :do_info
if /i "%CMD%"=="log"        goto :do_log
if /i "%CMD%"=="undo"       goto :do_undo
if /i "%CMD%"=="sync"       goto :do_sync
if /i "%CMD%"=="pull"       goto :do_pull
if /i "%CMD%"=="fetch"      goto :do_fetch
if /i "%CMD%"=="prune"      goto :do_prune
if /i "%CMD%"=="amend"      goto :do_amend
if /i "%CMD%"=="cleanup"    goto :do_cleanup
if /i "%CMD%"=="tag"        goto :do_tag
if /i "%CMD%"=="tag-list"   goto :do_tag_list
if /i "%CMD%"=="tag-del"    goto :do_tag_del
if /i "%CMD%"=="release"    goto :do_release
if /i "%CMD%"=="pr"         goto :do_pr
if /i "%CMD%"=="draft-pr"   goto :do_draft_pr
if /i "%CMD%"=="mr"         goto :do_mr
if /i "%CMD%"=="branches"   goto :do_branches
if /i "%CMD%"=="ahead"      goto :do_ahead
if /i "%CMD%"=="behind"     goto :do_behind
if /i "%CMD%"=="whoami"     goto :do_whoami
if /i "%CMD%"=="doctor"     goto :do_doctor
if /i "%CMD%"=="ping"       goto :do_ping
if /i "%CMD%"=="open"       goto :do_open
if /i "%CMD%"=="wip"        goto :do_wip
if /i "%CMD%"=="stash"      goto :do_stash
if /i "%CMD%"=="stash-pop"  goto :do_stash_pop
echo [91m[X][0m Unknown: %CMD%   (shipgo help)
exit /b 1

:menu
call :need_repo || exit /b 1
:menu_loop
cls
call :get_branch
echo.
echo   [96mshipgo %VERSION%[0m   branch: [93m%BRANCH%[0m
echo   [90m------------------------------------------------------------[0m
echo    1^) Push                    13^) Sync
echo    2^) First push (-u)         14^) Pull --rebase
echo    3^) All branches            15^) Fetch --prune
echo    4^) Tags                    16^) Prune
echo    5^) Force push              17^) Amend + force
echo    6^) Dry run                 18^) Cleanup merged
echo    7^) Delete remote branch
echo    8^) Push remote/branch      19^) Create tag
echo    9^) Undo last commit        20^) List tags
echo                                21^) Delete tag
echo   10^) Status                  22^) Release
echo   11^) Info                    23^) GitHub PR
echo   12^) Log                     24^) Draft PR
echo                                25^) GitLab MR
echo   26^) Whoami                  28^) Open browser
echo   27^) Doctor                  29^) Branches
echo    0^) Exit
echo.
set "SEL="
set /p "SEL=  Choose> "
if not defined SEL goto :menu_loop
if "%SEL%"=="0"  exit /b 0
if "%SEL%"=="1"  call :do_push
if "%SEL%"=="2"  call :do_up
if "%SEL%"=="3"  call :do_all
if "%SEL%"=="4"  call :do_tags
if "%SEL%"=="5"  call :do_force
if "%SEL%"=="6"  call :do_dry
if "%SEL%"=="7"  call :do_del
if "%SEL%"=="8"  call :do_remote
if "%SEL%"=="9"  call :do_undo
if "%SEL%"=="10" call :do_status
if "%SEL%"=="11" call :do_info
if "%SEL%"=="12" call :do_log
if "%SEL%"=="13" call :do_sync
if "%SEL%"=="14" call :do_pull
if "%SEL%"=="15" call :do_fetch
if "%SEL%"=="16" call :do_prune
if "%SEL%"=="17" call :do_amend
if "%SEL%"=="18" call :do_cleanup
if "%SEL%"=="19" call :do_tag
if "%SEL%"=="20" call :do_tag_list
if "%SEL%"=="21" call :do_tag_del
if "%SEL%"=="22" call :do_release
if "%SEL%"=="23" call :do_pr
if "%SEL%"=="24" call :do_draft_pr
if "%SEL%"=="25" call :do_mr
if "%SEL%"=="26" call :do_whoami
if "%SEL%"=="27" call :do_doctor
if "%SEL%"=="28" call :do_open
if "%SEL%"=="29" call :do_branches
echo.& pause >nul
goto :menu_loop

:do_push
call :need_repo || exit /b 1
call :get_branch & call :get_upstream
if defined UPSTREAM goto :dp_have
echo [93m[!][0m No upstream for "%BRANCH%".
call :confirm "Push and set upstream %DEFAULT_REMOTE%/%BRANCH%" || (echo Aborted.&exit /b 0)
git push -u %DEFAULT_REMOTE% "%BRANCH%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Tracking %DEFAULT_REMOTE%/%BRANCH%
exit /b 0
:dp_have
echo [96m[*][0m Pushing %BRANCH% to %UPSTREAM% ...
git push || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Push complete.
exit /b 0

:do_up
call :need_repo || exit /b 1
call :get_branch
set "REMOTE=%~1"
if "%REMOTE%"=="" set "REMOTE=%DEFAULT_REMOTE%"
git push -u "%REMOTE%" "%BRANCH%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Tracking %REMOTE%/%BRANCH%
exit /b 0

:do_all
call :need_repo || exit /b 1
set "REMOTE=%~1"& if "%REMOTE%"=="" set "REMOTE=%DEFAULT_REMOTE%"
git push --all "%REMOTE%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m All branches pushed.
exit /b 0

:do_tags
call :need_repo || exit /b 1
set "REMOTE=%~1"& if "%REMOTE%"=="" set "REMOTE=%DEFAULT_REMOTE%"
git push --tags "%REMOTE%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m All tags pushed.
exit /b 0

:do_force
call :need_repo || exit /b 1
call :get_branch
call :is_protected "%BRANCH%" && echo [93m[!][0m WARNING: protected branch.
call :confirm "Force push %BRANCH% (--force-with-lease)" || (echo Aborted.&exit /b 0)
git push --force-with-lease || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Force-pushed.
exit /b 0

:do_dry
call :need_repo || exit /b 1
git push --dry-run %1 %2 || (echo [91m[X][0m Dry run failed.&exit /b 1)
echo [92m[OK][0m Dry run OK.
exit /b 0

:do_del
call :need_repo || exit /b 1
set "TARGET=%~1"
if not "%TARGET%"=="" goto :del_go
git branch -r
set /p "TARGET=Remote branch: "
:del_go
if "%TARGET%"=="" (echo Aborted.&exit /b 0)
set "TARGET=%TARGET:origin/=%"
call :confirm "Delete %TARGET% on origin" || (echo Aborted.&exit /b 0)
git push origin --delete "%TARGET%" || (echo [91m[X][0m Delete failed.&exit /b 1)
echo [92m[OK][0m Deleted.
exit /b 0

:do_remote
call :need_repo || exit /b 1
call :get_branch
set "REMOTE=%~1"& if "%REMOTE%"=="" set "REMOTE=%DEFAULT_REMOTE%"
set "SRC=%~2"& if "%SRC%"=="" set "SRC=%BRANCH%"
set "DST=%~3"& if "%DST%"=="" set "DST=%SRC%"
git push "%REMOTE%" "%SRC%:%DST%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Done.
exit /b 0

:do_info
call :need_repo || exit /b 1
echo === Remotes ===& git remote -v
echo.& echo === Branches ===& git branch -vv
echo.& echo === Status ===& git status -sb
exit /b 0

:do_log
call :need_repo || exit /b 1
git log --oneline --graph --decorate -n 15
exit /b 0

:do_undo
call :need_repo || exit /b 1
call :confirm "Undo last commit (soft)" || (echo Aborted.&exit /b 0)
git reset --soft HEAD~1 || (echo [91m[X][0m Reset failed.&exit /b 1)
echo [92m[OK][0m Undone. To update remote: shipgo force
exit /b 0

:do_sync
call :need_repo || exit /b 1
git fetch --all --prune || (echo [91m[X][0m Fetch failed.&exit /b 1)
git pull --rebase --autostash || (echo [91m[X][0m Pull failed.&exit /b 1)
call :do_push
exit /b %errorlevel%

:do_pull
call :need_repo || exit /b 1
git pull --rebase --autostash || (echo [91m[X][0m Pull failed.&exit /b 1)
echo [92m[OK][0m Pulled.
exit /b 0

:do_fetch
call :need_repo || exit /b 1
set "REMOTE=%~1"& if "%REMOTE%"=="" set "REMOTE=%DEFAULT_REMOTE%"
git fetch --all --prune "%REMOTE%" || (echo [91m[X][0m Fetch failed.&exit /b 1)
echo [92m[OK][0m Fetched.
exit /b 0

:do_prune
call :need_repo || exit /b 1
git fetch --prune --all || (echo [91m[X][0m Prune failed.&exit /b 1)
echo [92m[OK][0m Pruned.
exit /b 0

:do_amend
call :need_repo || exit /b 1
call :get_upstream & call :ahead_count
if defined UPSTREAM if "%AHEAD%"=="0" (
  echo [93m[!][0m Already pushed. Force push required.
  call :confirm "Continue" || (echo Aborted.&exit /b 0)
)
git commit --amend --no-edit || (echo [91m[X][0m Amend failed.&exit /b 1)
git push --force-with-lease || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Amended and pushed.
exit /b 0

:do_cleanup
call :need_repo || exit /b 1
set "BASE=%~1"& if "%BASE%"=="" set "BASE=main"
git show-ref --verify --quiet "refs/heads/%BASE%" || set "BASE=master"
for /f "tokens=1" %%b in ('git branch --merged %BASE% ^| findstr /v /r "^^\* ^ %BASE%$ ^ master$ ^ main$"') do (
  echo   - %%b & git branch -d %%b
)
echo [92m[OK][0m Cleanup done.
exit /b 0

:do_tag
call :need_repo || exit /b 1
set "NAME=%~1"& set "MSG=%~2"
if "%NAME%"=="" (echo Usage: shipgo tag ^<name^> [msg]&exit /b 1)
if "%MSG%"=="" set "MSG=Release %NAME%"
git tag -a "%NAME%" -m "%MSG%" || (echo [91m[X][0m Tag failed.&exit /b 1)
git push origin "%NAME%" || (echo [91m[X][0m Push failed.&exit /b 1)
echo [92m[OK][0m Tag %NAME% pushed.
exit /b 0

:do_tag_list
call :need_repo || exit /b 1
git tag --sort=-v:refname
exit /b 0

:do_tag_del
call :need_repo || exit /b 1
set "NAME=%~1"& if "%NAME%"=="" (echo Usage: shipgo tag-del ^<name^>&exit /b 1)
call :confirm "Delete tag %NAME% local+remote" || (echo Aborted.&exit /b 0)
git tag -d "%NAME%" 2>nul
git push origin ":refs/tags/%NAME%" 2>nul && echo [92m[OK][0m Deleted.
exit /b 0

:do_release
set "VER=%~1"& set "MSG=%~2"
if "%VER%"=="" (echo Usage: shipgo release ^<version^> [msg]&exit /b 1)
if "%MSG%"=="" set "MSG=Release %VER%"
call :need_repo || exit /b 1
git tag -a "%VER%" -m "%MSG%" && git push origin "%VER%" || (echo [91m[X][0m Release failed.&exit /b 1)
echo [92m[OK][0m Release %VER% pushed.
exit /b 0

:do_pr
call :need_repo || exit /b 1
where gh >nul 2>&1 || (echo [91m[X][0m gh not installed.&exit /b 1)
call :do_push
set "T=%~1"
if "%T%"=="" (gh pr create --fill --web) else (gh pr create --title "%T%" --body "" --web)
exit /b %errorlevel%

:do_draft_pr
call :need_repo || exit /b 1
where gh >nul 2>&1 || (echo [91m[X][0m gh not installed.&exit /b 1)
call :do_push
set "T=%~1"
if "%T%"=="" (gh pr create --draft --fill --web) else (gh pr create --draft --title "%T%" --body "" --web)
exit /b %errorlevel%

:do_mr
call :need_repo || exit /b 1
where glab >nul 2>&1 || (echo [91m[X][0m glab not installed.&exit /b 1)
call :do_push
set "T=%~1"
if "%T%"=="" (glab mr create --fill --web) else (glab mr create --title "%T%" --web)
exit /b %errorlevel%

:do_branches
call :need_repo || exit /b 1
echo === Local ===& git branch -vv
echo.& echo === Remote ===& git branch -r
exit /b 0

:do_ahead
call :need_repo || exit /b 1
call :ahead_count
echo %AHEAD% commit(s) ahead
exit /b 0

:do_behind
call :need_repo || exit /b 1
call :behind_count
echo %BEHIND% commit(s) behind
exit /b 0

:do_whoami
echo user.name:  & git config --get user.name
echo user.email: & git config --get user.email
echo signing:    & git config --get commit.gpgsign
echo editor:     & git config --get core.editor
exit /b 0

:do_doctor
echo === Health ===
git --version
where gh  >nul 2>&1 && gh --version  || echo gh:  MISSING
where glab>nul 2>&1 && glab --version|| echo glab: MISSING
git config --get user.name
git config --get user.email
exit /b 0

:do_ping
call :need_repo || exit /b 1
git ls-remote --heads origin >nul 2>&1 && (echo [92m[OK][0m Reachable) || (echo [93m[!][0m Unreachable)
exit /b 0

:do_open
call :need_repo || exit /b 1
for /f "delims=" %%u in ('git config --get remote.origin.url') do set "URL=%%u"
if not defined URL (echo [91m[X][0m No origin.&exit /b 1)
set "URL=%URL:.git=%"
set "URL=%URL:git@github.com:=https://github.com/%"
set "URL=%URL:git@gitlab.com:=https://gitlab.com/%"
start "" "%URL%"
exit /b 0

:do_wip
call :need_repo || exit /b 1
git add -A
git commit -m "WIP" --no-verify 2>nul || echo [93m[!][0m Nothing to commit.
call :do_push
exit /b 0

:do_stash
call :need_repo || exit /b 1
git stash push -u -m shipgo & echo [92m[OK][0m Stashed.
exit /b 0

:do_stash_pop
call :need_repo || exit /b 1
git stash pop & echo [92m[OK][0m Popped.
exit /b 0

:need_repo
git rev-parse --is-inside-work-tree >nul 2>&1 || (echo [91m[X][0m Not inside a Git repository.&exit /b 1)
exit /b 0

:get_branch
set "BRANCH="
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%b"
if not defined BRANCH set "BRANCH=HEAD"
exit /b 0

:get_upstream
set "UPSTREAM="
for /f "delims=" %%u in ('git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2^>nul') do set "UPSTREAM=%%u"
exit /b 0

:ahead_count
set "AHEAD=0"
for /f "delims=" %%n in ('git rev-list --count "@{u}..HEAD" 2^>nul') do set "AHEAD=%%n"
exit /b 0

:behind_count
set "BEHIND=0"
for /f "delims=" %%n in ('git rev-list --count "HEAD..@{u}" 2^>nul') do set "BEHIND=%%n"
exit /b 0

:is_protected
for %%p in (%PROTECTED_BRANCHES%) do if /i "%%p"=="%~1" exit /b 0
exit /b 1

:confirm
set "ANS="
set /p "ANS=%~1 [y/N]: "
if /i "%ANS%"=="y"   exit /b 0
if /i "%ANS%"=="yes" exit /b 0
exit /b 1

:usage
echo.
echo [96mshipgo %VERSION%[0m - Git Push Tool
echo.
echo   push^|p  up^|first  all  tags  force^|f  dry  del  remote  undo
echo   sync  pull  fetch  prune  amend  cleanup
echo   tag  tag-list  tag-del  release
echo   pr  draft-pr  mr
echo   status^|st  info  log  branches  ahead  behind
echo   whoami  doctor  ping  open  compare
echo   config  init-config
echo   wip  stash  stash-pop  init  clone  menu  help  version
echo.
echo   ENV  SHIPGO_YES=1  skips confirmations
echo.
exit /b 0

:version
echo shipgo %VERSION%
exit /b 0