a$ = "a" + "b" + "c"
PRINT a$
PRINT "hi (there)"
PRINT UCASE$(LCASE$("A B"))
b$ = "x-y"
PRINT b$
PRINT LEN("hello world")
IF a$ = "abc" THEN PRINT "eq ok"
IF a$ <> "abd" THEN PRINT "ne ok"
PRINT LEFT$("hello", 2)
PRINT MID$("hello", 2, 3)
PRINT STR$(42) + "!"
