//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($port : Integer; $signal : 4D:C1709.Signal)

If (Value type:C1509(__WORKER__)=Is object:K8:27) && (OB Instance of:C1731(__WORKER__; cs:C1710.workers))
Else 
	__WORKER__:=cs:C1710.workers.new()
End if 

var $worker : 4D:C1709.SystemWorker
$worker:=__WORKER__.find($port)

var $isRunning : Boolean

If (OB Instance of:C1731($worker; 4D:C1709.SystemWorker)) && (Not:C34($worker.terminated))
	$isRunning:=True:C214
End if 

Use ($signal)
	$signal.isRunning:=$isRunning
End use 

$signal.trigger()
