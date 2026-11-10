i = 0
WHILE i < 3
    i = i + 1
    PRINT "i ="; i
WEND
FOR n = 0 TO 12 STEP 3
    SELECT CASE n
        CASE 0
            PRINT n; "zero"
        CASE 1, 2, 3
            PRINT n; "small"
        CASE 4 TO 7
            PRINT n; "medium"
        CASE IS > 10
            PRINT n; "big"
        CASE ELSE
            PRINT n; "other"
    END SELECT
NEXT
s$ = "kiwi"
SELECT CASE s$
    CASE "apple": PRINT "a"
    CASE "a" TO "m": PRINT s$; " is in a-m"
    CASE ELSE: PRINT "z"
END SELECT
SELECT CASE 5
    CASE 1
        PRINT "no"
END SELECT
PRINT "no match ok"
k = 0
WHILE 1
    k = k + 1
    IF k = 4 THEN EXIT WHILE
WEND
PRINT "k ="; k
