//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($class : 4D:C1709.Class; $port : Integer; $token : Text; $signal : 4D:C1709.Signal)

//startup check of the server registered by start() with $token: has it exited? is it ready (optional isReady($port) of the consumer class)?

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

var $ready : Boolean
var $entry : Object
$entry:=__WORKER__.entry($port)

Case of 
	: ($entry=Null:C1517) || (String:C10($entry.token)#$token)
		__ERRORS__.push({errCode: -8; message: "the server on port "+String:C10($port)+" was stopped during startup"; componentSignature: "wrks"})
	: (Not:C34(__WORKER__.isAlive($entry)))
		var $worker : 4D:C1709.SystemWorker
		var $stderr : Text
		var $exitCode : Variant
		$worker:=$entry.worker
		__WORKER__.remove($port)
		$exitCode:=$worker.exitCode
		If (Value type:C1509($worker.responseError)=Is text:K8:3)
			$stderr:=$worker.responseError
		End if 
		If ($stderr="") && (Value type:C1509($worker.response)=Is text:K8:3)
			$stderr:=$worker.response
		End if 
		If (Length:C16($stderr)>1000)
			$stderr:=Substring:C12($stderr; 1; 1000)+"…"
		End if 
		While (Length:C16($stderr)>0) && (Position:C15($stderr[[Length:C16($stderr)]]; "\r\n\t ")>0)
			$stderr:=Substring:C12($stderr; 1; Length:C16($stderr)-1)
		End while 
		__ERRORS__.push({errCode: -8; message: "the server on port "+String:C10($port)+" exited during startup (exit code "+String:C10($exitCode)+")"+(($stderr="") ? "" : (": "+$stderr)); componentSignature: "wrks"; exitCode: $exitCode; stderr: $stderr})
	: (Value type:C1509($entry.instance)=Is object:K8:27) && (OB Instance of:C1731($entry.instance.isReady; 4D:C1709.Function))
		$ready:=Bool:C1537($entry.instance.isReady($port))
	Else 
		$ready:=True:C214
End case 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.ready:=$ready
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
