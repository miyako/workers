//really listens on $option.port (supplied by workers when the option has none); fails if the port is still bound
//(raw socket without SO_REUSEADDR/SO_REUSEPORT: IO::Socket::INET on macOS lets a second listener bind)
Class constructor
Function start($option : Object) : 4D.SystemWorker
	var $worker : 4D.SystemWorker
	$worker:=4D.SystemWorker.new("/usr/bin/perl -e \"use Socket; socket(S,PF_INET,SOCK_STREAM,0) or die; bind(S,sockaddr_in(shift,inet_aton(q(127.0.0.1)))) or die qq(bind failed: $!); listen(S,5) or die; sleep 45\" "+String($option.port))
	If (Bool($option.race))
		_race($worker)
	End if 
	return $worker
