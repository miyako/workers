//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($class : 4D:C1709.Class; $port : Integer; $signal : 4D:C1709.Signal)

//$port=0: every server registered by $class; otherwise only $port, if registered by $class

var $handler : Text
$handler:=Method called on error:C704
var $outer : Collection
$outer:=__ERRORS__
__ERRORS__:=[]
ON ERR CALL:C155("_onError")

var $owner : Text

If (Value type:C1509(__WORKER__)=Is object:K8:27) && (OB Instance of:C1731(__WORKER__; cs:C1710.workers))
	
	var $entries : Collection
	$entries:=[]
	var $entry : Object
	If ($port=0)
		For each ($entry; __WORKER__.workers)
			If (__WORKER__.owns($entry; $class))
				$entries.push($entry)
			End if 
		End for each 
	Else 
		$entry:=__WORKER__.entry($port)
		If ($entry#Null:C1517)
			If (__WORKER__.owns($entry; $class))
				$entries.push($entry)
			Else 
				If (__WORKER__.isAlive($entry))
					$owner:=String:C10($entry.class.name)
					__ERRORS__.push({errCode: -5; message: "port "+String:C10($port)+" is used by "+$owner; componentSignature: "wrks"})
				End if 
			End if 
		End if 
	End if 
	
	//terminate() is asynchronous: the caller then waits for the processes to exit (see _reap)
	For each ($entry; $entries)
		__WORKER__.retire($entry)
		__WORKER__.remove($entry.port)
	End for each 
	
End if 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.success:=(__ERRORS__.length=0)
	$signal.owner:=$owner
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
