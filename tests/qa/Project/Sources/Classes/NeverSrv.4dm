//never becomes ready
Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new("/bin/sleep 45022")
Function isReady($port : Integer) : Boolean
	_put("neverPort"; $port)
	return False
