//%attributes = {"preemptive":"capable"}
#DECLARE($key : Text) : Variant
var $f : 4D.File
$f:=_dir().file("wt-kv-"+$key+".json")
If ($f.exists)
	return JSON Parse($f.getText()).v
End if 
