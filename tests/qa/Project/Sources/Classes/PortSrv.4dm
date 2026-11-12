//really listens on $option.port (supplied by workers when the option has none); fails if the port is still bound
//(raw socket without SO_REUSEADDR/SO_REUSEPORT: IO::Socket::INET on macOS lets a second listener bind)
//Windows: an exclusive TcpListener in PowerShell (slower to start: see T13 in t_main)
Class constructor
Function start($option : Object) : 4D.SystemWorker
	var $worker : 4D.SystemWorker
	If (Is Windows)
		$worker:=4D.SystemWorker.new("powershell -NoProfile -NonInteractive -Command \"try { $l=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, "+String($option.port)+"); $l.ExclusiveAddressUse=$true; $l.Start() } catch { [Console]::Error.WriteLine('bind failed: '+$_.Exception.Message); exit 1 }; Start-Sleep 45\"")
	Else 
		$worker:=4D.SystemWorker.new("/usr/bin/perl -e \"use Socket; socket(S,PF_INET,SOCK_STREAM,0) or die; bind(S,sockaddr_in(shift,inet_aton(q(127.0.0.1)))) or die qq(bind failed: $!); listen(S,5) or die; sleep 45\" "+String($option.port))
	End if 
	If (Bool($option.race))
		_race($worker)
	End if 
	return $worker
