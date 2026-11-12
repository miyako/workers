Class constructor
Function start($option : Object) : Object
	return {worker: 4D.SystemWorker.new(_sleep($option.secs))}
