Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new("/bin/sleep "+String($option.secs+900))
