OPTION _EXPLICIT

$CONSOLE

CONST true = -1, false = NOT true

DIM SHARED debugging AS _BYTE
debugging = false

'$include:'qXed/qXed.bi'

'Headless mode: "basiccmdline -run file.bas" runs the program with output
'sent to the console (stdout) and exits when it ends. Used by tests/.
DIM SHARED headless AS _BYTE, autoRun AS _BYTE, startFile$
startFile$ = COMMAND$
IF LCASE$(LEFT$(startFile$, 5)) = "-run " THEN
    headless = true
    startFile$ = _TRIM$(MID$(startFile$, 6))
    IF LEFT$(startFile$, 1) = CHR$(34) THEN startFile$ = removeQuote$(startFile$)
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

TYPE vartype
    name AS STRING 'as typed by the user
    key AS STRING 'lowercase name used for lookups
    type AS _BYTE
    scope AS STRING
    protected AS _BYTE
    nextHash AS LONG
END TYPE

TYPE levelControlType
    firstLine AS LONG
    continueAt AS LONG
    lastLine AS LONG
    condition AS _BYTE
    'For DO/LOOP blocks:
    '    0 = no condition; 1 = DO + condition; 2 = LOOP + condition
    stmtPos AS LONG 'where the DO statement starts in its line (1 = line start)
END TYPE

TYPE forControlType
    varName AS STRING
    varIndex AS LONG
    initial AS _FLOAT
    final AS _FLOAT
    theStep AS _FLOAT
    level AS levelControlType
    firstRun AS _BYTE
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

'$include:'eval.bi'


REDIM SHARED vars(0) AS vartype
REDIM SHARED strings(0) AS STRING
REDIM SHARED nums(0) AS _FLOAT
REDIM SHARED program(0) AS STRING
DIM SHARED totalVars AS LONG, varType_DEFAULT AS _BYTE
DIM SHARED thisScope$, currentLine AS LONG, lineThatErrored AS LONG
DIM varIndex AS LONG, i AS LONG, j AS LONG, l AS LONG
DIM continuation$, Ucontinuation$, continueAt AS LONG
DIM stmtPos AS LONG 'where the current statement starts in program(currentLine)
DIM loopControl(100) AS levelControlType
DIM forControl(100) AS forControlType
DIM currentDoLevel AS INTEGER, currentIfLevel AS INTEGER, currentForLevel AS INTEGER
DIM SHARED errorHappened AS _BYTE, lastErrorCode AS INTEGER, runtimeErr AS INTEGER
DIM SHARED keyhit AS LONG, screenKeyStatus AS _BYTE
DIM externalLimit AS INTEGER
DIM temp$, L$, L1$, saveFile$, q AS STRING * 1, k$, varName$
DIM MyBad AS _BYTE, Comma1 AS INTEGER, Comma2 AS INTEGER, Comma3 AS INTEGER
DIM SHARED running AS _BYTE, loaded AS _BYTE, loadedFile$
DIM SHARED loadedFileContents$

thisScope$ = "MAIN MODULE"
varType_DEFAULT = varTypeSINGLE
screenKeyStatus = true

IF _FILEEXISTS(startFile$) THEN
    loaded = load(startFile$)
    IF loaded AND NOT headless THEN PRINT "Loaded - "; startFile$
ELSEIF LEN(startFile$) > 0 THEN
    IF LCASE$(RIGHT$(startFile$, 4)) <> ".bas" THEN
        IF _FILEEXISTS(startFile$ + ".bas") THEN
            loaded = load(startFile$ + ".bas")
            IF loaded AND NOT headless THEN PRINT "Loaded - "; startFile$ + ".bas"
        ELSE
            PRINT "File not found - "; startFile$ + ".bas"
        END IF
    ELSE
        PRINT "File not found - "; startFile$
    END IF
END IF
IF headless THEN
    IF loaded THEN autoRun = true ELSE SYSTEM 1
END IF

'internal variables (functions)
RESTORE QB64Functions
DIM funcName$
DO
    READ funcName$
    IF funcName$ = "*end*" THEN EXIT DO
    varIndex = addVar(funcName$)
    vars(varIndex).protected = true
LOOP

QB64Functions:
DATA val,int,asc,cos,sin,len,rnd,timer,time$,date$, beep, sound
DATA chr$,inkey$,_width,_height,_mousex,_mousey,_mousebutton
DATA str$,asc,_resize,_resizewidth,_resizeheight,_scaledwidth
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
DATA lof,screen,point,tab,spc,inp,pos,sgn,lbound,ubound
DATA oct$,hex$,exp,fix,cdbl,csng,_round,cint,clng
DATA csrlin,mki$,mkl$,mks$,mkd$,mksmbf$,mkdmbf$
DATA _mk$,cvsmbf,cvdmbf,cvi,cvl,cvs,cvd,_cv
DATA string$,space$,instr,_instrrev,mid$,sqr
DATA tan,atn,log,abs,erl,err,ucase$,lcase$,left$
DATA right$,ltrim$,rtrim$,_trim$,_cwd$,_startdir$
DATA _dir$,_inclerrorfile$,_atan2,_hypot,_pi,_desktopheight
DATA _desktopwidth,_screenexists,_controlchr,_stricmp
DATA _strcmp,_autodisplay,_shr,_shl,_deflate$,_inflate$
DATA _readbit,_setbit,_resetbit,_togglebit
DATA *end*

ON ERROR GOTO runtimeError

