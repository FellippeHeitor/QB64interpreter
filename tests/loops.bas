FOR i = 1 TO 3: PRINT i;: NEXT: PRINT "done"
FOR i = 10 TO 1 STEP -3
    PRINT i;
NEXT i
PRINT
FOR i = 5 TO 1
    PRINT "never"
NEXT
PRINT "empty ok"
x = 0: DO: x = x + 1: LOOP UNTIL x = 4
PRINT "x ="; x
y = 0
DO WHILE y < 3
    y = y + 1
LOOP
PRINT "y ="; y
n = 0
FOR a = 1 TO 3
    FOR b = 1 TO 2
        n = n + 1
    NEXT
NEXT
PRINT "n ="; n
c = 0
DO
    c = c + 1
    IF c = 2 THEN GOTO skip
    PRINT "c ="; c
    skip:
LOOP UNTIL c >= 3
FOR k% = 1 TO 2.6
    PRINT k%;
NEXT
PRINT
z = 0
DO UNTIL z = 2
    z = z + 1
    FOR q = 1 TO 2
        IF q = 2 THEN EXIT FOR
    NEXT
LOOP
PRINT "z ="; z; "q ="; q
