//%attributes = {"invisible":true,"preemptive":"capable"}
var __ERRORS__ : Collection

If (__ERRORS__=Null:C1517)
	__ERRORS__:=[]
End if 

var $errors : Collection
$errors:=Last errors:C1799

If ($errors#Null:C1517)
	__ERRORS__.combine($errors)
End if 