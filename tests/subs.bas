DECLARE SUB greet (n$)
DIM SHARED total
total = 0
greet "Ann"
CALL greet("Bob")
PRINT "total ="; total
PRINT "fact(10) ="; fact(10)
PRINT square#(1.5)
a = 5
addOne a
PRINT "a ="; a
addOne (a)
PRINT "a ="; a
b = 1
addOne b + 1
PRINT "b ="; b
DIM arr(3)
fill arr()
PRINT arr(0); arr(3)
PRINT "x before:"; x
setLocal
PRINT "x after:"; x
PRINT upper$("abc")
PRINT fib(15)
early 5
early 50

SUB greet (n$)
    PRINT "Hello, "; n$
    total = total + 1
END SUB

FUNCTION fact (n)
    IF n <= 1 THEN fact = 1 ELSE fact = n * fact(n - 1)
END FUNCTION

FUNCTION square# (v#)
    square# = v# * v#
END FUNCTION

SUB addOne (v)
    v = v + 1
END SUB

SUB fill (z())
    FOR i = LBOUND(z) TO UBOUND(z)
        z(i) = i + 100
    NEXT
END SUB

SUB setLocal
    x = 99
    PRINT "x inside:"; x
END SUB

FUNCTION upper$ (s$)
    upper$ = UCASE$(s$) + "!"
END FUNCTION

FUNCTION fib& (n)
    IF n < 2 THEN fib& = n: EXIT FUNCTION
    fib& = fib&(n - 1) + fib&(n - 2)
END FUNCTION

SUB early (n)
    IF n > 10 THEN PRINT "too big": EXIT SUB
    PRINT "ok"; n
END SUB