DO
    keyhit = _KEYHIT
    errorHappened = false
    stmtPos = 1

    IF (ABS(keyhit) = ASC("C") OR ABS(keyhit) = ASC("c")) AND (_KEYDOWN(100305) OR _KEYDOWN(100306)) THEN
        PRINT "Break."
        IF running THEN running = false
        _KEYCLEAR
    END IF

    IF running THEN
        currentLine = currentLine + 1
        IF currentLine > UBOUND(program) THEN
            running = false
        ELSE
            L1$ = program(currentLine)
        END IF
    END IF

    IF NOT running THEN
        IF autoRun THEN
            autoRun = false
            L1$ = "RUN"
        ELSEIF headless THEN
            SYSTEM
        ELSE
            _AUTODISPLAY
            LINE INPUT "."; L1$
        END IF
    END IF

    L1$ = LTRIM$(RTRIM$(L1$))
    L$ = UCASE$(L1$)

    redoThisLine:
    db_echo "running line" + STR$(currentLine)
    db_echo ">> " + L1$
    IF isNumber(LEFT$(L$, INSTR(L$, " ") - 1)) THEN
        IF NOT running THEN
            IF loaded THEN
                i = VAL(LEFT$(L1$, INSTR(L1$, CHR$(32)) - 1))
                L1$ = MID$(L1$, INSTR(L1$, CHR$(32)) + 1)
                IF i > UBOUND(program) THEN
                    REDIM _PRESERVE program(i) AS STRING
                END IF
                program(i) = L1$
            ELSE
                PRINT "No program loaded. Use NEW or LOAD <file>."
            END IF
        ELSE
            L$ = MID$(L$, INSTR(L$, " ") + 1)
            L1$ = MID$(L1$, INSTR(L1$, " ") + 1)
            GOTO redoThisLine
        END IF
    ELSE
        'look for : separators (not in comments or single-line IFs)
        IF LEFT$(L$, 3) <> "IF " AND LEFT$(L$, 1) <> "'" AND LEFT$(L$, 4) <> "REM " THEN
            j = Find(1, L$, ":")
            IF j > 0 AND j < LEN(L$) THEN
                continuation$ = _TRIM$(MID$(L1$, j + 1))
                Ucontinuation$ = _TRIM$(MID$(L$, j + 1))
                L1$ = _TRIM$(LEFT$(L1$, j - 1))
                L$ = _TRIM$(LEFT$(L$, j - 1))
                continueAt = _INSTRREV(program(currentLine), continuation$)
            ELSEIF j = LEN(L$) THEN
                IF INSTR(L$, " ") > 0 THEN
                    L$ = LEFT$(L$, LEN(L$) - 1)
                    L1$ = LEFT$(L1$, LEN(L1$) - 1)
                    continuation$ = ""
                    Ucontinuation$ = ""
                    continueAt = 0
                ELSE
                    'likely a label, leave it as is
                END IF
            ELSE
                continuation$ = ""
                Ucontinuation$ = ""
                continueAt = 0
            END IF
        ELSE
            continuation$ = ""
            Ucontinuation$ = ""
            continueAt = 0
        END IF

        IF LEFT$(L$, 5) = "LOAD " THEN
            IF NOT running THEN
                temp$ = fileArg$(MID$(L1$, 6))
                tryWithExtension:
                IF _FILEEXISTS(temp$) THEN
                    loaded = load(temp$)
                    IF loaded THEN PRINT "Loaded."
                ELSE
                    IF RIGHT$(temp$, 4) = ".bas" THEN
                        PRINT "File not found - "; temp$
                    ELSE
                        temp$ = temp$ + ".bas"
                        GOTO tryWithExtension
                    END IF
                END IF
            END IF
        ELSEIF L$ = "RELOAD" THEN
            IF NOT running THEN
                IF loaded THEN
                    L1$ = "LOAD " + CHR$(34) + loadedFile$ + CHR$(34)
                    L$ = UCASE$(L1$)
                    GOTO redoThisLine
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
            'ELSEIF LEFT$(L$, 7) = "INSERT " AND VAL(MID$(L$, 8)) > 0 THEN
            '    IF NOT running THEN
            '        IF loaded THEN
            '            IF VAL(MID$(L$, 8)) <= UBOUND(program) THEN
            '                REDIM _PRESERVE program(UBOUND(program) + 1) AS STRING
            '                FOR i = UBOUND(program) - 1 TO VAL(MID$(L$, 8)) STEP -1
            '                    program(i + 1) = program(i)
            '                NEXT
            '                program(VAL(MID$(L$, 8))) = ""
            '                L$ = "EDIT " + MID$(L$, 8)
            '                GOTO Edit
            '            ELSE
            '                PRINT "Invalid line number -"; VAL(MID$(L$, 8))
            '            END IF
            '        ELSE
            '            PRINT "No program loaded."
            '        END IF
            '    END IF
        ELSEIF LEFT$(L$, 6) = "CHDIR " THEN
            CHDIR fileArg$(MID$(L1$, 7))
        ELSEIF LEFT$(L$, 6) = "MKDIR " THEN
            MKDIR fileArg$(MID$(L1$, 7))
        ELSEIF LEFT$(L$, 5) = "KILL " THEN
            KILL fileArg$(MID$(L1$, 6))
        ELSEIF L$ = "DEBUG ON" THEN
            _CONSOLE ON
            debugging = true
            PRINT "Debugging enabled."
        ELSEIF L$ = "DEBUG OFF" THEN
            _CONSOLE OFF
            debugging = false
            PRINT "Debugging disabled."
        ELSEIF LEFT$(L$, 7) = "DELETE " AND VAL(MID$(L$, 8)) > 0 THEN
            IF NOT running THEN
                IF loaded THEN
                    IF INSTR(MID$(L$, 8), "-") = 0 THEN
                        IF VAL(MID$(L$, 8)) <= UBOUND(program) THEN
                            FOR i = VAL(MID$(L$, 8)) + 1 TO UBOUND(program)
                                program(i - 1) = program(i)
                            NEXT
                            REDIM _PRESERVE program(UBOUND(program) - 1) AS STRING
                        ELSE
                            PRINT "Invalid line number -"; VAL(MID$(L$, 8))
                        END IF
                    ELSE
                        'interval
                        DIM lower AS LONG, upper AS LONG
                        DIM interval$
                        interval$ = MID$(L$, 8)
                        lower = VAL(LEFT$(interval$, INSTR(interval$, "-") - 1))
                        upper = VAL(MID$(interval$, INSTR(interval$, "-") + 1))
                        IF lower > upper THEN SWAP lower, upper

                        IF lower < 1 OR upper > UBOUND(program) THEN
                            PRINT "Invalid interval ("; LTRIM$(RTRIM$(interval$)); ")"
                        ELSE
                            FOR i = upper + 1 TO UBOUND(program)
                                program(lower + (i - (upper + 1))) = program(i)
                            NEXT
                            REDIM _PRESERVE program(UBOUND(program) - (upper - lower) - 1) AS STRING
                        END IF
                    END IF
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF L$ = "SAVE" THEN
            IF NOT running THEN
                IF loaded THEN
                    IF loadedFile$ = "" THEN
                        PRINT "Missing: file name."
                    ELSE
                        DIM ff AS INTEGER
                        ff = FREEFILE
                        OPEN loadedFile$ FOR OUTPUT AS ff
                        FOR i = 1 TO UBOUND(program)
                            PRINT #ff, program(i)
                        NEXT
                        CLOSE ff
                        PRINT "Saved - "; loadedFile$
                    END IF
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF LEFT$(L$, 5) = "SAVE " THEN
            IF NOT running THEN
                saveFile$ = fileArg$(MID$(L1$, 6))
                'db_echo "About to save '" + saveFile$ + "'"
                IF loaded THEN
                    IF saveFile$ <> loadedFile$ THEN
                        IF _FILEEXISTS(saveFile$) THEN
                            INPUT "Overwrite (y/N)?", q$1
                            IF LCASE$(q$1) = "y" THEN
                                GOTO overWrite
                            END IF
                        ELSE
                            GOTO overWrite
                        END IF
                    ELSE
                        overWrite:
                        'db_echo "About to OPEN AS '" + LTRIM$(STR$(ff)) + "'"
                        ff = FREEFILE
                        OPEN saveFile$ FOR OUTPUT AS ff
                        FOR i = 1 TO UBOUND(program)
                            PRINT #ff, program(i)
                        NEXT
                        CLOSE ff
                        loadedFile$ = saveFile$
                        PRINT "Saved - "; loadedFile$
                    END IF
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF L$ = "CLEAR" THEN
            clearVars
        ELSEIF L$ = "NEW" OR LEFT$(L$, 4) = "NEW " THEN
            IF NOT running THEN
                IF LEN(L$) > 3 THEN loadedFile$ = fileArg$(MID$(L1$, 5)) ELSE loadedFile$ = ""
                loaded = true
                REDIM SHARED program(1) AS STRING
                loadedFileContents$ = CHR$(10)
                GOTO launchEditor
            END IF
        ELSEIF L$ = "_DISPLAY" THEN
            _DISPLAY
            'ELSEIF LEFT$(L$, 5) = "EDIT " AND VAL(MID$(L$, 6)) > 0 THEN
            '    IF NOT running THEN
            '        Edit:
            '        IF loaded THEN
            '            IF VAL(MID$(L$, 6)) = UBOUND(program) + 1 THEN
            '                REDIM _PRESERVE program(UBOUND(program) + 1) AS STRING
            '                'EDIT can be used to increase program size without the need for INSERT
            '            END IF

            '            IF VAL(MID$(L$, 6)) <= UBOUND(program) THEN
            '                DIM row AS INTEGER, col AS INTEGER
            '                row = CSRLIN: col = POS(1)
            '                PRINT LEFT$(program(VAL(MID$(L$, 6))), 80);
            '                DO
            '                    LOCATE row, col, 1
            '                    k$ = "": WHILE k$ = "": k$ = INKEY$: _LIMIT 30: WEND
            '                    SELECT CASE k$
            '                        CASE CHR$(13)
            '                            DIM p$
            '                            p$ = ""
            '                            FOR i = 1 TO 80
            '                                p$ = p$ + CHR$(SCREEN(row, i))
            '                            NEXT
            '                            program(VAL(MID$(L$, 6))) = RTRIM$(p$)
            '                            EXIT DO
            '                        CASE CHR$(27)
            '                            EXIT DO
            '                        CASE CHR$(8)
            '                            IF col > 1 THEN
            '                                FOR i = col TO 80
            '                                    LOCATE row, i - 1
            '                                    PRINT CHR$(SCREEN(row, i));
            '                                NEXT
            '                                col = col - 1
            '                            END IF
            '                        CASE CHR$(0) + CHR$(83)
            '                            FOR i = col TO 79
            '                                LOCATE row, i
            '                                PRINT CHR$(SCREEN(row, i + 1));
            '                            NEXT
            '                        CASE CHR$(0) + CHR$(75)
            '                            IF col > 1 THEN col = col - 1
            '                        CASE CHR$(0) + CHR$(77)
            '                            IF col < 80 THEN col = col + 1
            '                        CASE ELSE
            '                            PRINT k$;
            '                            IF col < 80 THEN col = col + 1
            '                    END SELECT
            '                LOOP
            '                PRINT
            '                LOCATE , , 0
            '            ELSE
            '                PRINT "Invalid line number -"; VAL(MID$(L$, 6))
            '            END IF
            '        ELSE
            '            PRINT "No program loaded."
            '        END IF
            '    END IF
        ELSEIF L$ = "EDIT" THEN
            IF NOT running THEN
                launchEditor:
                IF loaded THEN
                    _KEYCLEAR
                    Editor
                    DIM findLF1 AS LONG, findLF2 AS LONG
                    findLF1 = INSTR(loadedFileContents$, CHR$(10))
                    IF findLF1 THEN
                        currentLine = 1
                        IF currentLine > UBOUND(program) THEN REDIM _PRESERVE program(currentLine + 999) AS STRING
                        program(currentLine) = LEFT$(loadedFileContents$, findLF1 - 1)
                        DO WHILE findLF1
                            findLF2 = INSTR(findLF1 + 1, loadedFileContents$, CHR$(10))
                            currentLine = currentLine + 1
                            IF currentLine > UBOUND(program) THEN REDIM _PRESERVE program(currentLine + 999) AS STRING
                            IF findLF2 = 0 THEN
                                program(currentLine) = MID$(loadedFileContents$, findLF1 + 1)
                            ELSE
                                program(currentLine) = MID$(loadedFileContents$, findLF1 + 1, findLF2 - findLF1 - 1)
                            END IF
                            findLF1 = findLF2
                        LOOP
                        REDIM _PRESERVE program(currentLine) AS STRING
                        currentLine = 0
                    ELSE
                        REDIM _PRESERVE program(1) AS STRING
                        program(1) = loadedFileContents$
                    END IF
                    _KEYCLEAR
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF L$ = "LIST VARIABLES" OR L$ = "LIST VAR" THEN
            IF NOT running THEN
                j = 0
                'db_echo "Listing variables"
                'db_echo "Total vars:" + STR$(totalVars)
                FOR i = 1 TO totalVars
                    IF NOT vars(i).protected THEN
                        j = j + 1
                        PRINT RTRIM$(vars(i).name); " = ";
                        IF vars(i).type = varTypeSTRING THEN
                            PRINT CHR$(34); strings(i); CHR$(34)
                        ELSE
                            PRINT numStr$(nums(i), vars(i).type)
                        END IF

                        IF j MOD 20 = 0 AND i < totalVars THEN
                            PRINT "-- hit a key --"
                            k$ = "": WHILE k$ = "": k$ = INKEY$: _LIMIT 30: WEND
                            IF k$ = CHR$(3) THEN
                                PRINT "Break."
                                GOTO ListEnd
                            END IF
                            _KEYCLEAR
                        END IF
                    END IF
                NEXT
            END IF
        ELSEIF L$ = "LIST" OR L$ = "LIST PAUSE" THEN
            IF NOT running THEN
                IF loaded THEN
                    DIM maxSpaceBefore AS INTEGER, prevFG AS LONG, prevBG AS LONG
                    DIM thisLineNum$, screenMaxCols AS INTEGER

                    prevFG = _DEFAULTCOLOR
                    prevBG = _BACKGROUNDCOLOR

                    IF _PIXELSIZE(_DEST) = 0 THEN
                        screenMaxCols = _WIDTH
                    ELSE
                        screenMaxCols = _WIDTH / _PRINTWIDTH("W")
                    END IF

                    maxSpaceBefore = LEN(STR$(UBOUND(program))) + 1

                    MyBad = true
                    COLOR , 0
                    MyBad = false

                    FOR i = 1 TO UBOUND(program)
                        thisLineNum$ = STR$(i)
                        thisLineNum$ = SPACE$(maxSpaceBefore - LEN(thisLineNum$) - 1) + thisLineNum$ + " "
                        MyBad = true
                        COLOR 8
                        MyBad = false
                        PRINT thisLineNum$;

                        MyBad = true
                        COLOR 7
                        MyBad = false
                        PRINT program(i);

                        IF POS(1) < screenMaxCols THEN
                            PRINT SPACE$((screenMaxCols + 1) - POS(1));
                        END IF

                        IF i MOD 20 = 0 AND L$ = "LIST PAUSE" THEN
                            MyBad = true
                            COLOR 8
                            MyBad = false

                            PRINT "-- hit a key --"
                            k$ = "": WHILE k$ = "": k$ = INKEY$: _LIMIT 30: WEND
                            IF k$ = CHR$(3) THEN
                                COLOR prevFG, prevBG
                                PRINT "Break."
                                GOTO ListEnd
                            END IF
                            _KEYCLEAR
                        END IF
                    NEXT
                    COLOR prevFG, prevBG
                    PRINT "End of file - "; loadedFile$
                    ListEnd:
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF LEFT$(L$, 5) = "LIST " AND VAL(MID$(L$, 6)) > 0 THEN
            IF NOT running THEN
                IF loaded THEN
                    IF VAL(MID$(L$, 6)) <= UBOUND(program) THEN
                        PRINT program(VAL(MID$(L$, 6)))
                    ELSE
                        PRINT "Invalid line number -"; VAL(MID$(L$, 6))
                    END IF
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF LEFT$(L$, 6) = "WIDTH " THEN
            REDIM arg$(0)
            SELECT CASE splitArgs(MID$(L1$, 7), arg$())
                CASE 1
                    WIDTH evalNum(arg$(1))
                CASE 2
                    IF LEN(arg$(1)) = 0 THEN
                        WIDTH , evalNum(arg$(2))
                    ELSEIF LEN(arg$(2)) = 0 THEN
                        WIDTH evalNum(arg$(1))
                    ELSE
                        WIDTH evalNum(arg$(1)), evalNum(arg$(2))
                    END IF
                CASE ELSE
                    GOTO syntaxerror
            END SELECT
        ELSEIF L$ = "RANDOMIZE" THEN
            RANDOMIZE TIMER
        ELSEIF LEFT$(L$, 10) = "RANDOMIZE " THEN
            RANDOMIZE evalNum(MID$(L1$, 11))
        ELSEIF LEFT$(L$, 7) = "_LIMIT " THEN
            externalLimit = evalNum(MID$(L1$, 8))
        ELSEIF LEFT$(L$, 1) = "'" OR LEFT$(L$, 4) = "REM " OR L$ = "'" OR L$ = "REM" OR L$ = "" THEN
            'it's a comment.
        ELSEIF LEFT$(L$, 4) = "KEY " THEN
            IF _TRIM$(MID$(L$, 5)) = "ON" THEN
                KEY ON
                screenKeyStatus = true
            ELSEIF _TRIM$(MID$(L$, 5)) = "OFF" THEN
                KEY OFF
                screenKeyStatus = false
            ELSE
                GOTO syntaxerror
            END IF
        ELSEIF L$ = "RUN" THEN
            IF NOT running THEN
                IF loaded THEN
                    'start clean: no variables, no open blocks from a previous run
                    clearVars
                    FOR i = 0 TO UBOUND(loopControl)
                        loopControl(i).firstLine = 0
                        loopControl(i).lastLine = 0
                        loopControl(i).continueAt = 0
                        loopControl(i).condition = 0
                        loopControl(i).stmtPos = 0
                    NEXT
                    FOR i = 0 TO UBOUND(forControl)
                        forControl(i).level.firstLine = 0
                        forControl(i).level.lastLine = 0
                        forControl(i).level.continueAt = 0
                        forControl(i).varIndex = 0
                        forControl(i).varName = ""
                    NEXT
                    currentLine = 0
                    currentDoLevel = 0
                    currentIfLevel = 0
                    currentForLevel = 0
                    externalLimit = 0
                    lineThatErrored = 0
                    lastErrorCode = 0
                    running = true
                    _KEYCLEAR
                ELSE
                    PRINT "No program loaded."
                END IF
            END IF
        ELSEIF LEFT$(L$, 6) = "COLOR " THEN
            REDIM arg$(0)
            SELECT CASE splitArgs(MID$(L1$, 7), arg$())
                CASE 1
                    COLOR evalNum(arg$(1))
                CASE 2
                    IF LEN(arg$(1)) = 0 THEN
                        COLOR , evalNum(arg$(2))
                    ELSEIF LEN(arg$(2)) = 0 THEN
                        COLOR evalNum(arg$(1))
                    ELSE
                        COLOR evalNum(arg$(1)), evalNum(arg$(2))
                    END IF
                CASE ELSE
                    GOTO syntaxerror
            END SELECT
        ELSEIF LEFT$(L$, 7) = "_BLINK " THEN
            IF _TRIM$(MID$(L$, 8)) = "ON" THEN
                _BLINK ON
            ELSEIF _TRIM$(MID$(L$, 8)) = "OFF" THEN
                _BLINK OFF
            ELSE
                GOTO syntaxerror
            END IF
        ELSEIF LEFT$(L$, 7) = "LOCATE " THEN
            DIM row AS LONG, col AS LONG
            REDIM arg$(0)
            l = splitArgs(MID$(L1$, 8), arg$())
            IF l > 3 THEN GOTO syntaxerror
            row = CSRLIN: col = POS(0)
            IF l >= 1 THEN IF LEN(arg$(1)) THEN row = evalNum(arg$(1))
            IF l >= 2 THEN IF LEN(arg$(2)) THEN col = evalNum(arg$(2))
            IF errorHappened = 0 THEN
                LOCATE row, col
                IF l >= 3 THEN IF LEN(arg$(3)) THEN LOCATE , , evalNum(arg$(3))
            END IF
        ELSEIF LEFT$(L$, 6) = "FILES " THEN
            FILES fileArg$(MID$(L1$, 7))
        ELSEIF L$ = "FILES" THEN
            FILES
        ELSEIF LEFT$(L$, 9) = "_SNDPLAY " THEN
            _SNDPLAY evalNum(MID$(L1$, 10))
        ELSEIF L$ = "BEEP" THEN
            BEEP
        ELSEIF LEFT$(L$, 6) = "SOUND " THEN
            DIM freq AS SINGLE, dur AS SINGLE
            REDIM arg$(0)
            IF splitArgs(MID$(L1$, 7), arg$()) <> 2 THEN GOTO syntaxerror
            freq = evalNum(arg$(1))
            dur = evalNum(arg$(2))
            IF errorHappened = 0 THEN
                IF freq = 0 OR (freq >= 37 AND freq <= 32767) THEN
                    SOUND freq, dur
                ELSE
                    throwError 5
                END IF
            END IF
        ELSEIF LEFT$(L$, 7) = "CIRCLE " OR LEFT$(L$, 7) = "CIRCLE(" THEN
            doCircle MID$(L1$, 7)
        ELSEIF L$ = "SLEEP" THEN
            SLEEP
        ELSEIF LEFT$(L$, 6) = "SLEEP " THEN
            SLEEP evalNum(MID$(L1$, 7))
        ELSEIF L$ = "PRINT" OR L$ = "?" THEN
            PRINT
        ELSEIF LEFT$(L$, 6) = "PRINT " THEN
            doPrint MID$(L1$, 7)
        ELSEIF LEFT$(L$, 1) = "?" THEN
            doPrint MID$(L1$, 2)
        ELSEIF LEFT$(L$, 7) = "_TITLE " THEN
            temp$ = Parse$(MID$(L1$, 8))
            _TITLE temp$
        ELSEIF L$ = "CLS" THEN
            CLS
            IF debugging THEN
                i = _DEST
                _DEST _CONSOLE
                CLS
                _DEST i
            END IF
        ELSEIF L$ = "SYSTEM" OR L$ = "EXIT" THEN
            SYSTEM
        ELSEIF L$ = "STOP" THEN
            running = false
        ELSEIF L$ = "END" THEN
            IF running THEN running = false
        ELSEIF LEFT$(L$, 6) = "INPUT " THEN
            doInput MID$(L1$, 7), false
        ELSEIF LEFT$(L$, 11) = "LINE INPUT " THEN
            doInput MID$(L1$, 12), true
        ELSEIF LEFT$(L$, 4) = "FOR " THEN
            IF NOT running THEN
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            ELSE
                i = Find(1, L$, "=")
                j = Find(i + 1, L$, " TO ")
                l = Find(j + 4, L$, " STEP ")
                IF i = 0 OR j = 0 THEN
                    PRINT "Expected FOR variable = lower TO upper on line"; currentLine
                    running = false
                    GOTO Parse.Done
                ELSE
                    DIM forInitial AS _FLOAT
                    currentForLevel = currentForLevel + 1
                    IF forControl(currentForLevel).level.firstLine <> currentLine THEN
                        forControl(currentForLevel).level.firstLine = currentLine
                        forControl(currentForLevel).level.continueAt = continueAt
                        forControl(currentForLevel).level.lastLine = 0
                        forControl(currentForLevel).varIndex = 0
                    END IF

                    forControl(currentForLevel).firstRun = true
                    forControl(currentForLevel).varName = _TRIM$(MID$(L1$, 5, i - 5))
                    forInitial = evalNum(MID$(L1$, i + 1, j - i - 1))
                    IF l THEN
                        forControl(currentForLevel).final = evalNum(MID$(L1$, j + 4, l - j - 4))
                        forControl(currentForLevel).theStep = evalNum(MID$(L1$, l + 6))
                    ELSE
                        forControl(currentForLevel).final = evalNum(MID$(L1$, j + 4))
                        forControl(currentForLevel).theStep = 1
                    END IF
                    IF errorHappened THEN GOTO Parse.Done

                    varIndex = addVar(forControl(currentForLevel).varName)
                    IF vars(varIndex).type = varTypeSTRING OR vars(varIndex).protected THEN throwError 13: GOTO Parse.Done
                    forControl(currentForLevel).varIndex = varIndex
                    nums(varIndex) = coerce(forInitial, vars(varIndex).type)
                    'QB64 converts the limits to the loop variable's type
                    forControl(currentForLevel).final = coerce(forControl(currentForLevel).final, vars(varIndex).type)
                    forControl(currentForLevel).theStep = coerce(forControl(currentForLevel).theStep, vars(varIndex).type)
                    GOTO treatAsNext
                END IF
            END IF
        ELSEIF L$ = "NEXT" THEN
            IF running THEN
                IF currentForLevel = 0 THEN
                    running = false
                    PRINT "NEXT without FOR on line"; currentLine
                    GOTO Parse.Done
                ELSE
                    treatAsNext:
                    DIM forFirst AS _BYTE, forDone AS _BYTE
                    varIndex = forControl(currentForLevel).varIndex
                    forFirst = forControl(currentForLevel).firstRun

                    IF forFirst THEN
                        forControl(currentForLevel).firstRun = false
                    ELSE
                        forControl(currentForLevel).level.lastLine = currentLine
                        nums(varIndex) = coerce(nums(varIndex) + forControl(currentForLevel).theStep, vars(varIndex).type)
                    END IF

                    IF forControl(currentForLevel).theStep < 0 THEN
                        forDone = (nums(varIndex) < forControl(currentForLevel).final)
                    ELSE
                        forDone = (nums(varIndex) > forControl(currentForLevel).final)
                    END IF
                    IF forDone THEN
                        'FOR whose range is empty: skip the body; loop that just
                        'finished at NEXT: carry on after NEXT
                        IF forFirst THEN GOTO treatAsExitFor
                        currentForLevel = currentForLevel - 1
                        GOTO Parse.Done
                    END IF

                    'next iteration: continue right after the FOR statement
                    currentLine = forControl(currentForLevel).level.firstLine
                    continuation$ = ""
                    Ucontinuation$ = ""
                    IF forControl(currentForLevel).level.continueAt > 0 THEN
                        stmtPos = forControl(currentForLevel).level.continueAt
                        L1$ = MID$(program(currentLine), stmtPos)
                        L$ = UCASE$(L1$)
                        GOTO redoThisLine
                    END IF
                END IF
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF LEFT$(L$, 5) = "NEXT " THEN
            IF running THEN
                IF currentForLevel = 0 THEN
                    running = false
                    PRINT "NEXT without FOR on line"; currentLine
                    GOTO Parse.Done
                ELSE
                    IF UCASE$(_TRIM$(MID$(L1$, 6))) <> UCASE$(forControl(currentForLevel).varName) THEN
                        running = false
                        PRINT "Incorrect variable after NEXT on line"; currentLine
                        GOTO Parse.Done
                    ELSE
                        GOTO treatAsNext
                    END IF
                END IF
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF L$ = "EXIT FOR" THEN
            IF running THEN
                IF currentForLevel = 0 THEN
                    running = false
                    PRINT "EXIT FOR without FOR on line"; currentLine
                    GOTO Parse.Done
                ELSE
                    treatAsExitFor:
                    IF forControl(currentForLevel).level.lastLine > 0 THEN
                        currentLine = forControl(currentForLevel).level.lastLine
                    ELSE
                        j = findBlockEnd(continuation$, currentLine, 2)
                        IF j = 0 THEN PRINT "FOR without NEXT on line"; forControl(currentForLevel).level.firstLine: running = false: GOTO Parse.Done
                        currentLine = j
                    END IF
                    currentForLevel = currentForLevel - 1
                    continuation$ = ""
                    Ucontinuation$ = ""
                END IF
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF L$ = "_CONTINUE" THEN
            IF running THEN
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF L$ = "DO" OR LEFT$(L$, 9) = "DO UNTIL " OR LEFT$(L$, 9) = "DO WHILE " THEN
            IF running THEN
                currentDoLevel = currentDoLevel + 1
                IF loopControl(currentDoLevel).firstLine <> currentLine THEN
                    loopControl(currentDoLevel).firstLine = currentLine
                    loopControl(currentDoLevel).lastLine = 0
                    loopControl(currentDoLevel).continueAt = continueAt
                END IF
                loopControl(currentDoLevel).stmtPos = stmtPos
                IF L$ = "DO" THEN
                    loopControl(currentDoLevel).condition = 0
                ELSE
                    loopControl(currentDoLevel).condition = 1
                    DIM doCond AS _FLOAT
                    doCond = evalNum(MID$(L1$, 10))
                    IF errorHappened THEN GOTO Parse.Done
                    IF LEFT$(L$, 9) = "DO UNTIL " THEN
                        IF doCond <> 0 THEN GOTO treatAsExitDo
                    ELSE
                        IF doCond = 0 THEN GOTO treatAsExitDo
                    END IF
                END IF
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF LEFT$(L$, 5) = "GOTO " THEN
            IF running THEN
                DIM theLabel$
                theLabel$ = _TRIM$(MID$(L$, 6))

                IF isNumber(theLabel$) THEN theLabel$ = theLabel$ + " " ELSE theLabel$ = theLabel$ + ": "
                'look for label
                FOR i = 1 TO UBOUND(program)
                    temp$ = UCASE$(_TRIM$(program(i))) + " "
                    IF LEFT$(temp$, INSTR(temp$, " ")) = UCASE$(theLabel$) THEN
                        currentLine = i - 1
                        continuation$ = ""
                        Ucontinuation$ = ""
                        GOTO Parse.Done
                    END IF
                NEXT
                PRINT "Label not found on line"; currentLine: running = false: GOTO Parse.Done
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF L$ = "LOOP" OR LEFT$(L$, 11) = "LOOP UNTIL " OR LEFT$(L$, 11) = "LOOP WHILE " THEN
            IF NOT running THEN
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF

            IF currentDoLevel = 0 THEN
                'not inside a DO we know about (e.g. after GOTO): scan backwards for it
                j = 0
                FOR i = currentLine - 1 TO 1 STEP -1
                    temp$ = UCASE$(_TRIM$(program(i)))
                    IF temp$ = "LOOP" OR LEFT$(temp$, 5) = "LOOP " THEN j = j + 1
                    IF temp$ = "DO" OR LEFT$(temp$, 3) = "DO " OR LEFT$(temp$, 3) = "DO:" THEN
                        IF j = 0 THEN EXIT FOR
                        j = j - 1
                    END IF
                NEXT
                IF i < 1 THEN PRINT "LOOP without DO on line"; currentLine: running = false: GOTO Parse.Done
                currentDoLevel = 1
                loopControl(1).firstLine = i
                loopControl(1).lastLine = currentLine
                loopControl(1).stmtPos = 1
                loopControl(1).condition = 0
            END IF

            IF L$ <> "LOOP" THEN
                IF loopControl(currentDoLevel).condition = 1 THEN PRINT "LOOP UNTIL/WHILE not allowed in the same block as DO UNTIL/WHILE on line"; currentLine: running = false: GOTO Parse.Done
                loopControl(currentDoLevel).condition = 2
                DIM loopCond AS _FLOAT
                loopCond = evalNum(MID$(L1$, 12))
                IF errorHappened THEN GOTO Parse.Done
                IF LEFT$(L$, 11) = "LOOP UNTIL " THEN loopCond = (loopCond = 0)
                IF loopCond = 0 THEN
                    'loop ends
                    currentDoLevel = currentDoLevel - 1
                    GOTO Parse.Done
                END IF
            END IF

            'jump back to the DO statement
            loopControl(currentDoLevel).lastLine = currentLine
            i = loopControl(currentDoLevel).stmtPos
            currentLine = loopControl(currentDoLevel).firstLine
            currentDoLevel = currentDoLevel - 1
            continuation$ = ""
            Ucontinuation$ = ""
            IF i > 1 THEN
                'DO is in the middle of its line
                stmtPos = i
                L1$ = MID$(program(currentLine), i)
                L$ = UCASE$(L1$)
                GOTO redoThisLine
            ELSE
                currentLine = currentLine - 1
            END IF
        ELSEIF L$ = "EXIT DO" THEN
            IF running THEN
                IF currentDoLevel = 0 THEN
                    PRINT "EXIT DO without DO on line"; currentLine: running = false: GOTO Parse.Done
                END IF

                treatAsExitDo:
                IF loopControl(currentDoLevel).lastLine > 0 THEN
                    currentLine = loopControl(currentDoLevel).lastLine
                ELSE
                    j = findBlockEnd(continuation$, currentLine, 1)
                    IF j = 0 THEN PRINT "DO without LOOP on line"; loopControl(currentDoLevel).firstLine: running = false: GOTO Parse.Done
                    currentLine = j
                END IF
                currentDoLevel = currentDoLevel - 1
                continuation$ = ""
                Ucontinuation$ = ""
            ELSE
                PRINT "Not valid in immediate mode."
                GOTO Parse.Done
            END IF
        ELSEIF LEFT$(L$, 7) = "SCREEN " THEN
            SCREEN evalNum(MID$(L1$, 8))
        ELSEIF LEFT$(L$, 12) = "_SCREENMOVE " THEN
            IF _TRIM$(MID$(L$, 13)) = "_MIDDLE" THEN
                _SCREENMOVE _MIDDLE
            ELSE
                REDIM arg$(0)
                IF splitArgs(MID$(L1$, 13), arg$()) <> 2 THEN GOTO syntaxerror
                IF LEN(arg$(1)) = 0 OR LEN(arg$(2)) = 0 THEN GOTO syntaxerror
                _SCREENMOVE evalNum(arg$(1)), evalNum(arg$(2))
            END IF
        ELSEIF L$ = "ELSE" OR LEFT$(L$, 7) = "ELSEIF " THEN
            IF running THEN
                'reached the end of the branch that ran: skip to the matching END IF
                IF LEFT$(L$, 7) = "ELSEIF " AND RIGHT$(L$, 5) <> " THEN" THEN
                    PRINT "Expected ELSEIF condition THEN on line"; currentLine
                    running = false
                    GOTO Parse.Done
                END IF
                j = findBlockEnd("", currentLine, 3)
                IF j = 0 THEN PRINT "IF without END IF on line"; currentLine: running = false: GOTO Parse.Done
                currentLine = j
                currentIfLevel = currentIfLevel - 1
            ELSE
                PRINT "Not valid in immediate mode."
            END IF
        ELSEIF L$ = "END IF" OR L$ = "ENDIF" THEN
            IF running THEN
                currentIfLevel = currentIfLevel - 1
            ELSE
                PRINT "Not valid in immediate mode."
            END IF
        ELSEIF LEFT$(L$, 3) = "IF " THEN
            IF RIGHT$(L$, 5) = " THEN" THEN
                'IF-THEN-ELSEIF-ELSE-END IF block
                IF NOT running THEN
                    PRINT "IF blocks are not valid in immediate mode."
                    GOTO Parse.Done
                END IF

                DIM i$, ifCond AS _FLOAT

                currentIfLevel = currentIfLevel + 1
                db_echo "IF block, line" + STR$(currentLine)
                db_echo "Current IF level:" + STR$(currentIfLevel)

                checkBlockCondition:
                i$ = MID$(L1$, 4, LEN(L1$) - 8)
                ifCond = evalNum(i$)
                IF errorHappened THEN GOTO Parse.Done

                IF ifCond = 0 THEN 'condition is false
                    j = currentIfLevel
                    DO
                        currentLine = currentLine + 1
                        IF currentLine > UBOUND(program) THEN PRINT "IF without END IF on line"; currentLine: running = false: GOTO Parse.Done
                        L1$ = program(currentLine)
                        L1$ = LTRIM$(RTRIM$(L1$))
                        L$ = UCASE$(L1$)
                        IF LEFT$(L$, 3) = "IF " AND RIGHT$(L$, 5) = " THEN" THEN
                            'new if level...
                            currentIfLevel = currentIfLevel + 1
                            _CONTINUE
                        END IF
                        IF L$ = "END IF" OR L$ = "ENDIF" THEN
                            currentIfLevel = currentIfLevel - 1
                            IF currentIfLevel = j - 1 THEN EXIT DO
                        END IF
                        IF LEFT$(L$, 7) = "ELSEIF " AND currentIfLevel = j THEN
                            IF RIGHT$(L$, 5) = " THEN" THEN
                                L$ = MID$(L$, 5)
                                L1$ = MID$(L1$, 5)
                                GOTO checkBlockCondition
                            ELSE
                                PRINT "Expected ELSEIF condition THEN on line"; currentLine: running = false: GOTO Parse.Done
                            END IF
                        END IF
                        IF L$ = "ELSE" AND currentIfLevel = j THEN EXIT DO
                        IF LEFT$(L$, 5) = "ELSE " AND currentIfLevel = j THEN
                            L$ = MID$(L$, 6)
                            L1$ = MID$(L1$, 6)
                            GOTO redoThisLine
                        END IF
                    LOOP
                END IF
            ELSE
                'single-line IF statement
                db_echo "Single-line IF, line" + STR$(currentLine)
                j = Find(1, L$, " THEN ")
                IF j = 0 THEN
                    PRINT "Expected IF condition THEN statements"
                    IF running THEN running = false
                    GOTO Parse.Done
                END IF

                i$ = MID$(LEFT$(L1$, j), 3)
                ifCond = evalNum(i$)
                IF errorHappened THEN GOTO Parse.Done
                IF ifCond <> 0 THEN
                    L$ = MID$(L$, j + 6)
                    L1$ = MID$(L1$, j + 6)
                    j = Find(1, L$, " ELSE ")
                    IF j = 0 THEN j = Find(1, L$, ":ELSE ")
                    IF j > 0 THEN
                        'remove ELSE part
                        L$ = LEFT$(L$, j - 1)
                        L1$ = LEFT$(L1$, j - 1)
                    END IF
                    GOTO redoThisLine
                ELSE
                    'look for ELSE
                    j = Find(j, L$, " ELSE ")
                    IF j = 0 THEN j = Find(1, L$, ":ELSE ")
                    IF j THEN
                        L$ = MID$(L$, j + 6)
                        L1$ = MID$(L1$, j + 6)
                        GOTO redoThisLine
                    END IF
                END IF
            END IF
        ELSEIF Find(1, L$, "=") > 0 THEN
            'Assignment
            IF LEFT$(L$, 4) = "LET " THEN L1$ = MID$(L1$, 5): L$ = MID$(L$, 5)
            j = Find(1, L1$, "=")
            varName$ = _TRIM$(LEFT$(L1$, j - 1))
            IF validName(varName$) = 0 THEN GOTO syntaxerror
            varIndex = addVar(varName$) 'either add or acquire existing index

            IF vars(varIndex).protected THEN
                PRINT "Variable is protected";
                IF running THEN
                    running = false
                    PRINT " on line "; currentLine
                ELSE
                    PRINT
                END IF

                GOTO Parse.Done
            END IF

            DIM asg AS valType
            evaluate MID$(L1$, j + 1), asg
            IF errorHappened THEN GOTO Parse.Done
            IF (vars(varIndex).type = varTypeSTRING) <> (asg.isText <> 0) THEN throwError 13: GOTO Parse.Done
            IF asg.isText THEN
                strings(varIndex) = asg.s
            ELSE
                nums(varIndex) = coerce(asg.n, vars(varIndex).type)
            END IF
        ELSE
            'label?
            L$ = L$ + " "
            IF LEN(L$) > 2 AND (RIGHT$(LEFT$(L$, INSTR(L$, " ") - 1), 1) = ":" OR isNumber(RTRIM$(L$))) THEN
                'it's a label
            ELSE
                syntaxerror:
                IF LEN(L$) THEN PRINT "Syntax error";
                IF running THEN
                    PRINT " on line"; currentLine
                    running = false
                ELSE
                    PRINT
                END IF
            END IF
        END IF
    END IF

    Parse.Done:
    IF runtimeErr THEN
        throwError runtimeErr
        runtimeErr = 0
    END IF
    IF errorHappened THEN Ucontinuation$ = "": continuation$ = ""
    IF LEN(Ucontinuation$) THEN
        L$ = Ucontinuation$: L1$ = continuation$
        stmtPos = continueAt
        GOTO redoThisLine
    END IF
    IF externalLimit > 0 AND running THEN _LIMIT externalLimit
    IF currentIfLevel < 0 THEN currentIfLevel = 0
