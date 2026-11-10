PRINT LEN("abc"); ASC("A"); CHR$(66)
PRINT LEFT$("hello", 2); RIGHT$("hello", 3); MID$("hello", 2, 2); MID$("hello", 3)
PRINT INSTR("hello", "l"); INSTR(4, "hello", "l")
PRINT UCASE$("abc"); LCASE$("ABC"); "["; LTRIM$("  x "); "]"; "["; _TRIM$("  y  "); "]"
PRINT STRING$(3, "*"); STRING$(2, 65); SPACE$(2); "|"
PRINT STR$(3.5); VAL("12.5") + 1
PRINT HEX$(255); OCT$(8)
PRINT ABS(-3); SGN(-2); INT(-2.5); FIX(-2.5); CINT(2.5); CINT(3.5)
PRINT SQR(16); _ROUND(2.5)
PRINT _RGB32(255, 0, 0)
PRINT UCASE$(LCASE$("A B"))
PRINT LEN(STR$(12345))
PRINT _ATAN2(1, 1) * 4
