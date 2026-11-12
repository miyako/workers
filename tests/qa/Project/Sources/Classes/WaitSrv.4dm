//start() and isReady() wait on another SystemWorker: wait() runs the .workers queue re-entrantly
Class constructor
Function start($option : Object) : 4D.SystemWorker
	4D.SystemWorker.new(_sleep(0.2)).wait(5)
	return 4D.SystemWorker.new(_sleep(45025))
Function isReady($port : Integer) : Boolean
	4D.SystemWorker.new(_sleep(0.2)).wait(5)
	return True
