//records whether .workers runs preemptively (PROCESS PROPERTIES mode bit 1)
Class constructor
Function start($option : Object) : 4D.SystemWorker
	var $name : Text
	var $state; $time; $mode : Integer
	PROCESS PROPERTIES:C336(Current process; $name; $state; $time; $mode)
	_put("preemptive"; ($mode ?? 1))
	return 4D.SystemWorker.new("/bin/sleep 45090")
