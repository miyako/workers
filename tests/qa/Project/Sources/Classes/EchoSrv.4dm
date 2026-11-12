//records the option it receives
Class constructor
Function start($option : Object) : 4D.SystemWorker
	_put("echo"; $option)
	return 4D.SystemWorker.new(_sleep(45023))
