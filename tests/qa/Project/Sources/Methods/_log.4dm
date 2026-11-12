//%attributes = {"preemptive":"capable"}
#DECLARE($t : Text)
var $f : 4D.File
$f:=_dir().file("wt2.log")
$f.setText(($f.exists ? $f.getText("UTF-8"; Document unchanged) : "")+String(Milliseconds)+" "+Current process name+": "+$t+"\n"; "UTF-8-no-bom"; Document unchanged)
