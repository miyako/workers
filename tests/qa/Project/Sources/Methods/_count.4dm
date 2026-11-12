#DECLARE($pat : Text) : Integer
//counts running processes started with _sleep() ($pat="sleep <secs>") or by PortSrv ($pat="listener")
var $stdin; $stdout; $stderr; $filter : Text
If (Is Windows)
	If ($pat="listener")
		$filter:="$_.Name -eq 'powershell.exe' -and $_.CommandLine -like '*TcpListener*'"
	Else 
		$filter:="$_.Name -eq 'PING.EXE' -and $_.CommandLine -like '* -n "+Substring($pat; 7)+" 127.0.0.1*'"
	End if 
	SET ENVIRONMENT VARIABLE("_4D_OPTION_HIDE_CONSOLE"; "true")
	LAUNCH EXTERNAL PROCESS("powershell -NoProfile -NonInteractive -Command \"@(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $PID -and "+$filter+" }).Count\""; $stdin; $stdout; $stderr)
	return Num($stdout)
End if 
If ($pat="listener")
	$pat:="/usr/bin/perl -e use Socket"
End if 
LAUNCH EXTERNAL PROCESS("/bin/ps -axww -o command="; $stdin; $stdout; $stderr)
return Split string($stdout; "\n"; sk ignore empty strings+sk trim spaces).filter(Formula(Position($2; $1.value)=1); (Position("/"; $pat)=1) ? $pat : ("/bin/"+$pat)).length
