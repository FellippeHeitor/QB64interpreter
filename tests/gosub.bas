x = 1
GOSUB dbl
GOSUB dbl
PRINT "x ="; x
FOR i = 1 TO 3
    ON i GOSUB one, two, three
NEXT
ON 2 GOTO a1, a2
a1: PRINT "wrong"
a2: PRINT "jumped to a2"
GOTO done
dbl:
x = x * 2
RETURN
one: PRINT "one": RETURN
two: PRINT "two": RETURN
three: PRINT "three": RETURN
done:
PRINT "end"
