Class constructor
Function start($option : Object) : 4D.SystemWorker
	_log("ReSrv nested isRunning...")
	_log("ReSrv nested isRunning="+String(cs.workers.worker.new(cs.Srv).isRunning(45099)))
	return 4D.SystemWorker.new(_sleep(45007))
