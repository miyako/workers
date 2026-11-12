#DECLARE($what : Text; $flag : Object)
var $w : cs.workers.worker
$w:=cs.workers.worker.new($what="err" ? cs.BadSrv : cs.ReSrv)
_log("bg start()")
var $r : Boolean
$r:=$w.start(45010; {secs: 1})
_log("bg start() returned "+String($r)+" errors="+JSON Stringify($w.errors))
Use ($flag)
	$flag.result:=$r
	$flag.hasAborted:=_has($w; -2)
	$flag.errorCount:=$w.errors.length
	$flag.done:=True
End use 
