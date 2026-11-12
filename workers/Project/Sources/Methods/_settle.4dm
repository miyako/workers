//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($signal : 4D:C1709.Signal)

//runs right after a request in the same worker queue: if the request was aborted by an error that no handler caught, the signal was never triggered

Case of 
	: ($signal.signaled)
		
	: (Call chain:C1662.length>1)
		//dispatched while the request is still running (consumer code called SystemWorker.wait(), which runs this queue)
		//do nothing: the caller posts _settle again while it waits
		
	Else 
		
		var $errors : Collection
		$errors:=Last errors:C1799
		If ($errors=Null:C1517)
			$errors:=[]
		Else 
			$errors:=$errors.copy()
		End if 
		$errors.push({errCode: -2; message: "the request was aborted by an unhandled error"; componentSignature: "wrks"})
		
		Use ($signal)
			$signal.errors:=$errors.copy(ck shared:K85:29; $signal)
		End use 
		
		$signal.trigger()
		
End case 
