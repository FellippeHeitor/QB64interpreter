x = 1
FOR i = 1 TO 2
    twice x
    PRINT i; x
NEXT
PRINT "end"; x
SUB twice (v)
    v = v * 2
END SUB
