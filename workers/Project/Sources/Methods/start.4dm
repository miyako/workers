//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($class : 4D:C1709.Class; $port : Integer; $option : Object; $signal : 4D:C1709.Signal)

var $handler : Text
$handler:=Method called on error:C704
var $outer : Collection
$outer:=__ERRORS__
__ERRORS__:=[]
ON ERR CALL:C155("_onError")

If (Value type:C1509(__WORKER__)=Is object:K8:27) && (OB Instance of:C1731(__WORKER__; cs:C1710.workers))
Else 
	__WORKER__:=cs:C1710.workers.new()
End if 

var $success : Boolean
var $owner : Text
var $entry : Object
$entry:=__WORKER__.entry($port)

If (__WORKER__.isAlive($entry))
	If (__WORKER__.owns($entry; $class))
		//already started by this class
		$success:=True:C214
	Else 
		$owner:=String:C10($entry.class.name)
		__ERRORS__.push({errCode: -5; message: "port "+String:C10($port)+" is used by "+$owner; componentSignature: "wrks"})
	End if 
Else 
	var $instance : Object
	var $result : Variant
	var $worker : 4D:C1709.SystemWorker
	$instance:=$class.new()
	$result:=$instance.start($option)
	$worker:=__WORKER__.unwrap($result)
	__WORKER__.remove($port)
	If ($worker=Null:C1517)
		//not manageable: do not register, release it if possible
		__WORKER__.dispose($result)
		If (__ERRORS__.length=0)
			__ERRORS__.push({errCode: -3; message: "start() did not return a 4D.SystemWorker"; componentSignature: "wrks"})
		End if 
	Else 
		//register even if an error was reported, so that terminate() can still reach it
		__WORKER__.insert($port; $worker; $class; $instance)
		$success:=(__ERRORS__.length=0)
	End if 
End if 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.success:=$success
	$signal.owner:=$owner
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
