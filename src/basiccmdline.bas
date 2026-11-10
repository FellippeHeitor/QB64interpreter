OPTION _EXPLICIT

$CONSOLE

CONST true = -1, false = NOT true

DIM SHARED debugging AS _BYTE
debugging = false

'$include:'qXed/qXed.bi'
'$include:'vars.bi'
'$include:'eval.bi'
'$include:'blocks.bi'
'$include:'exec.bi'

REDIM SHARED program(0) AS STRING
DIM SHARED currentLine AS LONG, lineThatErrored AS LONG
DIM SHARED errorHappened AS _BYTE, lastErrorCode AS INTEGER, runtimeErr AS INTEGER
DIM SHARED keyhit AS LONG, screenKeyStatus AS _BYTE
DIM SHARED running AS _BYTE, loaded AS _BYTE, loadedFile$
DIM SHARED loadedFileContents$, MyBad AS _BYTE
DIM L$, L1$, temp$, saveFile$, k$, i AS LONG, j AS LONG
DIM q AS STRING * 1

'Headless mode: "basiccmdline -run file.bas" runs the program with output
'sent to the console (stdout) and exits when it ends. Used by tests/.
'"basiccmdline -script file.txt" types each line of file.txt at the prompt.
DIM SHARED headless AS _BYTE, startFile$, scriptMode AS _BYTE, scriptPos AS LONG
REDIM SHARED scriptLines(0) AS STRING
startFile$ = COMMAND$
IF LCASE$(LEFT$(startFile$, 5)) = "-run " OR LCASE$(LEFT$(startFile$, 8)) = "-script " THEN
    headless = true
    IF LCASE$(LEFT$(startFile$, 8)) = "-script " THEN
        temp$ = _TRIM$(MID$(startFile$, 9))
        IF LEFT$(temp$, 1) = CHR$(34) THEN temp$ = removeQuote$(temp$)
        IF _FILEEXISTS(temp$) = 0 THEN PRINT "File not found - "; temp$: SYSTEM 1
        scriptMode = true
        i = FREEFILE
        OPEN temp$ FOR INPUT AS #i
        DO WHILE NOT EOF(i)
            LINE INPUT #i, temp$
            REDIM _PRESERVE scriptLines(UBOUND(scriptLines) + 1) AS STRING
            scriptLines(UBOUND(scriptLines)) = temp$
        LOOP
        CLOSE #i
        startFile$ = ""
    ELSE
        startFile$ = _TRIM$(MID$(startFile$, 6))
        IF LEFT$(startFile$, 1) = CHR$(34) THEN startFile$ = removeQuote$(startFile$)
    END IF
    _SCREENHIDE
    _DEST _CONSOLE
END IF

IF headless THEN
    'keep the console
ELSEIF debugging = false THEN
    _CONSOLE OFF
ELSE
    _SCREENMOVE _SCREENX + 800, _SCREENY
END IF

KEY 2, "LIST" + CHR$(13)
KEY 3, "LOAD " + CHR$(34)
KEY 4, "SAVE " + CHR$(34)
KEY 5, "RUN" + CHR$(13)
KEY ON

screenKeyStatus = true
FOR i = 1 TO 26: defType(i) = varTypeSINGLE: NEXT

'built-in function names: protected so they can't be assigned to
RESTORE QB64Functions
DIM funcName$
DO
    READ funcName$
    IF funcName$ = "*end*" THEN EXIT DO
    i = searchVar(funcName$)
    IF i = 0 THEN i = newVar(funcName$, varTypeSINGLE, false, true)
    vars(i).protected = true
LOOP
builtinCount = totalVars

