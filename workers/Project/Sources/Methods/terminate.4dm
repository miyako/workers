//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($signal : 4D:C1709.Signal)

If (Value type:C1509(__WORKER__)=Is object:K8:27) && (OB Instance of:C1731(__WORKER__; cs:C1710.workers))
	
	var $worker : 4D:C1709.SystemWorker
	For each ($worker; __WORKER__.workers.extract("worker"))
		If (OB Instance of:C1731($worker; 4D:C1709.SystemWorker)) && (Not:C34($worker.terminated))
			$worker.terminate()
		End if 
	End for each 
End if 

__WORKER__.workers:=[]

$signal.trigger()