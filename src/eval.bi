'eval.bi - declarations for the expression evaluator (see eval.bm)

TYPE valType
    isText AS _BYTE
    t AS _BYTE 'numeric type, one of the varType* constants
    n AS _FLOAT
    s AS STRING
END TYPE

CONST tkEND = 0, tkNUM = 1, tkSTR = 2, tkIDENT = 3, tkOP = 4
CONST tkLPAREN = 5, tkRPAREN = 6, tkCOMMA = 7

REDIM SHARED tkKind(10) AS _BYTE, tkText(10) AS STRING, tkStart(10) AS LONG
DIM SHARED tkCount AS LONG, tkPos AS LONG, evalErr AS INTEGER
DIM SHARED tkSrc$, tkCurStart AS LONG
