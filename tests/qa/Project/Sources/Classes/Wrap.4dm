Class constructor
Function start($option : Object) : Object
	return {worker: 4D.SystemWorker.new("/bin/sleep "+String($option.secs))}
