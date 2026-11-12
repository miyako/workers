property class : 4D:C1709.Class
property timeout : Real
property startupWait : Integer
property errors : Collection
property owner : Text

Class constructor($class : 4D:C1709.Class)
	
	var __WORKER__ : cs:C1710.workers
	var __ERRORS__ : Collection
	
	This:C1470.class:=$class
	This:C1470.timeout:=60
	This:C1470.startupWait:=500
	This:C1470.errors:=[]
	This:C1470.owner:=""
	
Function start($port : Integer; $option : Object) : Boolean
	
	If (Not:C34(This:C1470._validate($port)))
		return False:C215
	End if 
	
	If ($option=Null:C1517) || (Value type:C1509($option)#Is object:K8:27)
		return This:C1470._fail(-7; "option is not an object")
	End if 
	
	var $deadline : Real
	$deadline:=Milliseconds:C459+(This:C1470.timeout*1000)
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	If (Current process name:C1392=$signal.description)
		//re-entrant call (consumer start() or a SystemWorker callback): run directly to avoid waiting on ourselves
		//the .workers process cannot wait for the new process here, so there is no startup check
		start(This:C1470.class; $port; $option; $signal)
		If (This:C1470._wait($signal; This:C1470.timeout))
			return Bool:C1537($signal.success)
		End if 
		return False:C215
	End if 
	
	CALL WORKER:C1389($signal.description; Formula:C1597(start); This:C1470.class; $port; $option; $signal)
	CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	
	If (Not:C34(This:C1470._wait($signal; This:C1470.timeout)))
		return False:C215
	End if 
	
	If (String:C10($signal.token)="")
		//already running for this class
		return Bool:C1537($signal.success)
	End if 
	
	var $wait : Real
	$wait:=This:C1470.startupWait
	If (OB Is defined:C1231($option; "startupWait"))
		$wait:=Num:C11($option.startupWait)
	End if 
	
	return This:C1470._confirm($port; String:C10($signal.token); $wait; $deadline)
	
Function terminate($port : Integer) : Boolean
	
	//no argument: every server started by this class; otherwise only $port, if this class owns it
	If (Count parameters:C259=0)
		If (Not:C34(This:C1470._validate(1)))
			return False:C215
		End if 
		$port:=0
	Else 
		If (Not:C34(This:C1470._validate($port)))
			return False:C215
		End if 
	End if 
	
	var $deadline : Real
	$deadline:=Milliseconds:C459+(This:C1470.timeout*1000)
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	If (Current process name:C1392=$signal.description)
		//re-entrant call: the .workers process cannot wait for the processes to exit
		terminate(This:C1470.class; $port; $signal)
		If (This:C1470._wait($signal; This:C1470.timeout))
			return Bool:C1537($signal.success)
		End if 
		return False:C215
	End if 
	
	CALL WORKER:C1389($signal.description; Formula:C1597(terminate); This:C1470.class; $port; $signal)
	CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	
	If (Not:C34(This:C1470._wait($signal; This:C1470.timeout)))
		return False:C215
	End if 
	
	return This:C1470._drain($port; $deadline)
	
Function isRunning($port : Integer) : Boolean
	
	If (Not:C34(This:C1470._validate($port)))
		return False:C215
	End if 
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	If (Current process name:C1392=$signal.description)
		isRunning(This:C1470.class; $port; $signal)
	Else 
		CALL WORKER:C1389($signal.description; Formula:C1597(isRunning); This:C1470.class; $port; $signal)
		CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	End if 
	
	If (This:C1470._wait($signal; This:C1470.timeout))
		return Bool:C1537($signal.isRunning)
	End if 
	
	return False:C215
	
Function _confirm($port : Integer; $token : Text; $wait : Real; $deadline : Real) : Boolean
	
	//runs in the caller's process: the .workers process must never wait (SystemWorker.wait() would run its queued requests re-entrantly)
	//its SystemWorker states are refreshed between messages, so each check is a separate request
	
	var $until : Real
	$until:=Milliseconds:C459+$wait
	If ($until>$deadline)
		$until:=$deadline
	End if 
	If ($until>Milliseconds:C459)
		DELAY PROCESS:C323(Current process:C322; Int:C8(($until-Milliseconds:C459)*60/1000)+1)
	End if 
	
	var $probe : 4D:C1709.Signal
	var $polls : Integer
	
	Repeat 
		
		$probe:=New signal:C1641(".workers")
		CALL WORKER:C1389($probe.description; Formula:C1597(_probe); This:C1470.class; $port; $token; $probe)
		CALL WORKER:C1389($probe.description; Formula:C1597(_settle); $probe)
		
		If (Not:C34(This:C1470._wait($probe; This:C1470._remaining($deadline))))
			//exited (-8), isReady() raised an error, or timed out: make sure nothing is left behind
			This:C1470._discard($port; $token)
			return False:C215
		End if 
		
		If (Bool:C1537($probe.ready))
			return True:C214
		End if 
		
		$polls:=$polls+1
		
		If (Milliseconds:C459>=$deadline)
			This:C1470._discard($port; $token)
			return This:C1470._fail(-10; "the server on port "+String:C10($port)+" was not ready after "+String:C10(This:C1470.timeout)+"s ("+String:C10($polls)+" isReady() calls)")
		End if 
		
		DELAY PROCESS:C323(Current process:C322; 6)
		
	Until (False:C215)
	
Function _discard($port : Integer; $token : Text)
	
	//stop a server whose start failed and wait (briefly) for it to exit so that the port can be reused right away
	
	var $errors : Collection
	$errors:=This:C1470.errors
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	CALL WORKER:C1389($signal.description; Formula:C1597(_abandon); $port; $token; $signal)
	CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	If ($signal.wait(This:C1470._remaining(Milliseconds:C459+5000)))
		This:C1470._drain($port; Milliseconds:C459+5000)
	End if 
	
	This:C1470.errors:=$errors
	
Function _drain($port : Integer; $deadline : Real) : Boolean
	
	//wait until the processes stopped by this class ($port=0: all ports) have actually exited
	
	var $probe : 4D:C1709.Signal
	
	Repeat 
		
		$probe:=New signal:C1641(".workers")
		CALL WORKER:C1389($probe.description; Formula:C1597(_reap); This:C1470.class; $port; $probe)
		CALL WORKER:C1389($probe.description; Formula:C1597(_settle); $probe)
		
		If (Not:C34(This:C1470._wait($probe; This:C1470._remaining($deadline))))
			return False:C215
		End if 
		
		If (Num:C11($probe.remaining)=0)
			return True:C214
		End if 
		
		If (Milliseconds:C459>=$deadline)
			return This:C1470._fail(-9; String:C10($probe.remaining)+" process(es) "+(($port=0) ? "" : ("on port "+String:C10($port)+" "))+"did not exit within "+String:C10(This:C1470.timeout)+"s")
		End if 
		
		DELAY PROCESS:C323(Current process:C322; 2)
		
	Until (False:C215)
	
Function _remaining($deadline : Real) : Real
	
	//seconds left before $deadline, with a floor so that a quick request is not reported as a timeout
	
	var $seconds : Real
	$seconds:=($deadline-Milliseconds:C459)/1000
	If ($seconds<1)
		$seconds:=1
	End if 
	
	return $seconds
	
Function _validate($port : Integer) : Boolean
	
	This:C1470.errors:=[]
	This:C1470.owner:=""
	
	If (Value type:C1509(This:C1470.class)#Is object:K8:27) || (Not:C34(OB Instance of:C1731(This:C1470.class; 4D:C1709.Class)))
		return This:C1470._fail(-6; "class is not a 4D.Class")
	End if 
	
	If ($port<1) || ($port>65535)
		return This:C1470._fail(-4; "invalid port "+String:C10($port))
	End if 
	
	return True:C214
	
Function _fail($code : Integer; $message : Text) : Boolean
	
	This:C1470.errors.push({errCode: $code; message: $message; componentSignature: "wrks"})
	
	return False:C215
	
Function _wait($signal : 4D:C1709.Signal; $seconds : Real) : Boolean
	
	var $done : Boolean
	var $until; $slice : Real
	$until:=Milliseconds:C459+($seconds*1000)
	Repeat 
		$slice:=($until-Milliseconds:C459)/1000
		If ($slice>0.5)
			$slice:=0.5
		End if 
		If ($slice<0)
			$slice:=0
		End if 
		$done:=$signal.wait($slice)
		If (Not:C34($done)) && (Milliseconds:C459<$until) && (Current process name:C1392#$signal.description)
			//a _settle that ran nested inside the request (consumer code that waits) does nothing: post another one
			CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
		End if 
	Until ($done) | (Milliseconds:C459>=$until)
	
	If (Not:C34($done))
		//give up, unless the request has already committed its result (start.4dm sets committed just before it registers)
		Use ($signal)
			If (Not:C34(Bool:C1537($signal.committed)))
				$signal.cancelled:=True:C214
			End if 
		End use 
		If (Not:C34(Bool:C1537($signal.cancelled)))
			$done:=$signal.wait(10)
		End if 
	End if 
	
	If ($done)
		If ($signal.errors#Null:C1517)
			This:C1470.errors:=$signal.errors.copy()
		End if 
		This:C1470.owner:=String:C10($signal.owner)
	Else 
		This:C1470._fail(-1; "timed out after "+String:C10($seconds)+"s waiting for the .workers worker")
	End if 
	
	return This:C1470.errors.length=0
