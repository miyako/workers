#DECLARE($name : Text; $project : 4D.File; $components : Collection)
var $res; $e : Object
var $bad : Integer
var $msgs : Text
If ($project.exists)
	If ($components=Null)
		$res:=Compile project($project)
	Else 
		//recent versions do not resolve the classes of the host's Components folder unless they are listed
		$res:=Compile project($project; {components: $components})
	End if 
	If ($res.errors#Null)
		For each ($e; $res.errors)
			If (Bool($e.isError))
				$bad:=$bad+1
				$msgs:=$msgs+" "+String($e.message)+(($e.code#Null) ? (" @"+String($e.code.path)+":"+String($e.lineInFile)) : "")+";"
			End if 
		End for each 
	End if 
	_check($name; Bool($res.success) & ($bad=0); "errors="+String($bad)+$msgs)
Else 
	_check($name; False; "missing "+$project.platformPath)
End if 