LOOP

runtimeError:
'Errors raised by QB64 while running a statement (bad LOCATE arguments,
'missing files, ...). Remember the first one and let the statement finish;
'it's reported at Parse.Done and stops the program.
IF MyBad THEN RESUME NEXT
IF runtimeErr = 0 THEN runtimeErr = ERR
RESUME NEXT

FUNCTION addVar~& (varName$)
    DIM found AS LONG, h AS LONG

    'check if var exists
    found = searchVar(varName$)

    IF found THEN addVar~& = found: EXIT FUNCTION

    totalVars = totalVars + 1
    IF totalVars > UBOUND(vars) THEN
        REDIM _PRESERVE vars(totalVars + 99) AS vartype
        REDIM _PRESERVE strings(totalVars + 99) AS STRING
        REDIM _PRESERVE nums(totalVars + 99) AS _FLOAT
    END IF

    vars(totalVars).name = _TRIM$(varName$)
    vars(totalVars).key = LCASE$(vars(totalVars).name)
    vars(totalVars).type = detectType(varName$)
    vars(totalVars).scope = thisScope$
    vars(totalVars).protected = false
    strings(totalVars) = ""
    nums(totalVars) = 0

    h = hashKey(vars(totalVars).key)
    vars(totalVars).nextHash = varHash(h)
    varHash(h) = totalVars

    addVar~& = totalVars
