#!/bin/bash
# Usage: tests/qa/run.sh <tool4d.app | tool4d folder | tool4d executable> [mode...]
#   modes: compile main err reent onterm timeout compiled (default: all)
# "compile" runs Compile project on a separate copy of ./workers (tests/qa/Compile) and fails on any
# compile error; the other modes load a copy at tests/qa/Components/workers.4dbase and exercise it.
# "compiled" builds a compiled copy of this host and of the component (tests/qa/Build) and runs the
# main err reent onterm timeout modes again with --opening-mode=compiled, where the .workers worker
# runs preemptively (catches thread-safety problems in code called from it).
# Each mode runs headless under a time limit (90s on macOS, 300s on Windows). Prints tests/qa/out/wt2.log
# and exits 1 if any check FAILs, a mode hangs, or no checks ran.
# macOS (bash, perl, pgrep) or Windows (Git Bash; servers are ping.exe/PowerShell, counted with Get-CimInstance).
set -u
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN= ;; esac
TOOL=${1:?tool4d.app, tool4d folder or tool4d executable}; shift
if [ -d "$TOOL" ]; then
  if [ -n "$WIN" ]; then TOOL="$TOOL/tool4d.exe"; else TOOL="$TOOL/Contents/MacOS/tool4d"; fi
fi
[ -x "$TOOL" ] || { echo "not an executable: $TOOL"; exit 1; }
MODES=${*:-compile main err reent onterm timeout compiled}
RUNTIME_MODES="main err reent onterm timeout"
OUT="$HERE/out"; LOG="$OUT/wt2.log"
# native path for tool4d
native() { if [ -n "$WIN" ]; then cygpath -w "$1"; else echo "$1"; fi; }
# stop leftover servers (spawned by the consumer classes) and tool4d instances
cleanup() {
  if [ -n "$WIN" ]; then
    powershell -NoProfile -NonInteractive -Command "Get-CimInstance Win32_Process | Where-Object { \$_.ProcessId -ne \$PID -and ((\$_.Name -eq 'PING.EXE' -and \$_.CommandLine -match ' -n 45\\d\\d\\d 127\\.0\\.0\\.1') -or (\$_.Name -eq 'powershell.exe' -and \$_.CommandLine -like '*TcpListener*')) } | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force -ErrorAction SilentlyContinue }"
  else
    pids=$(pgrep -f '/bin/sleep 45|/usr/bin/perl -e use Socket'); [ -n "$pids" ] && kill $pids
  fi
}
rm -rf "$HERE/Components" "$HERE/Compile" "$HERE/Build" "$OUT"; mkdir -p "$HERE/Components" "$HERE/Compile" "$OUT"
cp -R "$ROOT/workers" "$HERE/Components/workers.4dbase"
cp -R "$ROOT/workers" "$HERE/Compile/workers"
status=0
# run <label> <project> <mode> [tool4d options]
run() {
  local label=$1 project=$2 m=$3 rc hung=; shift 3
  if [ -n "$WIN" ]; then
    timeout -k 10 300 "$TOOL" "$(native "$project")" \
      --dataless --skip-onstartup --startup-method=t_main --user-param="$m" "$@" >/dev/null 2>&1
    rc=$?; [ $rc -eq 124 ] || [ $rc -eq 137 ] && hung=1
    [ -n "$hung" ] && taskkill //F //T //IM tool4d.exe >/dev/null 2>&1
  else
    perl -e 'alarm shift; exec @ARGV' 90 "$TOOL" "$project" \
      --dataless --skip-onstartup --startup-method=t_main --user-param="$m" "$@" >/dev/null 2>&1
    rc=$?; [ $rc -eq 142 ] && hung=1
  fi
  echo "== mode $label: tool4d rc=$rc" >> "$LOG"
  [ -n "$hung" ] && { echo "FAIL mode $label hung (time limit)" >> "$LOG"; status=1; }
}
for m in $MODES; do
  if [ "$m" = compiled ]; then
    mkdir -p "$HERE/Build/qa/Components"
    cp -R "$HERE/Project" "$HERE/Build/qa/Project"
    cp -R "$ROOT/workers" "$HERE/Build/qa/Components/workers.4dbase"
    run build "$HERE/Project/qa.4DProject" build
    grep -q ': PASS B2 ' "$LOG" || { echo "FAIL mode compiled: build failed" >> "$LOG"; status=1; continue; }
    for c in $RUNTIME_MODES; do
      run "compiled $c" "$HERE/Build/qa/Project/qa.4DProject" "$c" --opening-mode=compiled
      grep -q ": mode=$c .* compiled=True" "$LOG" || { echo "FAIL mode compiled $c did not start compiled" >> "$LOG"; status=1; }
    done
  else
    run "$m" "$HERE/Project/qa.4DProject" "$m"
    grep -q ": mode=$m " "$LOG" || { echo "FAIL mode $m did not start" >> "$LOG"; status=1; }
  fi
done
cleanup
cat "$LOG"
grep -q '^[0-9]* .*: FAIL ' "$LOG" && status=1
grep -q 'FAIL mode' "$LOG" && status=1
grep -q ': PASS ' "$LOG" || status=1
echo "pass=$(grep -c ': PASS ' "$LOG") fail=$(grep -c 'FAIL ' "$LOG")"
exit $status
