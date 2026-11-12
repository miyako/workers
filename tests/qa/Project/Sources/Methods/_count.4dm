#DECLARE($pat : Text) : Integer
//counts running processes whose command line starts with $pat ("/bin/"+$pat unless $pat is an absolute path)
var $stdin; $stdout; $stderr : Text
LAUNCH EXTERNAL PROCESS("/bin/ps -axww -o command="; $stdin; $stdout; $stderr)
return Split string($stdout; "\n"; sk ignore empty strings+sk trim spaces).filter(Formula(Position($2; $1.value)=1); (Position("/"; $pat)=1) ? $pat : ("/bin/"+$pat)).length