END FUNCTION

FUNCTION hashKey& (k$)
    DIM i AS LONG, h AS LONG
    FOR i = 1 TO LEN(k$)
        h = (h * 31 + ASC(k$, i)) AND varHashSize
    NEXT
    hashKey& = h
END FUNCTION

SUB rebuildVarHash
    DIM i AS LONG, h AS LONG
    FOR i = 0 TO varHashSize: varHash(i) = 0: NEXT
    FOR i = 1 TO totalVars
        h = hashKey(vars(i).key)
        vars(i).nextHash = varHash(h)
        varHash(h) = i
    NEXT
END SUB

FUNCTION detectType%% (__varname$)
    DIM varname$

    varname$ = LTRIM$(RTRIM$(__varname$))

    detectType%% = varType_DEFAULT

    IF RIGHT$(varname$, 1) = "$" THEN detectType%% = varTypeSTRING

    IF RIGHT$(varname$, 3) = "~%%" THEN
        detectType%% = varType_UBYTE
    ELSEIF RIGHT$(varname$, 2) = "%%" THEN
        detectType%% = varType_BYTE
    ELSEIF RIGHT$(varname$, 2) = "~%" THEN
        detectType%% = varType_UINTEGER
    ELSEIF RIGHT$(varname$, 1) = "%" THEN
        detectType%% = varTypeINTEGER
    END IF

    IF RIGHT$(varname$, 1) = "!" THEN
        detectType%% = varTypeSINGLE
    ELSEIF RIGHT$(varname$, 2) = "##" THEN
        detectType%% = varType_FLOAT
    ELSEIF RIGHT$(varname$, 1) = "#" THEN
        detectType%% = varTypeDOUBLE
    END IF

    IF RIGHT$(varname$, 3) = "~&&" THEN
        detectType%% = varType_UINTEGER64
    ELSEIF RIGHT$(varname$, 2) = "&&" THEN
        detectType%% = varType_INTEGER64
    ELSEIF RIGHT$(varname$, 2) = "~&" THEN
        detectType%% = varType_ULONG
    ELSEIF RIGHT$(varname$, 1) = "&" THEN
        detectType%% = varTypeLONG
    END IF
