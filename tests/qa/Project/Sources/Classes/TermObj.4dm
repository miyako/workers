//returns itself (no "worker" property) but can terminate its own process
property sw : 4D.SystemWorker
Class constructor
Function start($option : Object) : Object
	This.sw:=4D.SystemWorker.new("/bin/sleep "+String($option.secs))
	return This
Function terminate()
	This.sw.terminate()
