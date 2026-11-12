ON ERR CALL("_err")
var $mode : Text
var $r : Real
$r:=Get database parameter(User param value; $mode)
_log("mode="+$mode+" "+Application version(*)+" compiled="+String(Is compiled mode))
var $w; $a; $b; $n; $z : cs.workers.worker
var $i; $t0; $bad : Integer
var $ok : Boolean
var $flag : Object
Case of 
	: ($mode="compile")
		var $project : 4D.File
		var $res : Object
		var $e : Object
		var $msgs : Text
		$project:=Folder(fk database folder).file("Compile/workers/Project/workers.4DProject")
		If ($project.exists)
			$res:=Compile project($project)
			$bad:=0
			$msgs:=""
			If ($res.errors#Null)
				For each ($e; $res.errors)
					If (Bool($e.isError))
						$bad:=$bad+1
						$msgs:=$msgs+" "+String($e.message)+(($e.code#Null) ? (" @"+String($e.code.path)+":"+String($e.lineInFile)) : "")+";"
					End if 
				End for each 
			End if 
			_check("C1 compile workers.4DProject"; Bool($res.success) & ($bad=0); "errors="+String($bad)+$msgs)
		Else 
			_check("C1 compile workers.4DProject"; False; "missing "+$project.platformPath)
		End if 
	: ($mode="main")
		$w:=cs.workers.worker.new(cs.Srv)
		_check("T0 terminate before start is a no-op"; $w.terminate(); JSON Stringify($w.errors))
		$ok:=$w.start(45001; {secs: 45001})
		_check("T1 start"; $ok & $w.isRunning(45001) & (_count("sleep 45001")=1); JSON Stringify($w.errors))
		$ok:=$w.start(45001; {secs: 45001})
		_check("T2 start same port again is a no-op"; $ok & (_count("sleep 45001")=1); "procs="+String(_count("sleep 45001")))
		_check("T3 terminate"; $w.terminate(); JSON Stringify($w.errors))
		DELAY PROCESS(Current process; 60)
		_check("T3b stopped"; Not($w.isRunning(45001)) & (_count("sleep 45001")=0); "")
		
		_check("T4 start(0) rejected"; Not($w.start(0; {secs: 45000})) & _has($w; -4); JSON Stringify($w.errors))
		_check("T4b start(-1) rejected"; Not($w.start(-1; {secs: 45000})) & _has($w; -4); "")
		_check("T4c start(70000) rejected"; Not($w.start(70000; {secs: 45000})) & _has($w; -4); "")
		_check("T4d nothing spawned for invalid ports"; _count("sleep 45000")=0; "procs="+String(_count("sleep 45000")))
		_check("T4e isRunning(0) false with -4"; Not($w.isRunning(0)) & _has($w; -4); "")
		_check("T4f terminate(70000) false with -4"; Not($w.terminate(70000)) & _has($w; -4); "")
		_check("T5 Null option rejected"; Not($w.start(45011; Null)) & _has($w; -7); JSON Stringify($w.errors))
		
		$a:=cs.workers.worker.new(cs.Srv)
		$b:=cs.workers.worker.new(cs.Srv2)
		_check("T6 A.start"; $a.start(45003; {secs: 45003}); JSON Stringify($a.errors))
		$ok:=$b.start(45003; {secs: 45003})
		_check("T6a B.start on A's port refused"; Not($ok) & _has($b; -5) & ($b.owner="Srv") & (_count("sleep 45903")=0) & (_count("sleep 45003")=1); "owner="+$b.owner+" "+JSON Stringify($b.errors))
		_check("T6b B.isRunning on A's port false, owner=Srv"; Not($b.isRunning(45003)) & ($b.owner="Srv"); "owner="+$b.owner)
		_check("T6c B.terminate(A's port) refused"; Not($b.terminate(45003)) & _has($b; -5) & (_count("sleep 45003")=1); "")
		_check("T6d B.start other port"; $b.start(45013; {secs: 45013}) & (_count("sleep 45913")=1); "")
		_check("T6e B.terminate()"; $b.terminate(); "")
		DELAY PROCESS(Current process; 60)
		_check("T6f B.terminate() left A running"; $a.isRunning(45003) & (_count("sleep 45003")=1) & (_count("sleep 45913")=0); "")
		_check("T6g A.terminate(45003)"; $a.terminate(45003); "")
		DELAY PROCESS(Current process; 60)
		_check("T6h A stopped"; Not($a.isRunning(45003)) & (_count("sleep 45003")=0); "")
		_check("T6i freed port reusable by B"; $b.start(45003; {secs: 45003}) & (_count("sleep 45903")=1); "")
		$b.terminate()
		
		$n:=cs.workers.worker.new(cs.Wrap)
		$ok:=$n.start(45004; {secs: 45004})
		$ok:=$ok & $n.start(45004; {secs: 45004})
		_check("T7 wrapper result registered once"; $ok & $n.isRunning(45004) & (_count("sleep 45004")=1); "procs="+String(_count("sleep 45004")))
		$n.terminate()
		DELAY PROCESS(Current process; 60)
		_check("T7b wrapper terminated"; _count("sleep 45004")=0; "procs="+String(_count("sleep 45004")))
		
		$z:=cs.workers.worker.new(cs.NullSrv)
		_check("T8 Null result -> false, -3"; Not($z.start(45015; {})) & _has($z; -3) & Not($z.isRunning(45015)); JSON Stringify($z.errors))
		$z:=cs.workers.worker.new(cs.TermObj)
		_check("T8b non-worker result with terminate() -> false, -3"; Not($z.start(45016; {secs: 45016})) & _has($z; -3); JSON Stringify($z.errors))
		DELAY PROCESS(Current process; 60)
		_check("T8c non-worker result was disposed"; _count("sleep 45016")=0; "procs="+String(_count("sleep 45016")))
		$z:=cs.workers.worker.new(Null)
		_check("T8d Null class -> false, -6"; Not($z.start(45017; {})) & _has($z; -6); JSON Stringify($z.errors))
		
		$bad:=0
		$t0:=Milliseconds
		For ($i; 1; 100)
			If (Not($w.start(45008; {secs: 45008}))) | (Not($w.isRunning(45008))) | (Not($w.terminate()))
				$bad:=$bad+1
			End if 
		End for 
		DELAY PROCESS(Current process; 60)
		_check("T9 stress 100x start/isRunning/terminate"; ($bad=0) & (_count("sleep 45008")=0); "bad="+String($bad)+" ms="+String(Milliseconds-$t0)+" leftover="+String(_count("sleep 45008")))
		
	: ($mode="err") | ($mode="reent")
		$flag:=New shared object("done"; False)
		$i:=New process("_bg"; 0; "bg"; $mode; $flag)
		$t0:=Milliseconds
		While ((Milliseconds-$t0)<15000) & (Not($flag.done))
			DELAY PROCESS(Current process; 30)
		End while 
		_check("T-"+$mode+" caller returned"; $flag.done; "ms="+String(Milliseconds-$t0))
		If ($mode="err")
			_check("T-err start() false with errors"; Not(Bool($flag.result)) & (Num($flag.errorCount)>0); "aborted(-2)="+String($flag.hasAborted))
			$w:=cs.workers.worker.new(cs.Srv)
			_check("T-err worker usable afterwards"; $w.start(45012; {secs: 45012}) & (_count("sleep 45012")=1); JSON Stringify($w.errors))
			$w.terminate()
		Else 
			_check("T-reent start() true"; Bool($flag.result) & (_count("sleep 45007")=1); "")
			$w:=cs.workers.worker.new(cs.ReSrv)
			$w.terminate()
		End if 
		
	: ($mode="onterm")
		$w:=cs.workers.worker.new(cs.OnTermSrv)
		_check("T-onterm start"; $w.start(45018; {}); JSON Stringify($w.errors))
		DELAY PROCESS(Current process; 240)
		$w.timeout:=5
		$t0:=Milliseconds
		$ok:=$w.isRunning(45018)
		_check("T-onterm .workers still responsive after callback"; Not(_has($w; -1)) & Not($ok); "ms="+String(Milliseconds-$t0)+" "+JSON Stringify($w.errors))
		
	: ($mode="timeout")
		$w:=cs.workers.worker.new(cs.SlowSrv)
		$w.timeout:=1
		$t0:=Milliseconds
		$ok:=$w.start(45014; {secs: 45014})
		_check("T-timeout start() false with -1 within ~1s"; Not($ok) & _has($w; -1) & ((Milliseconds-$t0)<3000); "ms="+String(Milliseconds-$t0))
		DELAY PROCESS(Current process; 360)
		$w.timeout:=60
		_check("T-timeout late completion is registered and terminable"; $w.isRunning(45014) & $w.terminate(); JSON Stringify($w.errors))
		DELAY PROCESS(Current process; 60)
		_check("T-timeout no leftover"; _count("sleep 45014")=0; "")
End case 
_log("quit")
QUIT 4D