END FUNCTION

FUNCTION searchVar~& (varName$)
    DIM i AS LONG, k$
    k$ = LCASE$(_TRIM$(varName$))
    i = varHash(hashKey(k$))
    DO WHILE i
        IF vars(i).key = k$ THEN searchVar~& = i: EXIT FUNCTION
        i = vars(i).nextHash
    LOOP
END FUNCTION

FUNCTION load%% (file$)
    DIM ff AS INTEGER, l$
    ff = FREEFILE
    OPEN file$ FOR BINARY AS ff

    currentLine = 0
    loadedFileContents$ = ""
    DO
        IF EOF(ff) THEN EXIT DO
        LINE INPUT #ff, l$
        currentLine = currentLine + 1
        IF currentLine > UBOUND(program) THEN REDIM _PRESERVE program(currentLine + 999) AS STRING
        program(currentLine) = l$
        IF LEN(loadedFileContents$) > 0 THEN loadedFileContents$ = loadedFileContents$ + CHR$(10)
        loadedFileContents$ = loadedFileContents$ + l$
    LOOP

    CLOSE ff

    IF currentLine > 0 THEN
        REDIM _PRESERVE program(currentLine) AS STRING
        currentLine = 0
        load%% = true
        loadedFile$ = file$
    ELSE
        load%% = false
    END IF
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

