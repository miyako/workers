#DECLARE($w : Object; $code : Integer) : Boolean
return $w.errors.query("errCode = :1"; $code).length>0
