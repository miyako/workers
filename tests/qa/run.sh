#!/bin/bash
# Usage: tests/qa/run.sh <tool4d.app> [mode...]   (modes: main err reent onterm timeout)
# Copies ./workers into tests/qa/Components/workers.4dbase, runs each mode headless with a 90s alarm,
# prints /tmp/wt2.log and exits 1 if any check FAILs, a mode hangs, or no checks ran.
set -u
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
TOOL=${1:?tool4d.app}; shift
MODES=${*:-main err reent onterm timeout}
rm -rf "$HERE/Components"; mkdir -p "$HERE/Components"
cp -R "$ROOT/workers" "$HERE/Components/workers.4dbase"
rm -f /tmp/wt2.log; status=0
for m in $MODES; do
  perl -e 'alarm shift; exec @ARGV' 90 "$TOOL/Contents/MacOS/tool4d" "$HERE/Project/qa.4DProject" \
    --dataless --skip-onstartup --startup-method=t_main --user-param="$m" >/dev/null 2>&1
  rc=$?; echo "== mode $m: tool4d rc=$rc" >> /tmp/wt2.log
  [ $rc -eq 142 ] && { echo "FAIL mode $m hung (alarm)" >> /tmp/wt2.log; status=1; }
done
pids=$(pgrep -f '/bin/sleep 45'); [ -n "$pids" ] && kill $pids
cat /tmp/wt2.log
grep -q '^[0-9]* .*: FAIL ' /tmp/wt2.log && status=1
grep -q 'FAIL mode' /tmp/wt2.log && status=1
grep -q ': PASS ' /tmp/wt2.log || status=1
echo "pass=$(grep -c ': PASS ' /tmp/wt2.log) fail=$(grep -c 'FAIL ' /tmp/wt2.log)"
exit $status