SUB db_echo (text$)
    IF debugging THEN _ECHO text$
END SUB

SUB throwError (code AS INTEGER)
    PRINT errorText$(code);
    IF running THEN
        PRINT " on line"; currentLine
        lineThatErrored = currentLine
        running = false
    ELSE
        PRINT
    END IF
    lastErrorCode = code
    errorHappened = true
END SUB

FUNCTION errorText$ (code AS INTEGER)
    SELECT CASE code
        CASE 2: errorText$ = "Syntax error"
        CASE 3: errorText$ = "RETURN without GOSUB"
        CASE 4: errorText$ = "Out of DATA"
        CASE 5: errorText$ = "Illegal function call"
        CASE 6: errorText$ = "Overflow"
        CASE 7: errorText$ = "Out of memory"
        CASE 9: errorText$ = "Subscript out of range"
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
        CASE ELSE: errorText$ = "Error #" + _TRIM$(STR$(code))
    END SELECT
END FUNCTION

FUNCTION Find& (start AS LONG, text$, subtext$)
    'like INSTR, but searches for subtext$ only outside quotation marks
    DIM i AS LONG, p AS LONG, quote AS _BYTE, lastQuote AS LONG

    p = start - 1
    DO
        p = INSTR(p + 1, text$, subtext$)
        IF p = 0 THEN EXIT FUNCTION

        quote = false
        IF lastQuote = 0 THEN lastQuote = 1
        FOR i = lastQuote TO p
            IF ASC(text$, i) = 34 THEN lastQuote = i: quote = NOT quote
        NEXT
    LOOP WHILE quote

    Find& = p
