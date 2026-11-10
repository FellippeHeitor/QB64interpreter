a = 1
IF a = 1 THEN FOR i = 1 TO 3: PRINT i;: NEXT: PRINT
IF a = 2 THEN PRINT "no" ELSE PRINT "else": PRINT "still else"
IF a = 1 THEN PRINT "yes": PRINT "both" ELSE PRINT "no"
IF a THEN IF a = 1 THEN PRINT "nested"
IF a = 1 GOTO skip
PRINT "not skipped"
skip:
IF a = 1 THEN 100
PRINT "not 100"
100 PRINT "line 100"
c = 0
DO: c = c + 1: IF c = 3 THEN EXIT DO
LOOP
PRINT "c ="; c