QB64Functions:
DATA val,int,asc,cos,sin,len,rnd,timer,time$,date$
DATA chr$,inkey$,_width,_height,_mousex,_mousey,_mousebutton
DATA str$,_resize,_resizewidth,_resizeheight,_scaledwidth
DATA _scaledheight,_screenhide,_console,_blink,_fileexists
DATA _direxists,_devices,_device$,_deviceinput,_lastbutton
DATA _lastaxis,_lastwheel,_button,_buttonchange,_axis,_wheel
DATA _screenx,_screeny,_os$,_title$,_mapunicode,_keydown
DATA _keyhit,_windowhandle,_screenimage,_freetimer,_fullscreen
DATA _smooth,_windowhasfocus,_clipboard$,_clipboardimage
DATA _exit,_openhost,_connected,_connectionaddress,_connectionaddress$
DATA _openconnection,_openclient,environ$,_errorline,_inclerrorline
DATA _acceptfiledrop,_totaldroppedfiles,_droppedfile,_droppedfile$
DATA _newimage,_loadimage,_copyimage,_source,_dest,_display
DATA _pixelsize,_clearcolor,_blend,_defaultcolor,_backgroundcolor
DATA _palettecolor,_loadfont,_fontwidth,_fontheight,_font
DATA _printwidth,_printmode,_rgba,_rgba32,_rgb,_rgb32
DATA _red,_red32,_green,_green32,_blue,_blue32
DATA _alpha,_alpha32,_mouseinput,_mousewheel,freefile
DATA shell,_shellhide,command$,_commandcount,_sndrate
DATA _sndopenraw,_sndrawlen,_sndlen,_sndpaused,_sndopen
DATA _sndgetpos,_sndplaying,_sndcopy,seek,loc,eof
DATA lof,screen,point,tab,spc,pos,sgn,lbound,ubound
DATA oct$,hex$,exp,fix,cdbl,csng,_round,cint,clng
DATA csrlin,mki$,mkl$,mks$,mkd$,mksmbf$,mkdmbf$
DATA cvsmbf,cvdmbf,cvi,cvl,cvs,cvd
DATA string$,space$,instr,_instrrev,mid$,sqr
DATA tan,atn,log,abs,erl,err,ucase$,lcase$,left$
DATA right$,ltrim$,rtrim$,_trim$,_cwd$,_startdir$
DATA _dir$,_inclerrorfile$,_atan2,_hypot,_pi,_desktopheight
DATA _desktopwidth,_screenexists,_controlchr,_stricmp
DATA _strcmp,_autodisplay,_shr,_shl,_deflate$,_inflate$
DATA _readbit,_setbit,_resetbit,_togglebit
DATA _ceil,_min,_max,_bin$,_d2r,_r2d
DATA *end*

IF _FILEEXISTS(startFile$) THEN
    loaded = load(startFile$)
    IF loaded AND NOT headless THEN PRINT "Loaded - "; startFile$
ELSEIF LEN(startFile$) > 0 THEN
    IF LCASE$(RIGHT$(startFile$, 4)) <> ".bas" AND _FILEEXISTS(startFile$ + ".bas") THEN
        loaded = load(startFile$ + ".bas")
        IF loaded AND NOT headless THEN PRINT "Loaded - "; startFile$ + ".bas"
    ELSE
        PRINT "File not found - "; startFile$
    END IF
END IF

ON ERROR GOTO runtimeError

IF headless AND scriptMode = 0 THEN
    IF loaded = 0 THEN SYSTEM 1
    runProgram
    SYSTEM
END IF

