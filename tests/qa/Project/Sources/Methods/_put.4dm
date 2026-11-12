//%attributes = {"preemptive":"capable"}
#DECLARE($key : Text; $value : Variant)
//lets consumer classes (run in the component's .workers process) report values to the test
File("/tmp/wt-kv-"+$key+".json").setText(JSON Stringify({v: $value}))