END FUNCTION

SUB doPrint (argText$)
    'PRINT list: items separated by ; (no gap) or , (next 14-column zone).
    'A trailing ; or , keeps the cursor on the same line.
    DIM i AS LONG, c AS INTEGER, depth AS LONG, quote AS _BYTE
    DIM start AS LONG, item$, lastSep$, v AS valType, col AS LONG, nxt AS LONG

    start = 1
    FOR i = 1 TO LEN(argText$) + 1
        IF i <= LEN(argText$) THEN c = ASC(argText$, i) ELSE c = 0
        IF c = 34 THEN quote = NOT quote
        IF NOT quote THEN
            IF c = 40 THEN depth = depth + 1
            IF c = 41 THEN depth = depth - 1
            IF c = 39 THEN c = 0: i = LEN(argText$) + 1 'comment
        END IF
        IF (quote = 0 AND depth = 0 AND (c = 59 OR c = 44)) OR c = 0 THEN
            item$ = _TRIM$(MID$(argText$, start, i - start))
            IF LEN(item$) THEN
                evaluate item$, v
                IF errorHappened THEN EXIT SUB
                IF v.isText THEN PRINT v.s; ELSE PRINT numStr$(v.n, v.t); " ";
                lastSep$ = ""
            END IF
            IF c = 59 THEN lastSep$ = ";"
            IF c = 44 THEN
                lastSep$ = ","
                col = POS(0)
                nxt = ((col - 1) \ 14 + 1) * 14 + 1
                IF nxt > _WIDTH THEN PRINT ELSE PRINT SPACE$(nxt - col);
            END IF
            start = i + 1
        END IF
    NEXT
    IF lastSep$ = "" THEN PRINT
END SUB

SUB doInput (argText$, lineMode AS _BYTE)
    'INPUT ["prompt"{;|,}] var[, var...]   /   LINE INPUT ["prompt";] var$
    DIM t$, prompt$, qmark AS _BYTE, k AS LONG, n AS LONG, i AS LONG
    DIM answer$, idx AS LONG, ok AS _BYTE, item$
    REDIM names$(0), values$(0)

    t$ = _TRIM$(argText$)
    IF LEFT$(t$, 1) = ";" THEN t$ = _TRIM$(MID$(t$, 2))
    qmark = NOT lineMode
    IF LEFT$(t$, 1) = CHR$(34) THEN
        k = INSTR(2, t$, CHR$(34))
        IF k = 0 THEN throwError 2: EXIT SUB
        prompt$ = MID$(t$, 2, k - 2)
        t$ = _TRIM$(MID$(t$, k + 1))
        IF LEFT$(t$, 1) = "," THEN
            qmark = false
        ELSEIF LEFT$(t$, 1) <> ";" THEN
            throwError 2: EXIT SUB
        END IF
        t$ = _TRIM$(MID$(t$, 2))
    END IF

    n = splitArgs(t$, names$())
    IF n = 0 OR (lineMode AND n > 1) THEN throwError 2: EXIT SUB
    FOR i = 1 TO n
        IF LEN(names$(i)) = 0 THEN throwError 2: EXIT SUB
    NEXT
    IF lineMode AND detectType(names$(1)) <> varTypeSTRING THEN throwError 13: EXIT SUB

    DO
        PRINT prompt$;
        IF qmark THEN PRINT "? ";
        LINE INPUT answer$
        IF lineMode THEN
            idx = addVar(names$(1))
            strings(idx) = answer$
            EXIT SUB
        END IF

        ok = (splitArgs(answer$, values$()) = n) OR (n = 1)
        IF n = 1 THEN values$(1) = _TRIM$(answer$)
        IF ok THEN
            FOR i = 1 TO n
                item$ = values$(i)
                IF detectType(names$(i)) <> varTypeSTRING THEN
                    IF LEN(item$) > 0 AND isNumber(item$) = 0 THEN ok = false: EXIT FOR
                END IF
            NEXT
        END IF
        IF ok THEN EXIT DO
        PRINT "Redo from start"
    LOOP

    FOR i = 1 TO n
        idx = addVar(names$(i))
        IF vars(idx).type = varTypeSTRING THEN
            strings(idx) = removeQuote$(values$(i))
        ELSE
            nums(idx) = coerce(VAL(values$(i)), vars(idx).type)
        END IF
    NEXT