'---------------------------------------------------------------- the prompt
DO
    IF scriptMode THEN
        scriptPos = scriptPos + 1
        IF scriptPos > UBOUND(scriptLines) THEN SYSTEM
        L1$ = scriptLines(scriptPos)
        PRINT "."; L1$
    ELSE
        _AUTODISPLAY
        LINE INPUT "."; L1$
    END IF
    L1$ = _TRIM$(L1$)
    L$ = UCASE$(L1$)
    errorHappened = false

    'a line starting with a number replaces that line of the program
    i = INSTR(L$ + " ", " ")
    IF isNumber(LEFT$(L$, i - 1)) AND INSTR(LEFT$(L$, i - 1), ".") = 0 THEN
        IF loaded THEN
            j = VAL(LEFT$(L$, i - 1))
            IF j < 1 THEN
                PRINT "Invalid line number"
            ELSE
                IF j > UBOUND(program) THEN REDIM _PRESERVE program(j) AS STRING
                program(j) = _TRIM$(MID$(L1$, i + 1))
            END IF
        ELSE
            PRINT "No program loaded. Use NEW or LOAD <file>."
        END IF
        _CONTINUE
    END IF

    SELECT CASE L$
        CASE "RUN"
            IF loaded THEN runProgram ELSE PRINT "No program loaded."
        CASE "LIST", "LIST PAUSE"
            listProgram (L$ = "LIST PAUSE")
        CASE "LIST VAR", "LIST VARIABLES"
            listVariables
        CASE "EDIT"
            IF loaded THEN editProgram ELSE PRINT "No program loaded."
        CASE "NEW"
            newProgram ""
        CASE "SAVE"
            IF NOT loaded THEN
                PRINT "No program loaded."
            ELSEIF loadedFile$ = "" THEN
                PRINT "Missing: file name."
            ELSE
                saveProgram loadedFile$
            END IF
        CASE "RELOAD"
            IF loaded AND LEN(loadedFile$) THEN loadProgram loadedFile$ ELSE PRINT "No program loaded."
        CASE "DEBUG ON"
            _CONSOLE ON
            debugging = true
            PRINT "Debugging enabled."
        CASE "DEBUG OFF"
            _CONSOLE OFF
            debugging = false
            PRINT "Debugging disabled."
        CASE "EXIT", "SYSTEM"
            SYSTEM
        CASE ELSE
            IF LEFT$(L$, 5) = "LOAD " THEN
                loadProgram fileArg$(MID$(L1$, 6))
            ELSEIF LEFT$(L$, 5) = "SAVE " THEN
                saveFile$ = fileArg$(MID$(L1$, 6))
                IF NOT loaded THEN
                    PRINT "No program loaded."
                ELSEIF saveFile$ <> loadedFile$ AND _FILEEXISTS(saveFile$) THEN
                    INPUT "Overwrite (y/N)?", q
                    IF LCASE$(q) = "y" THEN saveProgram saveFile$
                ELSE
                    saveProgram saveFile$
                END IF
            ELSEIF LEFT$(L$, 4) = "NEW " THEN
                newProgram fileArg$(MID$(L1$, 5))
            ELSEIF LEFT$(L$, 5) = "LIST " AND VAL(MID$(L$, 6)) > 0 THEN
                j = VAL(MID$(L$, 6))
                IF NOT loaded THEN
                    PRINT "No program loaded."
                ELSEIF j <= UBOUND(program) THEN
                    PRINT program(j)
                ELSE
                    PRINT "Invalid line number -"; j
                END IF
            ELSEIF LEFT$(L$, 7) = "DELETE " THEN
                deleteLines MID$(L$, 8)
            ELSEIF LEN(L$) THEN
                runImmediate L1$
            END IF
    END SELECT
LOOP

runtimeError:
'Errors raised by QB64 while running a statement (bad LOCATE arguments,
'missing files, ...). Remember the first one and let the statement finish;
'the runner reports it and stops the program.
IF MyBad THEN RESUME NEXT
IF runtimeErr = 0 THEN runtimeErr = ERR
RESUME NEXT

'---------------------------------------------------------------- running
SUB resetRunState
    running = true
    callDepth = 0: gosubTop = 0: exitProcFlag = false
    frameId = 0: framePrefix$ = "": curProc = 0: retVar = 0
    errorHappened = false: runtimeErr = 0
END SUB

SUB runProgram
    'RUN: fresh variables, closed files, then the whole program
    clearVars
    CLOSE
    lineThatErrored = 0: lastErrorCode = 0
    IF compileProgram(program()) = 0 THEN EXIT SUB
    immediateRun = false
    resetRunState
    _KEYCLEAR
    runFrom 1
    running = false
END SUB

SUB runImmediate (text$)
    'a line typed at the prompt runs on its own; variables are kept
    REDIM one(1 TO 1) AS STRING
    one(1) = text$
    immediateRun = true
    IF compileProgram(one()) = 0 THEN immediateRun = false: EXIT SUB
    resetRunState
    currentLine = 0
    runFrom 1
    running = false
    immediateRun = false
END SUB

'---------------------------------------------------------------- program editing
SUB loadProgram (f$)
    DIM fname$
    fname$ = f$
    IF _FILEEXISTS(fname$) = 0 AND LCASE$(RIGHT$(fname$, 4)) <> ".bas" THEN fname$ = fname$ + ".bas"
    IF _FILEEXISTS(fname$) THEN
        loaded = load(fname$)
        IF loaded THEN PRINT "Loaded."
    ELSE
        PRINT "File not found - "; f$
    END IF
END SUB

