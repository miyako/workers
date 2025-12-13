//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($class : 4D:C1709.Class; $port : Integer; $option : Object; $signal : 4D:C1709.Signal)

If (Value type:C1509(__WORKER__)=Is object:K8:27) && (OB Instance of:C1731(__WORKER__; cs:C1710.workers))
Else 
	__WORKER__:=cs:C1710.workers.new()
End if 

var $worker : 4D:C1709.SystemWorker
$worker:=__WORKER__.find($port)

If (OB Instance of:C1731($worker; 4D:C1709.SystemWorker)) && (Not:C34($worker.terminated))
	//already started
Else 
	var $LlamaEdge : Object
	$LlamaEdge:=$class.new()
	$worker:=$LlamaEdge.start($option)
	__WORKER__.insert($port; $worker)
End if 

$signal.trigger()