//%attributes = {"preemptive":"capable"}
#DECLARE($name : Text; $ok : Boolean; $detail : Text)
_log(($ok ? "PASS " : "FAIL ")+(Is compiled mode ? "[compiled] " : "")+$name+(($detail#"") ? (" | "+$detail) : ""))
