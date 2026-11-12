//becomes ready after 1s (creates a marker file); isReady() polls for it
Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new("/bin/sh -c \"/bin/sleep 1; touch /tmp/wt-ready-"+String($option.port)+"; exec /bin/sleep 45021\"")
Function isReady($port : Integer) : Boolean
	return File("/tmp/wt-ready-"+String($port)).exists
