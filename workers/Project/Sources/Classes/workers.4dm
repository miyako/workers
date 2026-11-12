property workers : Collection
property stopping : Collection

//registry of running servers: one entry per port, {port; worker; class; instance; token}
//stopping: entries whose process was asked to terminate but had not exited yet
//note: do not call This.<function>() inside this class (rejected by 4D 21 R5 because the class name matches the component namespace)

Class constructor
	
	This:C1470.workers:=[]
	This:C1470.stopping:=[]
	
Function find($port : Integer) : 4D:C1709.SystemWorker
	
	If ($port<1) || ($port>65535)
		return 
	End if 
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx#-1)
		return This:C1470.workers[$idx].worker
	End if 
	
Function entry($port : Integer) : Object
	
	If ($port<1) || ($port>65535)
		return 
	End if 
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx#-1)
		return This:C1470.workers[$idx]
	End if 
	
Function isAlive($entry : Object) : Boolean
	
	If ($entry=Null:C1517)
		return False:C215
	End if 
	
	If (Value type:C1509($entry.worker)#Is object:K8:27)
		return False:C215
	End if 
	
	return (OB Instance of:C1731($entry.worker; 4D:C1709.SystemWorker)) && (Not:C34($entry.worker.terminated))
	
Function owns($entry : Object; $class : 4D:C1709.Class) : Boolean
	
	//4D 20.x cannot compare class references with =; compare by name and check the instance
	If ($entry=Null:C1517) || ($class=Null:C1517)
		return False:C215
	End if 
	
	If (Value type:C1509($entry.class)#Is object:K8:27)
		return False:C215
	End if 
	
	If (String:C10($entry.class.name)#String:C10($class.name))
		return False:C215
	End if 
	
	If (Value type:C1509($entry.instance)=Is object:K8:27)
		return OB Instance of:C1731($entry.instance; $class)
	End if 
	
	return True:C214
	
Function unwrap($result : Variant) : 4D:C1709.SystemWorker
	
	//accept a 4D.SystemWorker, or an object that exposes one in its "worker" property
	If (Value type:C1509($result)#Is object:K8:27)
		return 
	End if 
	
	If (OB Instance of:C1731($result; 4D:C1709.SystemWorker))
		return $result
	End if 
	
	If (Value type:C1509($result.worker)=Is object:K8:27) && (OB Instance of:C1731($result.worker; 4D:C1709.SystemWorker))
		return $result.worker
	End if 
	
Function dispose($result : Variant)
	
	//release a result that could not be registered so that it does not leak
	If (Value type:C1509($result)=Is object:K8:27)
		If (Value type:C1509($result.terminate)=Is object:K8:27) && (OB Instance of:C1731($result.terminate; 4D:C1709.Function))
			$result.terminate()
		End if 
	End if 
	
Function insert($port : Integer; $worker : 4D:C1709.SystemWorker; $class : 4D:C1709.Class; $instance : Object; $token : Text)
	
	If ($port<1) || ($port>65535) || (Not:C34(OB Instance of:C1731($worker; 4D:C1709.SystemWorker)))
		return 
	End if 
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx=-1)
		This:C1470.workers.push({port: $port; worker: $worker; class: $class; instance: $instance; token: $token})
	End if 
	
Function retire($entry : Object)
	
	//ask the process to terminate (asynchronous) and keep track of it until it has exited
	If ($entry=Null:C1517)
		return 
	End if 
	
	If (Value type:C1509($entry.worker)=Is object:K8:27) && (OB Instance of:C1731($entry.worker; 4D:C1709.SystemWorker))
		If (Not:C34($entry.worker.terminated))
			$entry.worker.terminate()
			This:C1470.stopping.push($entry)
		End if 
	End if 
	
Function stalled($port : Integer) : Boolean
	
	//true if a process that used $port was asked to terminate but has not exited yet
	This:C1470.stopping:=This:C1470.stopping.filter(Formula:C1597(Not:C34($1.value.worker.terminated)))
	
	return This:C1470.stopping.findIndex(Formula:C1597($1.value.port=$2); $port)#-1
	
Function reap($class : 4D:C1709.Class; $port : Integer) : Integer
	
	//forget the processes that have exited; count those of $class ($port=0: any port) that are still running
	This:C1470.stopping:=This:C1470.stopping.filter(Formula:C1597(Not:C34($1.value.worker.terminated)))
	
	If ($class=Null:C1517)
		return 0
	End if 
	
	return This:C1470.stopping.filter(Formula:C1597((String:C10($1.value.class.name)=$2) && (($3=0) || ($1.value.port=$3))); String:C10($class.name); $port).length
	
Function remove($port : Integer)
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx#-1)
		This:C1470.workers.remove($idx)
	End if 
