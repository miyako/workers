property class : 4D:C1709.Class
property timeout : Real
property errors : Collection
property owner : Text

Class constructor($class : 4D:C1709.Class)
	
	var __WORKER__ : cs:C1710.workers
	var __ERRORS__ : Collection
	
	This:C1470.class:=$class
	This:C1470.timeout:=60
	This:C1470.errors:=[]
	This:C1470.owner:=""
	
Function start($port : Integer; $option : Object) : Boolean
	
	If (Not:C34(This:C1470._validate($port)))
		return False:C215
	End if 
	
	If ($option=Null:C1517) || (Value type:C1509($option)#Is object:K8:27)
		return This:C1470._fail(-7; "option is not an object")
	End if 
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	If (Current process name:C1392=$signal.description)
		//re-entrant call (consumer start() or a SystemWorker callback): run directly to avoid waiting on ourselves
		start(This:C1470.class; $port; $option; $signal)
	Else 
		CALL WORKER:C1389($signal.description; Formula:C1597(start); This:C1470.class; $port; $option; $signal)
		CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	End if 
	
	If (This:C1470._wait($signal))
		return Bool:C1537($signal.success)
	End if 
	
	return False:C215
	
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
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	If (Current process name:C1392=$signal.description)
		terminate(This:C1470.class; $port; $signal)
	Else 
		CALL WORKER:C1389($signal.description; Formula:C1597(terminate); This:C1470.class; $port; $signal)
		CALL WORKER:C1389($signal.description; Formula:C1597(_settle); $signal)
	End if 
	
	If (This:C1470._wait($signal))
		return Bool:C1537($signal.success)
	End if 
	
	return False:C215
	
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
	
	If (This:C1470._wait($signal))
		return Bool:C1537($signal.isRunning)
	End if 
	
	return False:C215
	
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
	
Function _wait($signal : 4D:C1709.Signal) : Boolean
	
	If ($signal.wait(This:C1470.timeout))
		If ($signal.errors#Null:C1517)
			This:C1470.errors:=$signal.errors.copy()
		End if 
		This:C1470.owner:=String:C10($signal.owner)
	Else 
		This:C1470._fail(-1; "timed out after "+String:C10(This:C1470.timeout)+"s waiting for the .workers worker")
	End if 
	
	return This:C1470.errors.length=0
