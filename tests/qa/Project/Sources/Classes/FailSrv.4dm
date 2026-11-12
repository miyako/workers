//exits right away with an error on stderr
Class constructor
Function start($option : Object) : 4D.SystemWorker
	return 4D.SystemWorker.new("/bin/sh -c \"echo boom >&2; exit 3\"")
