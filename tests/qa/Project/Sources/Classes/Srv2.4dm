Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new(_sleep($option.secs+900))
