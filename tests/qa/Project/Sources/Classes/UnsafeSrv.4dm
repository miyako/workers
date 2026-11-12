//start() calls a method that is not thread-safe: fails when .workers runs preemptively (compiled), works interpreted
Class constructor
Function start($option : Object) : 4D.SystemWorker
	_log("UnsafeSrv "+_unsafe())
	return 4D.SystemWorker.new(_sleep(45091))
