'exec.bi - program runner state (see exec.bm)

DIM SHARED pcCur AS LONG, pcNext AS LONG 'statement running, statement to run next
DIM SHARED exitProcFlag AS _BYTE, callDepth AS LONG
DIM SHARED immediateRun AS _BYTE 'running a line typed at the prompt
REDIM SHARED gosubStack(100) AS LONG, gosubDepth(100) AS LONG
DIM SHARED gosubTop AS LONG
