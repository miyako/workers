#!/bin/bash
# Usage: tests/qa/run.sh <tool4d.app | tool4d executable> [mode...]
#   modes: compile main err reent onterm timeout compiled (default: all)
# "compile" runs Compile project on a separate copy of ./workers (tests/qa/Compile) and fails on any
# compile error; the other modes load a copy at tests/qa/Components/workers.4dbase and exercise it.
# "compiled" builds a compiled copy of this host and of the component (tests/qa/Build) and runs the
# main err reent onterm timeout modes again with --opening-mode=compiled, where the .workers worker
# runs preemptively (catches thread-safety problems in code called from it).
# Each mode runs headless under a 90s alarm. Prints /tmp/wt2.log and exits 1 if any check FAILs,
# a mode hangs, or no checks ran. macOS only (uses /bin/sleep, ps, pgrep).
set -u
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
TOOL=${1:?tool4d.app or tool4d executable}; shift
[ -d "$TOOL" ] && TOOL="$TOOL/Contents/MacOS/tool4d"
[ -x "$TOOL" ] || { echo "not an executable: $TOOL"; exit 1; }
MODES=${*:-compile main err reent onterm timeout compiled}
RUNTIME_MODES="main err reent onterm timeout"
rm -rf "$HERE/Components" "$HERE/Compile" "$HERE/Build"; mkdir -p "$HERE/Components" "$HERE/Compile"
cp -R "$ROOT/workers" "$HERE/Components/workers.4dbase"
cp -R "$ROOT/workers" "$HERE/Compile/workers"
rm -f /tmp/wt2.log /tmp/wt-ready-* /tmp/wt-kv-*; status=0
# run <label> <project> <mode> [tool4d options]
run() {
  local label=$1 project=$2 m=$3; shift 3
  perl -e 'alarm shift; exec @ARGV' 90 "$TOOL" "$project" \
    --dataless --skip-onstartup --startup-method=t_main --user-param="$m" "$@" >/dev/null 2>&1
  rc=$?; echo "== mode $label: tool4d rc=$rc" >> /tmp/wt2.log
  [ $rc -eq 142 ] && { echo "FAIL mode $label hung (alarm)" >> /tmp/wt2.log; status=1; }
}
for m in $MODES; do
  if [ "$m" = compiled ]; then
    mkdir -p "$HERE/Build/qa/Components"
    cp -R "$HERE/Project" "$HERE/Build/qa/Project"
    cp -R "$ROOT/workers" "$HERE/Build/qa/Components/workers.4dbase"
    run build "$HERE/Project/qa.4DProject" build
    grep -q ': PASS B2 ' /tmp/wt2.log || { echo "FAIL mode compiled: build failed" >> /tmp/wt2.log; status=1; continue; }
    for c in $RUNTIME_MODES; do
      run "compiled $c" "$HERE/Build/qa/Project/qa.4DProject" "$c" --opening-mode=compiled
      grep -q ": mode=$c .* compiled=True" /tmp/wt2.log || { echo "FAIL mode compiled $c did not start compiled" >> /tmp/wt2.log; status=1; }
    done
  else
    run "$m" "$HERE/Project/qa.4DProject" "$m"
    grep -q ": mode=$m " /tmp/wt2.log || { echo "FAIL mode $m did not start" >> /tmp/wt2.log; status=1; }
  fi
done
pids=$(pgrep -f '/bin/sleep 45|/usr/bin/perl -e use Socket'); [ -n "$pids" ] && kill $pids
cat /tmp/wt2.log
grep -q '^[0-9]* .*: FAIL ' /tmp/wt2.log && status=1
grep -q 'FAIL mode' /tmp/wt2.log && status=1
grep -q ': PASS ' /tmp/wt2.log || status=1
echo "pass=$(grep -c ': PASS ' /tmp/wt2.log) fail=$(grep -c 'FAIL ' /tmp/wt2.log)"
exit $status
