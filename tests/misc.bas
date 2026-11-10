REM comment: with colon
' another: comment
a = 5 ' trailing comment
PRINT a ' here too
LET b = a * 2
PRINT b
s$ = "a:b"
PRINT s$
PRINT "x"; "y"; 1; -2
IF a = 5 THEN PRINT "five" ELSE PRINT "not five"
IF a = 4 THEN PRINT "four" ELSE PRINT "not four"
IF a > 1 THEN
    PRINT "big"
ELSEIF a > 0 THEN
    PRINT "small"
ELSE
    PRINT "zero"
END IF
IF a > 10 THEN
    PRINT "huge"
ELSEIF a > 1 THEN
    PRINT "medium"
ELSE
    PRINT "small"
END IF
t$ = "abc"
IF t$ = "abc" THEN
    PRINT "string block if ok"
END IF
abcdefghijabcdefghijabcdefghijabcdefghi1 = 1
abcdefghijabcdefghijabcdefghijabcdefghi2 = 2
PRINT abcdefghijabcdefghijabcdefghijabcdefghi1
? "question mark print"
