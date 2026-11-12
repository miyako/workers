//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($port : Integer; $token : Text; $signal : 4D:C1709.Signal)

//stop and unregister the server started with $token if its start failed (not ready, timed out)

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

var $entry : Object
$entry:=__WORKER__.entry($port)

If ($entry#Null:C1517) && (String:C10($entry.token)=$token)
	__WORKER__.retire($entry)
	__WORKER__.remove($port)
End if 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