SUB saveProgram (f$)
    DIM ff AS INTEGER, i AS LONG
    ff = FREEFILE
    OPEN f$ FOR OUTPUT AS ff
    FOR i = 1 TO UBOUND(program)
        PRINT #ff, program(i)
    NEXT
    CLOSE ff
    loadedFile$ = f$
    PRINT "Saved - "; loadedFile$
END SUB

SUB newProgram (f$)
    loadedFile$ = f$
    loaded = true
    REDIM program(1) AS STRING
    loadedFileContents$ = CHR$(10)
    editProgram
END SUB

SUB editProgram
    'opens the program in qXed and reads it back
    DIM a AS LONG, b AS LONG, n AS LONG
    _KEYCLEAR
    Editor
    REDIM program(0) AS STRING
    a = 1
    DO
        b = INSTR(a, loadedFileContents$, CHR$(10))
        n = n + 1
        REDIM _PRESERVE program(n) AS STRING
        IF b = 0 THEN
            program(n) = MID$(loadedFileContents$, a)
            EXIT DO
        END IF
        program(n) = MID$(loadedFileContents$, a, b - a)
        a = b + 1
    LOOP
    _KEYCLEAR
END SUB

SUB deleteLines (range$)
    'DELETE n   /   DELETE a-b
    DIM lower AS LONG, upper AS LONG, i AS LONG, d AS LONG
    IF NOT loaded THEN PRINT "No program loaded.": EXIT SUB
    d = INSTR(range$, "-")
    IF d THEN
        lower = VAL(LEFT$(range$, d - 1)): upper = VAL(MID$(range$, d + 1))
    ELSE
        lower = VAL(range$): upper = lower
    END IF
    IF lower > upper THEN SWAP lower, upper
    IF lower < 1 OR upper > UBOUND(program) THEN PRINT "Invalid line number or range": EXIT SUB
    FOR i = upper + 1 TO UBOUND(program)
        program(lower + i - upper - 1) = program(i)
    NEXT
    IF UBOUND(program) - (upper - lower + 1) < 1 THEN
        REDIM program(1) AS STRING
    ELSE
        REDIM _PRESERVE program(UBOUND(program) - (upper - lower + 1)) AS STRING
    END IF
END SUB

SUB listProgram (pause AS _BYTE)
    DIM maxSpaceBefore AS INTEGER, prevFG AS LONG, prevBG AS LONG, i AS LONG
    DIM num$, screenMaxCols AS INTEGER, k$

    IF NOT loaded THEN PRINT "No program loaded.": EXIT SUB
    prevFG = _DEFAULTCOLOR
    prevBG = _BACKGROUNDCOLOR
    IF _PIXELSIZE(_DEST) = 0 THEN screenMaxCols = _WIDTH ELSE screenMaxCols = _WIDTH / _PRINTWIDTH("W")
    maxSpaceBefore = LEN(STR$(UBOUND(program))) + 1

    MyBad = true
    COLOR , 0
    FOR i = 1 TO UBOUND(program)
        num$ = STR$(i)
        num$ = SPACE$(maxSpaceBefore - LEN(num$) - 1) + num$ + " "
        COLOR 8
        PRINT num$;
        COLOR 7
        PRINT program(i);
        IF POS(1) < screenMaxCols THEN PRINT SPACE$((screenMaxCols + 1) - POS(1));

        IF i MOD 20 = 0 AND pause THEN
            COLOR 8
            PRINT "-- hit a key --"
            k$ = "": WHILE k$ = "": k$ = INKEY$: _LIMIT 30: WEND
            IF k$ = CHR$(3) THEN
                COLOR prevFG, prevBG
                MyBad = false
                PRINT "Break."
                EXIT SUB
            END IF
            _KEYCLEAR
        END IF
    NEXT
    COLOR prevFG, prevBG
    MyBad = false
    PRINT "End of file - "; loadedFile$
END SUB

