'blocks.bi - the compiled program (see blocks.bm)

CONST stOTHER = 0, stDO = 1, stLOOP = 2, stFOR = 3, stNEXT = 4
CONST stIF = 5, stELSEIF = 6, stELSE = 7, stENDIF = 8
CONST stWHILE = 9, stWEND = 10, stSELECT = 11, stCASE = 12, stENDSELECT = 13
CONST stSIF = 14, stSKIP = 15, stSUB = 16, stENDSUB = 17

TYPE stmtType
    lineNo AS LONG
    text AS STRING 'the statement's source, trimmed
    kind AS _BYTE
    match AS LONG 'DO<->LOOP, WHILE<->WEND, FOR->NEXT, NEXT->innermost FOR,
    '              SUB<->END SUB; single-line IF / skip: where to jump
    nextBranch AS LONG 'IF/ELSEIF/ELSE and SELECT/CASE chains
    endIdx AS LONG 'branches -> END IF / END SELECT
    encDo AS LONG 'innermost DO, FOR, WHILE around this statement (0 = none)
    encFor AS LONG
    encWhile AS LONG
    proc AS LONG 'SUB/FUNCTION this statement belongs to (0 = main module)
    nVars AS INTEGER 'NEXT i, j -> 2
    hasCond AS _BYTE 'DO WHILE/UNTIL, LOOP WHILE/UNTIL
END TYPE

TYPE procType
    name AS STRING 'uppercase, without type suffix
    isFunc AS _BYTE
    retType AS _BYTE
    params AS STRING 'parameter list text
    startIdx AS LONG 'the SUB/FUNCTION statement
    endIdx AS LONG 'its END SUB/END FUNCTION
END TYPE

REDIM SHARED stmts(0) AS stmtType
DIM SHARED stmtCount AS LONG
REDIM SHARED procs(0) AS procType
DIM SHARED procCount AS LONG
REDIM SHARED labelName(0) AS STRING, labelStmt(0) AS LONG, labelData(0) AS LONG
DIM SHARED labelCount AS LONG
REDIM SHARED dataItem(0) AS STRING, dataIsStr(0) AS _BYTE
DIM SHARED dataCount AS LONG, dataPtr AS LONG

'runtime state of each FOR statement, indexed by statement number
REDIM SHARED forVar(0) AS LONG, forFinal(0) AS _FLOAT, forStep(0) AS _FLOAT

'compiler state
DIM SHARED cStack(1 TO 1000) AS LONG, cLast(1 TO 1000) AS LONG, csp AS LONG
DIM SHARED cErr$, cErrLine AS LONG, cProc AS LONG
