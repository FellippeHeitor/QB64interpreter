'blocks.bi - program structure table (see blocks.bm)

CONST stOTHER = 0, stDO = 1, stLOOP = 2, stFOR = 3, stNEXT = 4
CONST stIF = 5, stELSEIF = 6, stELSE = 7, stENDIF = 8

TYPE stmtType
    lineNo AS LONG
    pos AS LONG 'where the statement starts in program(lineNo)
    kind AS _BYTE
    match AS LONG 'DO<->LOOP, FOR->its NEXT, NEXT->innermost FOR it closes
    nextBranch AS LONG 'IF/ELSEIF/ELSE -> next ELSEIF/ELSE/END IF
    endIdx AS LONG 'IF/ELSEIF/ELSE -> END IF
    encDo AS LONG 'innermost DO around this statement (0 = none)
    encFor AS LONG 'innermost FOR around this statement (0 = none)
    nVars AS INTEGER 'NEXT i, j -> 2
    hasCond AS _BYTE 'DO WHILE/UNTIL, LOOP WHILE/UNTIL
END TYPE

REDIM SHARED stmts(0) AS stmtType
DIM SHARED stmtCount AS LONG
REDIM SHARED lineFirst(0) AS LONG, lineCnt(0) AS LONG
REDIM SHARED labelName(0) AS STRING, labelLine(0) AS LONG
DIM SHARED labelCount AS LONG

'runtime state of each FOR statement, indexed by statement number
REDIM SHARED forVar(0) AS LONG, forFinal(0) AS _FLOAT, forStep(0) AS _FLOAT
