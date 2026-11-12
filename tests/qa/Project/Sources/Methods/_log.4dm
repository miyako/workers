//%attributes = {"preemptive":"capable"}
#DECLARE($t : Text)
var $f : 4D.File
$f:=File("/tmp/wt2.log")
$f.setText(($f.exists ? $f.getText() : "")+String(Milliseconds)+" "+Current process name+": "+$t+"\n")
