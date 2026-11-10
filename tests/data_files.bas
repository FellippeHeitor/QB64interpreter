DIM nm$(3), age(3)
FOR i = 1 TO 3
    READ nm$(i), age(i)
NEXT
PRINT nm$(2); age(2)
RESTORE second
READ w$
PRINT w$
f$ = "_bcl_test.txt"
OPEN f$ FOR OUTPUT AS #1
PRINT #1, "line one"
PRINT #1, 42; "x"
WRITE #1, "quoted", 7
CLOSE #1
OPEN f$ FOR APPEND AS #1
PRINT #1, "appended"
CLOSE #1
OPEN f$ FOR INPUT AS #2
DO WHILE NOT EOF(2)
    LINE INPUT #2, l$
    PRINT "["; l$; "]"
LOOP
CLOSE #2
OPEN f$ FOR INPUT AS #1
LINE INPUT #1, l$
LINE INPUT #1, l$
INPUT #1, q$, n
PRINT q$; n
CLOSE
KILL f$
PRINT _FILEEXISTS(f$)
DATA "Ann", 31, Bob, 42
second:
DATA "Cy", 7
