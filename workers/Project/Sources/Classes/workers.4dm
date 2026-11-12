property workers : Collection

//registry of running servers: one entry per port, {port; worker; class; instance}
//note: do not call This.<function>() inside this class (rejected by 4D 21 R5 because the class name matches the component namespace)

Class constructor
	
	This:C1470.workers:=[]
	
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
	
Function insert($port : Integer; $worker : 4D:C1709.SystemWorker; $class : 4D:C1709.Class; $instance : Object)
	
	If ($port<1) || ($port>65535) || (Not:C34(OB Instance of:C1731($worker; 4D:C1709.SystemWorker)))
		return 
	End if 
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx=-1)
		This:C1470.workers.push({port: $port; worker: $worker; class: $class; instance: $instance})
	End if 
	
Function remove($port : Integer)
	
	var $idx : Integer
	$idx:=This:C1470.workers.findIndex(Formula:C1597($1.value.port=$2); $port)
	If ($idx#-1)
		This:C1470.workers.remove($idx)
	End if 
