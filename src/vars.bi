'vars.bi - variables, arrays and call frames (see vars.bm)

TYPE vartype
    name AS STRING 'as typed by the user
    key AS STRING 'lookup key: [frame prefix] + lowercase name [+ "()" for arrays]
    type AS _BYTE
    protected AS _BYTE 'built-in function name
    isConst AS _BYTE
    isShared AS _BYTE 'DIM SHARED: visible inside SUBs and FUNCTIONs
    nextHash AS LONG
    refIdx AS LONG 'this name is an alias of another variable (BYREF params, SHARED)
    isArray AS _BYTE
    nDims AS INTEGER
    dimStart AS LONG 'first entry in dimLo()/dimHi()
    firstElem AS LONG 'first element in poolNum()/poolStr()
    size AS LONG
END TYPE

'an assignable place: a scalar variable, or one array element
TYPE lvType
    idx AS LONG 'variable
    elem AS LONG 'pool index of the array element, 0 for scalars
    t AS _BYTE
END TYPE

CONST varType_FLOAT = 0
CONST varTypeSTRING = 1
CONST varTypeINTEGER = 2
CONST varTypeSINGLE = 3
CONST varTypeDOUBLE = 4
CONST varType_UBYTE = 5
CONST varType_BYTE = 6
CONST varType_UINTEGER = 7
CONST varType_UINTEGER64 = 8
CONST varType_INTEGER64 = 9
CONST varType_ULONG = 10
CONST varTypeLONG = 11

REDIM SHARED vars(0) AS vartype
REDIM SHARED strings(0) AS STRING
REDIM SHARED nums(0) AS _FLOAT
DIM SHARED totalVars AS LONG, builtinCount AS LONG

CONST varHashSize = 4095
DIM SHARED varHash(varHashSize) AS LONG

'array storage
REDIM SHARED poolNum(1000) AS _FLOAT, poolStr(1000) AS STRING
REDIM SHARED dimLo(100) AS LONG, dimHi(100) AS LONG
DIM SHARED poolTop AS LONG, dimTop AS LONG
DIM SHARED poolGlobalHigh AS LONG, dimGlobalHigh AS LONG

'call frames: locals are stored under keys prefixed with "#<frame>:"
DIM SHARED frameId AS LONG, framePrefix$, frameSerial AS LONG
DIM SHARED curProc AS LONG, retVar AS LONG

'DEFINT/DEFSTR/...: default type by first letter
DIM SHARED defType(1 TO 26) AS _BYTE
