//exits right away with an error on stderr
Class constructor
Function start($option : Object) : 4D.SystemWorker
	If (Is Windows)
		return 4D.SystemWorker.new("cmd /c \"echo boom>&2& exit 3\"")
	End if 
	return 4D.SystemWorker.new("/bin/sh -c \"echo boom >&2; exit 3\"")
