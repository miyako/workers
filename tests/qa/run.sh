#!/bin/bash
# Usage: tests/qa/run.sh <tool4d.app | tool4d executable> [mode...]
#   modes: compile main err reent onterm timeout (default: all)
# "compile" runs Compile project on a separate copy of ./workers (tests/qa/Compile) and fails on any
# compile error; the other modes load a copy at tests/qa/Components/workers.4dbase and exercise it.
# Each mode runs headless under a 90s alarm. Prints /tmp/wt2.log and exits 1 if any check FAILs,
# a mode hangs, or no checks ran. macOS only (uses /bin/sleep, ps, pgrep).
set -u
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
TOOL=${1:?tool4d.app or tool4d executable}; shift
[ -d "$TOOL" ] && TOOL="$TOOL/Contents/MacOS/tool4d"
[ -x "$TOOL" ] || { echo "not an executable: $TOOL"; exit 1; }
MODES=${*:-compile main err reent onterm timeout}
rm -rf "$HERE/Components" "$HERE/Compile"; mkdir -p "$HERE/Components" "$HERE/Compile"
cp -R "$ROOT/workers" "$HERE/Components/workers.4dbase"
cp -R "$ROOT/workers" "$HERE/Compile/workers"
rm -f /tmp/wt2.log; status=0
for m in $MODES; do
  perl -e 'alarm shift; exec @ARGV' 90 "$TOOL" "$HERE/Project/qa.4DProject" \
    --dataless --skip-onstartup --startup-method=t_main --user-param="$m" >/dev/null 2>&1
  rc=$?; echo "== mode $m: tool4d rc=$rc" >> /tmp/wt2.log
  [ $rc -eq 142 ] && { echo "FAIL mode $m hung (alarm)" >> /tmp/wt2.log; status=1; }
  grep -q ": mode=$m " /tmp/wt2.log || { echo "FAIL mode $m did not start" >> /tmp/wt2.log; status=1; }
done
pids=$(pgrep -f '/bin/sleep 45'); [ -n "$pids" ] && kill $pids
cat /tmp/wt2.log
grep -q '^[0-9]* .*: FAIL ' /tmp/wt2.log && status=1
grep -q 'FAIL mode' /tmp/wt2.log && status=1
grep -q ': PASS ' /tmp/wt2.log || status=1
echo "pass=$(grep -c ': PASS ' /tmp/wt2.log) fail=$(grep -c 'FAIL ' /tmp/wt2.log)"
exit $status
