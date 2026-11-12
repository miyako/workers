//%attributes = {"preemptive":"capable"}
#DECLARE($name : Text; $ok : Boolean; $detail : Text)
_log(($ok ? "PASS " : "FAIL ")+$name+(($detail#"") ? (" | "+$detail) : ""))
