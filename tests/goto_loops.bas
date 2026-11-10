' GOTO out of loops must not leave them half-open
n = 0
again:
n = n + 1
FOR i = 1 TO 10
    DO
        GOTO outside
    LOOP
NEXT
outside:
IF n < 50 THEN GOTO again
PRINT "n ="; n; "i ="; i
top: PRINT "label with statement"
c = 0
FOR i = 1 TO 5
    IF i MOD 2 = 0 THEN _CONTINUE
    c = c + i
NEXT
PRINT "odd sum ="; c
d = 0
DO
    d = d + 1
    IF d < 3 THEN _CONTINUE
    PRINT "d ="; d
LOOP UNTIL d >= 4
t = 0
FOR a = 1 TO 3: FOR b = 1 TO 2
    t = t + 1
NEXT b, a
PRINT "t ="; t
x = 0: DO WHILE x < 3: x = x + 1: LOOP: PRINT "x ="; x
FOR i = 1 TO 2: PRINT i;: NEXT i: PRINT "after next"
v = 2
IF v = 1 THEN
    PRINT "one"
ELSEIF v = 2 THEN
    PRINT "two"
    IF v > 0 THEN
        PRINT "nested"
    ELSE
        PRINT "wrong"
    END IF
ELSE
    PRINT "other"
END IF
PRINT "a: b" ' comment: with colon
