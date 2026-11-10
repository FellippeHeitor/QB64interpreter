'eval.bi - declarations for the expression evaluator (see eval.bm)
'Include after the varType* constants.

TYPE valType
    isText AS _BYTE
    t AS _BYTE 'numeric type, one of the varType* constants
    n AS _FLOAT
    s AS STRING
END TYPE

CONST tkEND = 0, tkNUM = 1, tkSTR = 2, tkIDENT = 3, tkOP = 4
CONST tkLPAREN = 5, tkRPAREN = 6, tkCOMMA = 7

REDIM SHARED tkKind(10) AS _BYTE, tkText(10) AS STRING
DIM SHARED tkCount AS LONG, tkPos AS LONG, evalErr AS INTEGER

'variable name hash: varHash(h) holds the newest var index with that hash,
'vars(i).nextHash chains to older ones
CONST varHashSize = 4095
DIM SHARED varHash(varHashSize) AS LONG