SUB listVariables
    DIM i AS LONG, j AS LONG, d AS LONG, k$
    FOR i = builtinCount + 1 TO totalVars
        IF LEFT$(vars(i).key, 1) = "#" OR vars(i).refIdx THEN _CONTINUE
        j = j + 1
        IF vars(i).isArray THEN
            PRINT vars(i).name; "(";
            FOR d = 1 TO vars(i).nDims
                IF d > 1 THEN PRINT ", ";
                PRINT _TRIM$(STR$(dimLo(vars(i).dimStart + d - 1))); " TO "; _TRIM$(STR$(dimHi(vars(i).dimStart + d - 1)));
            NEXT
            PRINT ")"
        ELSE
            PRINT vars(i).name; " = ";
            IF vars(i).type = varTypeSTRING THEN
                PRINT CHR$(34); strings(i); CHR$(34)
            ELSE
                PRINT numStr$(nums(i), vars(i).type)
            END IF
        END IF
        IF j MOD 20 = 0 AND i < totalVars THEN
            PRINT "-- hit a key --"
            k$ = "": WHILE k$ = "": k$ = INKEY$: _LIMIT 30: WEND
            IF k$ = CHR$(3) THEN PRINT "Break.": EXIT SUB
            _KEYCLEAR
        END IF
    NEXT
END SUB

FUNCTION load%% (file$)
    DIM ff AS INTEGER, l$, n AS LONG
    ff = FREEFILE
    OPEN file$ FOR BINARY AS ff
    REDIM program(0) AS STRING
    loadedFileContents$ = ""
    DO
        IF EOF(ff) THEN EXIT DO
        LINE INPUT #ff, l$
        n = n + 1
        IF n > UBOUND(program) THEN REDIM _PRESERVE program(n + 999) AS STRING
        program(n) = l$
        IF n > 1 THEN loadedFileContents$ = loadedFileContents$ + CHR$(10)
        loadedFileContents$ = loadedFileContents$ + l$
    LOOP
    CLOSE ff

    IF n > 0 THEN
        REDIM _PRESERVE program(n) AS STRING
        load%% = true
        loadedFile$ = file$
    END IF
END FUNCTION

'---------------------------------------------------------------- errors & helpers
SUB db_echo (text$)
    IF debugging THEN _ECHO text$
END SUB

SUB throwError (code AS INTEGER)
    throwErrorMsg errorText$(code)
    lastErrorCode = code
END SUB

SUB throwErrorMsg (msg$)
    IF errorHappened THEN EXIT SUB 'one message per statement
    PRINT msg$;
    IF running AND NOT immediateRun AND currentLine > 0 THEN
        PRINT " on line"; currentLine
        lineThatErrored = currentLine
    ELSE
        PRINT
    END IF
    running = false
    errorHappened = true
END SUB

FUNCTION Find& (start AS LONG, text$, subtext$)
    'like INSTR, but only finds subtext$ outside quotation marks
    DIM i AS LONG, quote AS _BYTE, n AS LONG
    n = LEN(subtext$)
    FOR i = 1 TO LEN(text$) - n + 1
        IF ASC(text$, i) = 34 THEN quote = NOT quote
        IF i >= start AND quote = 0 THEN
            IF MID$(text$, i, n) = subtext$ THEN Find& = i: EXIT FUNCTION
        END IF
    NEXT
END FUNCTION

FUNCTION removeQuote$ (__text$)
    DIM text$

    text$ = __text$

    IF LEFT$(text$, 1) = CHR$(34) THEN
        text$ = MID$(text$, 2)
    END IF

    IF RIGHT$(text$, 1) = CHR$(34) THEN
        text$ = LEFT$(text$, LEN(text$) - 1)
    END IF

    removeQuote$ = text$
END FUNCTION

FUNCTION isNumber%% (__a$)
    DIM i AS LONG
    DIM a AS _UNSIGNED _BYTE
    DIM D AS LONG, E AS LONG
    DIM dp AS LONG
    DIM a$

    a$ = _TRIM$(__a$)

    IF LEN(a$) = 0 THEN EXIT FUNCTION
    FOR i = 1 TO LEN(a$)
        a = ASC(MID$(a$, i, 1))
        IF a = 45 THEN
            IF (i = 1 AND LEN(a$) > 1) OR (i > 1 AND ((D > 0 AND D = i - 1) OR (E > 0 AND E = i - 1))) THEN _CONTINUE
            EXIT FUNCTION
        END IF
        IF a = 46 THEN
            IF dp = 1 THEN EXIT FUNCTION
            dp = 1
            _CONTINUE
        END IF
        IF a = 100 OR a = 68 THEN 'D
            IF D > 0 OR E > 0 THEN EXIT FUNCTION
            IF i = 1 THEN EXIT FUNCTION
            D = i
            _CONTINUE
        END IF
        IF a = 101 OR a = 69 THEN 'E
            IF D > 0 OR E > 0 THEN EXIT FUNCTION
            IF i = 1 THEN EXIT FUNCTION
            E = i
            _CONTINUE
        END IF
        IF a = 43 THEN '+
            IF (D > 0 AND D = i - 1) OR (E > 0 AND E = i - 1) THEN _CONTINUE
            EXIT FUNCTION
        END IF

        IF a >= 48 AND a <= 57 THEN _CONTINUE
        EXIT FUNCTION
    NEXT
    isNumber%% = true
