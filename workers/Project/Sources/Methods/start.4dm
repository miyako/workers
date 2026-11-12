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
var $token : Text
var $entry : Object
$entry:=__WORKER__.entry($port)

Case of 
	: (Bool:C1537($signal.cancelled))
		//the caller gave up before this request ran: do not start anything
	: (__WORKER__.isAlive($entry))
		If (__WORKER__.owns($entry; $class))
			//already started by this class
			$success:=True:C214
		Else 
			$owner:=String:C10($entry.class.name)
			__ERRORS__.push({errCode: -5; message: "port "+String:C10($port)+" is used by "+$owner; componentSignature: "wrks"})
		End if 
	: (__WORKER__.stalled($port))
		__ERRORS__.push({errCode: -9; message: "the previous server on port "+String:C10($port)+" has not exited yet"; componentSignature: "wrks"})
	Else 
		//pass the port to the consumer in a copy of the option, unless the option already has one
		var $params : Object
		var $key : Text
		$params:={}
		For each ($key; $option)
			$params[$key]:=$option[$key]
		End for each 
		If (Not:C34(OB Is defined:C1231($params; "port")))
			$params.port:=$port
		End if 
		var $instance : Object
		var $result : Variant
		var $worker : 4D:C1709.SystemWorker
		var $cancelled : Boolean
		$instance:=$class.new()
		$result:=$instance.start($params)
		$worker:=__WORKER__.unwrap($result)
		__WORKER__.remove($port)
		Use ($signal)
			//the caller may have timed out while start() was running; otherwise it now waits for this result
			$cancelled:=Bool:C1537($signal.cancelled)
			If (Not:C34($cancelled))
				$signal.committed:=True:C214
			End if 
		End use 
		Case of 
			: ($worker=Null:C1517)
				//not manageable: do not register, release it if possible
				__WORKER__.dispose($result)
				If (__ERRORS__.length=0)
					__ERRORS__.push({errCode: -3; message: "start() did not return a 4D.SystemWorker"; componentSignature: "wrks"})
				End if 
			: ($cancelled)
				//nobody will use this server: stop it instead of registering it
				If (Not:C34(OB Instance of:C1731($result; 4D:C1709.SystemWorker)))
					__WORKER__.dispose($result)
				End if 
				__WORKER__.retire({port: $port; worker: $worker; class: $class; instance: $instance})
			Else 
				//register even if an error was reported, so that terminate() can still reach it
				$token:=Generate UUID:C1066
				__WORKER__.insert($port; $worker; $class; $instance; $token)
				$success:=(__ERRORS__.length=0)
				If (Not:C34($success))
					$token:=""
				End if 
		End case 
End case 

ON ERR CALL:C155($handler)

Use ($signal)
	$signal.success:=$success
	$signal.owner:=$owner
	$signal.token:=$token
	$signal.errors:=__ERRORS__.copy(ck shared:K85:29; $signal)
End use 

__ERRORS__:=$outer

$signal.trigger()
