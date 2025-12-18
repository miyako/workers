property class : 4D:C1709.Class

Class constructor($class : 4D:C1709.Class)
	
	var __WORKER__ : cs:C1710.workers
	
	This:C1470.class:=$class
	
Function start($port : Integer; $option : Object)
	
	If ($option=Null:C1517) || (Value type:C1509($option)#Is object:K8:27)
		return 
	End if 
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	CALL WORKER:C1389($signal.description; Formula:C1597(start); This:C1470.class; $port; $option; $signal)
	
	$signal.wait()
	
Function _start($class : 4D:C1709.Class; $port : Integer; $option : Object; $signal : 4D:C1709.Signal)
	
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
	
Function terminate()
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	CALL WORKER:C1389($signal.description; Formula:C1597(terminate); $signal)
	
	$signal.wait()
	
Function isRunning($port : Integer) : Boolean
	
	var $signal : 4D:C1709.Signal
	$signal:=New signal:C1641(".workers")
	
	CALL WORKER:C1389($signal.description; Formula:C1597(isRunning); $port; $signal)
	
	$signal.wait()
	
	return $signal.isRunning