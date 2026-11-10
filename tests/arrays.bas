DIM a(5)
FOR i = 0 TO 5: a(i) = i * i: NEXT
PRINT a(3); a(5)
DIM b(1 TO 3, 1 TO 2) AS INTEGER
FOR i = 1 TO 3: FOR j = 1 TO 2: b(i, j) = i * 10 + j: NEXT j, i
PRINT b(2, 1); b(3, 2)
PRINT LBOUND(b, 1); UBOUND(b, 1); LBOUND(b, 2); UBOUND(b, 2)
DIM n$(2)
n$(0) = "zero": n$(1) = "one": n$(2) = "two"
PRINT n$(1) + "/" + n$(2)
c(3) = 7
PRINT c(3); UBOUND(c)
REDIM d(2) AS LONG
d(2) = 9
REDIM _PRESERVE d(4) AS LONG
PRINT d(2); UBOUND(d)
DIM AS INTEGER p, q
p = 2.6: q = 7
PRINT p; q
CONST PI2 = 6.28, HELLO$ = "hi"
PRINT PI2; HELLO$
x = 1: y = 2
SWAP x, y
PRINT x; y
SWAP a(1), a(2)
PRINT a(1); a(2)
ERASE a
PRINT a(3)
DIM t AS STRING
t = "typed"
PRINT t
s$ = "hello"
MID$(s$, 2, 3) = "EYY"
PRINT s$
