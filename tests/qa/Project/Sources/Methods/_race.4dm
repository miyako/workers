//%attributes = {"preemptive":"capable"}
#DECLARE($worker : 4D.SystemWorker)
//runs in .workers: counts starts that happen while the previous server's process has not exited yet
var x_prev : 4D.SystemWorker
If (x_prev#Null) && (Not(x_prev.terminated))
	_put("race"; Num(_get("race"))+1)
End if 
x_prev:=$worker
