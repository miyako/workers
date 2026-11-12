#DECLARE($worker : Object; $event : Object)
_log("onTerminate callback in process "+Current process name)
var $w : cs.workers.worker
$w:=cs.workers.worker.new(cs.Srv)
$w.timeout:=5
var $r : Boolean
$r:=$w.isRunning(45099)
_check("T-onterm nested isRunning returned without error"; Not($r) & ($w.errors.length=0); JSON Stringify($w.errors))
