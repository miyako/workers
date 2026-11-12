ON ERR CALL("_err")
var $mode : Text
var $r : Real
$r:=Get database parameter(User param value; $mode)
_log("mode="+$mode+" "+Application version(*)+" compiled="+String(Is compiled mode))
var $w; $a; $b; $n; $z : cs.workers.worker
var $i; $t0; $bad : Integer
var $ok : Boolean
var $flag; $opt; $e : Object
var $errs : Collection
Case of 
	: ($mode="compile")
		_compile("C1 compile workers.4DProject"; Folder(fk database folder).file("Compile/workers/Project/workers.4DProject"))
	: ($mode="build")
		//for the compiled runs: compile the component, then the host that uses it (see run.sh)
		_compile("B1 compile workers component for the compiled host"; Folder(fk database folder).file("Build/qa/Components/workers.4dbase/Project/workers.4DProject"))
		_compile("B2 compile qa host"; Folder(fk database folder).file("Build/qa/Project/qa.4DProject"); [Folder(fk database folder).file("Build/qa/Components/workers.4dbase/Project/workers.4DProject")])
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
		$w.startupWait:=0
		For ($i; 1; 100)
			If (Not($w.start(45008; {secs: 45008}))) | (Not($w.isRunning(45008))) | (Not($w.terminate()))
				$bad:=$bad+1
			End if 
		End for 
		DELAY PROCESS(Current process; 60)
		_check("T9 stress 100x start/isRunning/terminate"; ($bad=0) & (_count("sleep 45008")=0); "bad="+String($bad)+" ms="+String(Milliseconds-$t0)+" leftover="+String(_count("sleep 45008")))
		
		//failed launches are reported
		$z:=cs.workers.worker.new(cs.FailSrv)
		$t0:=Milliseconds
		$ok:=$z.start(45019; {})
		$errs:=$z.errors.query("errCode = :1"; -8)
		$e:=($errs.length>0) ? $errs[0] : {}
		_check("T10 process exiting at startup -> false, -8 with exit code and stderr"; Not($ok) & (Num($e.exitCode)=3) & (Position("boom"; String($e.message))>0) & (String($e.stderr)="boom"); JSON Stringify($z.errors))
		_check("T10b waited startupWait (500ms)"; (Milliseconds-$t0)>=450; "ms="+String(Milliseconds-$t0))
		_check("T10c failed server not registered"; Not($z.isRunning(45019)) & ($z.errors.length=0); JSON Stringify($z.errors))
		
		$z:=cs.workers.worker.new(cs.ReadySrv)
		File("/tmp/wt-ready-45021").delete()
		$t0:=Milliseconds
		$ok:=$z.start(45021; {})
		_check("T11 isReady() polled until true"; $ok & ((Milliseconds-$t0)>=900) & File("/tmp/wt-ready-45021").exists & $z.isRunning(45021); "ms="+String(Milliseconds-$t0)+" "+JSON Stringify($z.errors))
		_check("T11b terminate ready server"; $z.terminate() & (_count("sleep 45021")=0); JSON Stringify($z.errors))
		File("/tmp/wt-ready-45021").delete()
		
		$z:=cs.workers.worker.new(cs.NeverSrv)
		$z.timeout:=2
		$t0:=Milliseconds
		$ok:=$z.start(45022; {})
		_check("T11c never ready -> false, -10 after timeout"; Not($ok) & _has($z; -10) & ((Milliseconds-$t0)<6000) & (Num(_get("neverPort"))=45022); "ms="+String(Milliseconds-$t0)+" "+JSON Stringify($z.errors))
		_check("T11d not-ready server was stopped"; (_count("sleep 45022")=0) & Not($z.isRunning(45022)); "procs="+String(_count("sleep 45022")))
		
		$z:=cs.workers.worker.new(cs.WaitSrv)
		$ms:=Milliseconds
		$ok:=$z.start(45025; {})
		$ms:=Milliseconds-$ms
		_check("T11e start()/isReady() that wait() (re-entrant queue) succeed"; $ok & $z.isRunning(45025); "ok="+String($ok)+" ms="+String($ms)+" "+JSON Stringify($z.errors))
		_check("T11f terminate it"; $z.terminate() & (_count("sleep 45025")=0); JSON Stringify($z.errors))
		
		//the port reaches the consumer in a copy of the option
		$z:=cs.workers.worker.new(cs.EchoSrv)
		$opt:={secs: 1}
		$ok:=$z.start(45023; $opt)
		$e:=_get("echo")
		_check("T12 option.port is set to the port"; $ok & (Num($e.port)=45023) & (Num($e.secs)=1) & Undefined($opt.port); JSON Stringify($e))
		$z.terminate()
		$ok:=$z.start(45024; {port: 9})
		$e:=_get("echo")
		_check("T12b an explicit option.port is kept"; $ok & (Num($e.port)=9); JSON Stringify($e))
		$z.terminate()
		
		//real TCP listener: terminate() returns once the port is free
		$a:=cs.workers.worker.new(cs.PortSrv)
		$a.startupWait:=200
		_check("T13 listener start"; $a.start(45030; {}) & (_count("/usr/bin/perl -e use Socket")=1); JSON Stringify($a.errors))
		$ok:=$a.start(45031; {port: 45030})
		_check("T13b second listener on the same TCP port -> false, -8 (bind failed)"; Not($ok) & _has($a; -8) & (Position("bind failed"; JSON Stringify($a.errors))>0) & (_count("/usr/bin/perl -e use Socket")=1); JSON Stringify($a.errors))
		_check("T13c terminate() returns after the process has exited"; $a.terminate(45030) & (_count("/usr/bin/perl -e use Socket")=0); "procs="+String(_count("/usr/bin/perl -e use Socket")))
		$bad:=0
		$t0:=Milliseconds
		_put("race"; 0)
		For ($i; 1; 20)
			If (Not($a.start(45030; {race: True}))) | (Not($a.terminate(45030)))
				$bad:=$bad+1
				_log("T14 #"+String($i)+" "+JSON Stringify($a.errors))
			End if 
		End for 
		_check("T14 stress 20x terminate-then-start on the same TCP port"; ($bad=0) & (Num(_get("race"))=0) & (_count("/usr/bin/perl -e use Socket")=0); "bad="+String($bad)+" started before the previous process exited="+String(_get("race"))+" ms="+String(Milliseconds-$t0))
		
		//compiled: .workers runs preemptively, so consumer code must be thread-safe
		$z:=cs.workers.worker.new(cs.PreSrv)
		$ok:=$z.start(45090; {})
		_check("T15 .workers is preemptive iff compiled"; $ok & (Bool(_get("preemptive"))=Is compiled mode); "preemptive="+String(_get("preemptive")))
		$z.terminate()
		$z:=cs.workers.worker.new(cs.UnsafeSrv)
		$ok:=$z.start(45091; {})
		If (Is compiled mode)
			_check("T16 non-thread-safe consumer -> false with -10529"; Not($ok) & _has($z; -10529); JSON Stringify($z.errors))
		Else 
			_check("T16 non-thread-safe consumer works interpreted"; $ok; JSON Stringify($z.errors))
		End if 
		$z.terminate()
		_check("T16b no leftover"; _count("sleep 45091")=0; "")
		
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
			$flag:=New shared object("done"; False)
			$i:=New process("_bg"; 0; "bg2"; "errwait"; $flag)
			$t0:=Milliseconds
			While ((Milliseconds-$t0)<15000) & (Not($flag.done))
				DELAY PROCESS(Current process; 30)
			End while 
			_check("T-err2 abort after a wait() in start() -> false, -2"; $flag.done & Not(Bool($flag.result)) & Bool($flag.hasAborted); "ms="+String(Milliseconds-$t0))
			$w:=cs.workers.worker.new(cs.BadSrv)
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
		_check("T-timeout late completion was disposed, not registered"; Not($w.isRunning(45014)) & ($w.errors.length=0); JSON Stringify($w.errors))
		DELAY PROCESS(Current process; 60)
		_check("T-timeout no leftover"; _count("sleep 45014")=0; "procs="+String(_count("sleep 45014")))
		_check("T-timeout port usable afterwards"; $w.start(45014; {secs: 45014}) & $w.terminate() & (_count("sleep 45014")=0); JSON Stringify($w.errors))
End case 
_log("quit")
QUIT 4D
