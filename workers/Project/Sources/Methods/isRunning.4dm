//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($class : 4D:C1709.Class; $port : Integer; $signal : 4D:C1709.Signal)

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

var $isRunning : Boolean
var $owner : Text
var $entry : Object
$entry:=__WORKER__.entry($port)

If (__WORKER__.isAlive($entry))
	If (__WORKER__.owns($entry; $class))
		$isRunning:=True:C214
	Else 
		$owner:=String:C10($entry.class.name)
	End if 
End if 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.isRunning:=$isRunning
	$signal.owner:=$owner
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
