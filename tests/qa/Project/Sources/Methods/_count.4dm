#DECLARE($pat : Text) : Integer
var $stdin; $stdout; $stderr : Text
LAUNCH EXTERNAL PROCESS("/bin/ps -axww -o command="; $stdin; $stdout; $stderr)
return Split string($stdout; "\n"; sk ignore empty strings+sk trim spaces).filter(Formula(Position($2; $1.value)=1); "/bin/"+$pat).length
