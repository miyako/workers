Class constructor
Function start($option : Object) : 4D.SystemWorker
	If (Bool($option.wait))
		//wait() runs the .workers queue, including the caller's _settle, before the error below aborts the request
		4D.SystemWorker.new("/bin/sleep 0.2").wait(5)
	End if 
	var $o : Object
	$o.a.b:=1
	return 4D.SystemWorker.new("/bin/sleep 45006")
