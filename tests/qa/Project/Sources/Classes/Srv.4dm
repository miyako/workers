Class constructor
Function start($option : Object) : 4D.SystemWorker
	_log("Srv.start secs="+String($option.secs))
	return 4D.SystemWorker.new(_sleep($option.secs))