END FUNCTION

FUNCTION splitArgs& (text$, parts$())
    'splits text$ at commas that are outside quotes and parentheses;
    'returns the number of parts (an empty text$ gives 0)
    DIM i AS LONG, c AS INTEGER, depth AS LONG, quote AS _BYTE, n AS LONG, start AS LONG
    IF LEN(_TRIM$(text$)) = 0 THEN splitArgs& = 0: EXIT FUNCTION
    REDIM parts$(1 TO 10)
    start = 1
    FOR i = 1 TO LEN(text$) + 1
        IF i <= LEN(text$) THEN c = ASC(text$, i) ELSE c = 44
        IF c = 34 THEN quote = NOT quote
        IF NOT quote THEN
            IF c = 40 THEN depth = depth + 1
            IF c = 41 THEN depth = depth - 1
            IF (c = 44 AND depth = 0) OR i > LEN(text$) THEN
                n = n + 1
                IF n > UBOUND(parts$) THEN REDIM _PRESERVE parts$(1 TO n + 10)
                parts$(n) = _TRIM$(MID$(text$, start, i - start))
                start = i + 1
            END IF
        END IF
    NEXT
    splitArgs& = n
END FUNCTION

FUNCTION fileArg$ (text$)
    'file names may be given quoted ("my file.bas"), as a string expression
    '(f$ + ".bas"), or bare (myfile.bas)
    DIM t$
    t$ = _TRIM$(text$)
    IF INSTR(t$, CHR$(34)) > 0 OR INSTR(t$, "+") > 0 OR RIGHT$(t$, 1) = "$" THEN
        fileArg$ = Parse$(t$)
    ELSE
        fileArg$ = t$
    END IF
END FUNCTION

FUNCTION errorText$ (code AS INTEGER)
    SELECT CASE code
        CASE 2: errorText$ = "Syntax error"
        CASE 3: errorText$ = "RETURN without GOSUB"
        CASE 4: errorText$ = "Out of DATA"
        CASE 5: errorText$ = "Illegal function call"
        CASE 6: errorText$ = "Overflow"
        CASE 7: errorText$ = "Out of memory"
        CASE 9: errorText$ = "Subscript out of range"
        CASE 10: errorText$ = "Duplicate definition"
        CASE 11: errorText$ = "Division by zero"
        CASE 13: errorText$ = "Type mismatch"
        CASE 52: errorText$ = "Bad file name or number"
        CASE 53: errorText$ = "File not found"
        CASE 54: errorText$ = "Bad file mode"
        CASE 55: errorText$ = "File already open"
        CASE 62: errorText$ = "Input past end of file"
        CASE 64: errorText$ = "Bad file name"
        CASE 68: errorText$ = "Device unavailable"
        CASE 70: errorText$ = "Permission denied"
        CASE 75: errorText$ = "Path/file access error"
        CASE 76: errorText$ = "Path not found"
        CASE 258: errorText$ = "Invalid handle"
        CASE 1001: errorText$ = "Can't assign to a built-in function name"
        CASE 1002: errorText$ = "Can't assign to a CONST"
        CASE 1003: errorText$ = "Wrong number of arguments"
        CASE 1004: errorText$ = "Unknown type"
        CASE ELSE: errorText$ = "Error #" + _TRIM$(STR$(code))
    END SELECT
END FUNCTION

'$include:'vars.bm'
'$include:'eval.bm'
'$include:'blocks.bm'
'$include:'exec.bm'
'$include:'stmts.bm'
'$include:'qXed/qXed.bm'
