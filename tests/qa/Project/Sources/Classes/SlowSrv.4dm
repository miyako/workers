Class constructor
Function start($option : Object) : 4D.SystemWorker
	DELAY PROCESS(Current process; 300)
	return 4D.SystemWorker.new("/bin/sleep "+String($option.secs))
