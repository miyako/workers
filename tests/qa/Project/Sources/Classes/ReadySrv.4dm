//becomes ready after 1s (creates a marker file); isReady() polls for it
Class constructor
Function start($option : Object) : 4D.SystemWorker
	var $marker : 4D.File
	$marker:=_dir().file("wt-ready-"+String($option.port))
	If (Is Windows)
		//a separate helper creates the marker: terminating "cmd /c" would not stop its children
		4D.SystemWorker.new("cmd /c \"ping -n 2 127.0.0.1 >nul & type nul > \""+$marker.platformPath+"\"\"")
		return 4D.SystemWorker.new(_sleep(45021))
	End if 
	return 4D.SystemWorker.new("/bin/sh -c \"/bin/sleep 1; touch '"+$marker.path+"'; exec /bin/sleep 45021\"")
Function isReady($port : Integer) : Boolean
	return _dir().file("wt-ready-"+String($port)).exists
