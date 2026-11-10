i = 0
DO
    i = i + 1
    j = 0
    DO
        j = j + 1
    LOOP UNTIL j = 2
    IF i = 3 THEN EXIT DO
LOOP
PRINT "i ="; i
FOR x = 1 TO 3
    FOR y = 1 TO 3
    NEXT
    IF x = 2 THEN EXIT FOR
NEXT
PRINT "x ="; x
