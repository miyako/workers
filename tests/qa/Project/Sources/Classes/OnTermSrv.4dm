Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new(_sleep(1); {onTerminate: Formula(_onterm($1; $2))})
