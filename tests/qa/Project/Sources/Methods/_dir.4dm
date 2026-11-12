//%attributes = {"preemptive":"capable"}
#DECLARE() : 4D.Folder
//tests/qa/out: log and files shared with the consumer classes and run.sh (also from the compiled copy in tests/qa/Build/qa)
var $f : 4D.Folder
//platform path: in compiled mode the database folder is the "/PACKAGE/" filesystem, which has no parent
$f:=Folder(Folder(fk database folder).platformPath; fk platform path)
If (Not($f.file("run.sh").exists))
	$f:=$f.parent.parent
End if 
$f:=$f.folder("out")
If (Not($f.exists))
	$f.create()
End if 
return $f