END SUB

SUB doCircle (argText$)
    'CIRCLE [STEP](x, y), radius[, color[, start, end[, aspect]]]
    DIM t$, k AS LONG, depth AS LONG, stepMode AS _BYTE, rest$
    DIM x AS SINGLE, y AS SINGLE, r AS SINGLE, c AS _UNSIGNED LONG
    DIM arcS AS SINGLE, arcE AS SINGLE, asp AS SINGLE
    DIM hasArc AS _BYTE, hasAsp AS _BYTE, m AS LONG
    REDIM xy$(0), p$(0)

    IF _PIXELSIZE(_DEST) = 0 THEN throwError 5: EXIT SUB
    t$ = _TRIM$(argText$)
    IF UCASE$(LEFT$(t$, 4)) = "STEP" THEN stepMode = true: t$ = _TRIM$(MID$(t$, 5))
    IF LEFT$(t$, 1) <> "(" THEN throwError 2: EXIT SUB
    FOR k = 1 TO LEN(t$)
        IF ASC(t$, k) = 40 THEN depth = depth + 1
        IF ASC(t$, k) = 41 THEN depth = depth - 1: IF depth = 0 THEN EXIT FOR
    NEXT
    rest$ = _TRIM$(MID$(t$, k + 1))
    IF splitArgs(MID$(t$, 2, k - 2), xy$()) <> 2 OR LEFT$(rest$, 1) <> "," THEN throwError 2: EXIT SUB
    m = splitArgs(MID$(rest$, 2), p$())
    IF m < 1 OR m > 5 THEN throwError 2: EXIT SUB

    x = evalNum(xy$(1)): y = evalNum(xy$(2))
    r = evalNum(p$(1))
    c = _DEFAULTCOLOR
    IF m >= 2 THEN IF LEN(p$(2)) THEN c = evalNum(p$(2))
    arcS = 0: arcE = _PI(2)
    IF m >= 3 THEN IF LEN(p$(3)) THEN arcS = evalNum(p$(3)): hasArc = true
    IF m >= 4 THEN IF LEN(p$(4)) THEN arcE = evalNum(p$(4)): hasArc = true
    IF m >= 5 THEN IF LEN(p$(5)) THEN asp = evalNum(p$(5)): hasAsp = true
    IF errorHappened THEN EXIT SUB
    IF stepMode THEN x = x + POINT(2): y = y + POINT(3)

    IF hasArc AND hasAsp THEN
        CIRCLE (x, y), r, c, arcS, arcE, asp
    ELSEIF hasAsp THEN
        CIRCLE (x, y), r, c, , , asp
    ELSEIF hasArc THEN
        CIRCLE (x, y), r, c, arcS, arcE
    ELSE
        CIRCLE (x, y), r, c
    END IF
END SUB

FUNCTION validName%% (n$)
    'a plain variable name: letter, then letters/digits/_/., then a type suffix
    DIM i AS LONG, c AS INTEGER, body AS LONG
    IF LEN(n$) = 0 THEN EXIT FUNCTION
    c = ASC(UCASE$(n$), 1)
    IF (c < 65 OR c > 90) AND c <> 95 THEN EXIT FUNCTION
    body = LEN(n$)
    DO WHILE body > 0
        IF INSTR("$%&!#~`", MID$(n$, body, 1)) = 0 THEN EXIT DO
        body = body - 1
    LOOP
    IF body = 0 OR body > 40 THEN EXIT FUNCTION 'QB64 limits names to 40 characters
    FOR i = 1 TO body
        IF isIdentChar(ASC(n$, i)) = 0 THEN EXIT FUNCTION
    NEXT
    IF body < LEN(n$) THEN IF detectType(n$) = varType_DEFAULT AND RIGHT$(n$, 1) <> "!" THEN EXIT FUNCTION
    validName%% = true
END FUNCTION

FUNCTION splitStmts& (text$, st$())
    'splits a line into its statements (uppercased, trimmed). A single-line
    'IF keeps the rest of the line; a comment ends it.
    DIM i AS LONG, start AS LONG, quote AS _BYTE, n AS LONG, c AS INTEGER, s$, st0 AS LONG
    REDIM st$(1 TO 10)
    start = 1
    FOR i = 1 TO LEN(text$) + 1
        IF i <= LEN(text$) THEN c = ASC(text$, i) ELSE c = 58
        IF c = 34 THEN quote = NOT quote
        IF c = 58 AND quote = 0 THEN
            s$ = UCASE$(_TRIM$(MID$(text$, start, i - start)))
            st0 = start
            start = i + 1
            IF LEFT$(s$, 1) = "'" OR LEFT$(s$, 4) = "REM " OR s$ = "REM" THEN EXIT FOR
            IF LEN(s$) THEN
                n = n + 1
                IF n > UBOUND(st$) THEN REDIM _PRESERVE st$(1 TO n + 10)
                st$(n) = s$
                IF LEFT$(s$, 3) = "IF " AND RIGHT$(s$, 5) <> " THEN" THEN
                    st$(n) = UCASE$(_TRIM$(MID$(text$, st0)))
                    EXIT FOR
                END IF
            END IF
        END IF
    NEXT
    splitStmts& = n
END FUNCTION

FUNCTION findBlockEnd& (rest$, fromLine AS LONG, kind AS INTEGER)
    'Finds the line that closes the block we're in, honoring nesting.
    'kind: 1 = DO/LOOP, 2 = FOR/NEXT, 3 = IF/END IF.
    'rest$ is what follows the current statement on fromLine.
    DIM ln AS LONG, n AS LONG, i AS LONG, depth AS LONG, s$, text$, closes AS LONG, k AS LONG
    REDIM st$(0)
    FOR ln = fromLine TO UBOUND(program)
        IF ln = fromLine THEN text$ = rest$ ELSE text$ = program(ln)
        n = splitStmts(text$, st$())
        FOR i = 1 TO n
            s$ = st$(i)
            closes = 0
            SELECT CASE kind
                CASE 1
                    IF s$ = "DO" OR LEFT$(s$, 3) = "DO " THEN depth = depth + 1
                    IF s$ = "LOOP" OR LEFT$(s$, 5) = "LOOP " THEN closes = 1
                CASE 2
                    IF LEFT$(s$, 4) = "FOR " THEN depth = depth + 1
                    IF s$ = "NEXT" THEN closes = 1
                    IF LEFT$(s$, 5) = "NEXT " THEN
                        closes = 1 'NEXT i, j closes two loops
                        FOR k = 1 TO LEN(s$)
                            IF ASC(s$, k) = 44 THEN closes = closes + 1
                        NEXT
                    END IF
                CASE 3
                    IF LEFT$(s$, 3) = "IF " AND RIGHT$(s$, 5) = " THEN" THEN depth = depth + 1
                    IF s$ = "END IF" OR s$ = "ENDIF" THEN closes = 1
            END SELECT
            IF closes THEN
                IF depth < closes THEN findBlockEnd& = ln: EXIT FUNCTION
                depth = depth - closes
            END IF
        NEXT
    NEXT
END FUNCTION

SUB clearVars
    'removes user variables; built-in function names (protected) stay
    DIM i AS LONG
    FOR i = totalVars TO 1 STEP -1
        IF NOT vars(i).protected THEN
            totalVars = totalVars - 1
            vars(i).name = ""
            vars(i).key = ""
            vars(i).type = 0
            strings(i) = ""
            nums(i) = 0
        END IF
    NEXT
    rebuildVarHash
END SUB

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

'$include:'eval.bm'
'$include:'qXed/qXed.bm'
