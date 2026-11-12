//%attributes = {"preemptive":"capable"}
#DECLARE($secs : Real) : Text
//command line of a process that runs for about $secs seconds; _count("sleep "+String($secs)) finds it
//Windows: ping waits 1s between echo requests (n requests: n-1 seconds); long-lived servers use n=$secs as a unique marker
If (Is Windows)
	Case of 
		: ($secs>=1000)
			return "ping -n "+String($secs)+" 127.0.0.1"
		: ($secs<1)
			return "ping -n 1 127.0.0.1"
		Else 
			return "ping -n "+String(Int($secs)+1)+" 127.0.0.1"
	End case 
End if 
return "/bin/sleep "+Replace string(String($secs); ","; ".")
