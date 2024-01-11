; IMPORT TIMER.ASM

;EQU CONSTANTS' KEY
;  PREFIX:
;    R     IN/OUT REGESTER
;    I     IN ONLY REGESTER
;    O     OUT ONLY REGESTER
;    C     COMMAND FOR OTHER PROC
;    M     BIT MASK
;    A     BITWISE NOT MASK
;    E     OTHER EQU BASED CONSTANT
;    NONE  IDK, LITERALLY ANYTHING IG

;SHARED REGISTERS AND STUFF
O$SHARED$CONTROL	EQU	0F0H
I$SHARED$STATUS$1	EQU	0E0H
I$SHARED$STATUS$2	EQU	0D0H

C$START$MOTORS		EQU	0$0000$0101B
C$SHOW$SECTOR		EQU	0$0000$0000B
M$MOTOR$STATUS		EQU	0$0000$1111B
A$MOTOR$STATUS		EQU	0FFH-M$MOTOR$STATUS
E$MOTOR$OFF		EQU	0$0000$1110B

M$TRACK$ZERO		EQU	0$0010$0000B
A$TRACK$ZERO		EQU	0FFH-M$TRACK$ZERO
E$TRACK$ZERO$FALSE	EQU	0$0000$0000B
E$TRACK$ZERO$TRUE	EQU	0$0010$0000B

M$AQUIRE$MODE		EQU	0$0000$1000B
A$AQUIRE$MODE		EQU	0FFH-M$AQUIRE$MODE

M$COMMAND$ACK		EQU	0$1000$0000B
A$COMMAND$ACK		EQU	0FFH-M$COMMAND$ACK
E$COMMAND$ACK$FALSE	EQU	0$0000$0000B
E$COMMAND$ACK$TRUE	EQU	0$1000$0000B

M$SECTOR$MARK		EQU	0$0100$0000B
A$SECTOR$MARK		EQU	0FFH-M$SECTOR$MARK

M$SECTOR$NUMBER		EQU	0$0000$1111B
A$SECTOR$NUMBER		EQU	0FFH-M$SECTOR$NUMBER



;DRIVE REGISTERS
R$DISK$DATA		EQU	080H
I$SYNC$BYTE		EQU	081H
O$DRIVE$CONTROL		EQU	081H
I$F$READ$CLEAR		EQU	082H
O$F$READ		EQU	082H
R$F$WRITE		EQU	082H

;DRIVE CONTROL STUFF
M$DISK$DRIVE		EQU	0$0000$0011B
A$DISK$DRIVE		EQU	0FFH-M$DISK$DRIVE
E$DISK$DRIVE$1		EQU	0$0000$0001B
E$DISK$DRIVE$2		EQU	0$0000$0010B

M$DISK$SIDE		EQU	0$0100$0000B
A$DISK$SIDE		EQU	0FFH-M$DISK$SIDE
E$DISK$SIDE$0		EQU	0$0000$0000B
E$DISK$SIDE$1		EQU	0$0100$0000B

M$STEP$DIRECTION	EQU	0$0010$0000B
A$STEP$DIRECTION	EQU	0FFH-M$STEP$DIRECTION
E$STEP$DIRECTION$OUTER	EQU	0$0000$0000B
E$STEP$DIRECTION$INNER	EQU	0$0010$0000B

M$STEP$PULSE		EQU	0$0001$0000B
A$STEP$PULSE		EQU	0FFH-M$STEP$PULSE
E$STEP$PULSE$OFF	EQU	0$0000$0000B
E$STEP$PULSE$ON		EQU	0$0001$0000B

M$SECTOR$PRECOMP	EQU	0$0010$0000B
A$SECTOR$PRECOMP	EQU	0FFH-M$SECTOR$PRECOMP
E$SECTOR$PRECOMP$OFF	EQU	0$0000$0000B
E$SECTOR$PRECOMP$ON	EQU	0$0010$0000B


;DATA
;SHOULD BE MOVED TO DATA SECTION BUT FOR NOW ITS EASIER HERE
DISK$DRIVE_CONTROL:	DS	1
DISK$TRACK:		DS	1
DISK$SECTOR:		DS	1
DISK$DATA_ADDR:		DS	2
DISK$BLOCKS:		DS	2

RAW$WRITE:
	;FOLLOWING THE PROCEDURE OUTLINE IN SECTION 3.7

	;REG ACC = DRIVE CONTROL VALUE
	;REG B   = TRACK
	;REG C   = SECTOR
	;REG DE  = IN BLOCKS, SIZE OF DATA TO WRITE (512 BYTES)
	;REG HL  = ADDR OF DATA

	;SAVE PARAMETERS TO GLOBAL VARIABLES
					;STORE THE DATA_ADDRESS	
	SHLD	DISK$DATA_ADDR		;STORE HL INTO VARIABLE

					;STORE THE DATA SIZE
	XCHG				;MOVE VALUE INTO HL
	SHLD	DISK$BLOCKS		;STORE HL IN VARIABLE

	; CODE
	CALL	DISK$INIT

	;CHECK WRITE PROTECT BIT
	IN	I$SHARED$STATUS$1	;GET WRITE PROTECT STATUS
	ANI	M$WRITE$PROTECT		;EXTRACT JUST THE IMPORTANT DATA
	CPI	M$WRITE$PROTECT$ON	;CHECK IF WRITE PROTECT IS ON
	JZ	RAW$WRITE$EXIT		;IF IT IS WE CANT WRITE, SO EXIT

	;IF WRITING TO INNER TRACK SET PRECOMP
	
	

	;SET THE DIRSK WRITE FLAG
	;OUTPUT PREAMBLE
	;OUTPUT SYNC BYTES
	;OUTPUT 512 DATA BYTES
	;OUTPUT CRC BYTE

RAW$WRITE$EXIT
	CALL	DISK$DONE

	RET





DISK$INIT:
	;FOLLOWING THE PROCEDURE OUTLINE IN SECTION 3.7

	;REG ACC = DRIVE CONTROL VALUE
	;REG B   = TRACK
	;REG C   = SECTOR

	; SAVE PARAMETERS TO GLOBAL VARIABLES
					;STORE THE DRIVE CONTROL VALUE
	LXI	H,DINIT$DRIVE_CONTROL	;LOAD VARIABLE ADDRESS
	MOV	M,A			;STORE THE VALUE INTO THE VARIABLE

					;STORE THE TRACK
	LXI	H,DINIT$TRACK		;LOAD VARIABLE ADDRESS
	MOV	M,B			;STORE THE VALUE INTO THE VARIABLE

					;STORE THE SECTOR
	LXI	H,DINIT$SECTOR		;LOAD VARIABLE ADDRESS
	MOV	M,C			;STORE THE VALUE INTO THE VARIABLE

	
	;START PREPARING TO WRITE TO THE DISK
	CALL	POWERON$INIT		;INITIALIZE POWER-ON SEQ. FOR DRIVES
	CALL	MOTOR$START		;START THE MOTOR

	LDA	DINIT$DRIVE_CONTROL	;LOAD THE DRIVE_CONTROL VALUE
	OUT	O$DRIVE$CONTROL		;OUTPUT TO THE DRIVE CONTROL REG

	LXI	H,DINIT$DRIVE_CONTROL	;HL = DRIVE_CONTROL VAR ADDR
	MOV	B,M			;LOAD THE VARIABLE'S VALUE INTO B
	LXI	H,DINIT$TRACK		;HL = TRACK VAR ADDR
	MOV	C,M			;LOAD THE VARIABLE'S VALUE INTO C
	CALL	SEEK			;SEEK TO THE GIVEN TRACK

	LDA	DINIT$SECTOR		;LOAD THE SECTOR WE WANT
	CALL	SECTOR$SELECT		;MOVE TO THAT SECTOR

	RET


DISK$DONE:
	CALL	MOTOR$STOP		;STOP THE MOTOR

	RET



SET$READ$FLAG:
	; TABLE 3-15 SET THE READ FLAG
	OUT	O$F$READ
	RET

CLEAR$READ$FLAG:
	; TABLE 3-15 CLEAR THE READ FLAG
	IN	I$F$READ$CLEAR
	RET

POWERON$INIT:
	; 3.7.1 POWER-ON INITIALIZATION	

	;SETUP PARAMETERS FOR WAIT/SLEEP CALLS
	MVI	C,100			;SPECIFY 100 ITERATIONS
	MVI	B,SLEEPMILI		;OF 1 MILLISECOND WAITS

	;CYCLE THE READ FLAG
	CALL	POWERON$CYCLE$FIRST	;CYCLE #1 (NO BEGINNING WAIT)
	CALL	POWERON$CYCLE		;CYCLE #2
	CALL	POWERON$CYCLE		;CYCLE #3
	CALL	POWERON$CYCLE		;CYCLE #4
	CALL	POWERON$CYCLE		;CYCLE #5
	RET
POWERON$CYCLE:
	CALL	SLEEP			;WAIT 100 MILLISECONDS
	;FALL-THROUGH
POWERON$CYCLE$FIRST:			;DONT WAIT ON FIRST CALL
	CALL	SET$READ$FLAG		;SET THE READ FLAG
	CALL	SLEEP			;WAIT 100 MILLISECONDS
	CALL	CLEAR$READ$FLAG		;CLEAR THE READ FLAG
	RET

MOTOR$START:
	; 3.7.2 MOTOR ENABLE

	;START BOTH DISK DRIVE MOTORS
	;STOP THE MOTORS USING THE MOTOR$STOP PROCEDURE

	MVI	A,C$START$MOTORS	;START DISK DRIVE MOTOR COMMAND NUMBER
	OUT	O$SHARED$CONTROL	;START THE MOTORS

	RET

MOTOR$STOP:
	; 3.7.2 MOTOR ENABLE

	;STOP THE DISK DRIVE MOTORS AND WAIT FOR THEM TO STOP.

	MVI	A,C$SHOW$SECTOR		;SHOW SECTOR COMMAND NUMBER
	OUT	O$SHARED$CONTROL	;OVERWRITE THE START DRIVE MOTOR CMD
					;INSTEAD, GET THE SECTOR NUMBER
					;IF THE SECTOR # IS SECTOR$MOTOROFF
					;THEN THE MOTORS HAVE STOPPED.

	IN	I$SHARED$STATUS$2	;READ THE OUTPUT OF SHOW$SECTOR
	ANI	E$MOTOR$STATUS		;USE A BITMASK TO REMOVE TRASH DATA
	CPI	E$MOTOR$OFF		;CHECK THE MOTOR IS OFF
	JNZ	MOTOR$STOP		;IF IT ISN'T CHECK AGIN UNTIL IT IS

	;WAIT 100 MICROSECONDS TO ALLOW THE DRIVES TO FINISH ALL READ/WRITES
	MVI	C,2			;2 ITERATIONS
	MVI	B,SLEEPMICRO		;OF 50 MICROSECOND WAITS
	CALL	SLEEP			;SLEEP FOR (2*50) 100 MICROSECONDS

	RET


;DATA
SEEK$DRIVE_CONTROL:	DS	1
SEEK$TRACK:		DS	1

SEEK:
	; 3.7.4 SEEK

	;REG B = DRIVE CONTROL REG VALUE
	;REG C = TRACK NUMBER

	;STORE PARAMETERS
	LXI	H,SEEK$DRIVE_CONTROL	;HL = VARIABLE ADDRESS
	MOV	M,B			;STORE THE VALUE IN IT

	LXI	H,SEEK$TRACK		;HL = VARIABLE ADDRESS
	MOV	M,C			;STORE THE VALUE IN IT

	;CODE STUFF
	LDA	SEEK$DRIVE_CONTROL	;LOAD VALUE OF DRIVE_CONTROL
	CALL	HEAD$INIT		;MOVE HEAD TO TRACK 0

	LDA	SEEK$DRIVE_CONTROL	;LOAD VALUE OF DRIVE_CONTROL
	LXI	H,SEEK$TRACK		;HL = SEEK$TRACK ADDR
	MOV	B,M			;LOAD VALUE OF SEEK$TRACK INTO REG B
	CALL	TRACK$MOVE		;MOVE N TRACKS

					;LET THE HEADS SETTLE
	MVI	C,20			;SLEEP 20 ITERATIONS
	MVI	B,SLEEPMILLI		;OF 1 MILLISECOND
	CALL	SLEEP			;SLEEP NOW

	RET


HEAD$INIT:
	;MOVE TO TRACK 0

	;REG ACC = DRIVE_CONTROL VALUE

	;VARIABLES
	ANI	A$STEP$DIRECTION	;CLEAR THE STEP DIRECTION BIT
	ORI	E$STEP$DIRECTION$OUTER	;SET THE DIRECTION TO OUTER

	ANI	A$STEP$PULSE		;CLEAR THE STEP PULSE BIT
	ORI	E$STEP$PULSE$ON		;SET THE PUSLE BIT TO 1
	MOV	B,A			;STORE THE ON_PULSE TO REG B

	ANI	A$STEP$PULSE		;CLEAR THE STEP PULSE BIT
	ORI	E$STEP$PULSE$OFF	;SET THE PULSE BIT TO 0
	MOV	C,A			;STORE THE OFF_PULSE TO REG C

	;CODE
	;FALL-THROUGH
HEAD$INIT$LOOP:
	IN	I$SHARED$STATUS$1	;CHECK IF WE ARE AT TRACK 0
	ANI	M$TRACK$ZERO		;ISOLATE THE NEEDED FLAG (BIT)
	CPI	E$TRACK$ZERO$TRUE	;CHECK IF IT IS ON/OFF
	RZ				;IF WE ARE AT TRACK 0, RETURN

	PUSH	B 
	CALL	CYCLE$PULSE		;SEND A STEP PULSE
	POP	B
	
	JMP	HEAD$INIT$LOOP		;LOOP UNTIL WE ARE AT TRACK 0


CYCLE$PULSE:
	;REG B = ON PULSE
	;REG C = OFF PULSE

	MOV	A,B			;PREPARE THE PULSE_ON VALUE
	OUT	O$DRIVE$CONTROL		;OUTPUT IT TO DRIVE CONTORL

	MOV	A,C			;PREPARE THE PULSE_OFF VALUE
	OUT	O$DRIVE$CONTROL		;OUTPUT IT TO DRIVE CONTORL

	MVI	C,5			;SPECIFY 5 ITERATION
	MVI	B,SLEEPMILLI		;OF 1 MILLISECOND WAITS
	CALL	SLEEP			;SLEEP FOR 5 MILLISECONDS

	RET


;DATA
TRACK$I		DS	1

TRACK$MOVE:
	;REG ACC = DRIVE_CONTROL
	;REG B = TRACK
	
	;PARAMETERS
	LXI	H,TRACK$I		;LOAD VARIABLE ADDR
	MOV	M,B			;STORE THE PARAM IN TRACK$I

	;VARIABLES
	ANI	A$STEP$DIRECTION	;CLEAR THE STEP DIRECTION BIT
	ORI	E$STEP$DIRECTION$INNER	;SET THE DIRECTION TO INNER 

	ANI	A$STEP$PULSE		;CLEAR THE STEP PULSE BIT
	ORI	E$STEP$PULSE$ON		;SET THE PUSLE BIT TO 1
	MOV	B,A			;STORE THE ON_PULSE TO REG B

	ANI	A$STEP$PULSE		;CLEAR THE STEP PULSE BIT
	ORI	E$STEP$PULSE$OFF	;SET THE PULSE BIT TO 0
	MOV	C,A			;STORE THE OFF_PULSE TO REG C

	;CODE
	;FALL-THROUGH
TRACK$LOOP:
	LXI	H,TRACK$I		;LOAD VARIABLE ADDRESS
	MOV	A,M			;LOAD VARIABLE VALUE INTO ACC
	CPI	0			;CHECK IF THE VALUE IS 0
	RZ				;IF IT IS, RETURN
	DCR	A			;OTHERWISE, DECREMENT THE VALUE
	MOV	M,A			;AND STORE IT BACK IN THE VARIABLE

	PUSH	B			;STORE THE PULSE VALUES ON THE STACK
	CALL	CYCLE$PULSE		;STEP 1 TRACK INWARD
	POP	B			;RESTORE THE PULSE VALUES TO BC

	JMP	TRACK$LOOP		;THEN LOOP BACK UNTIL WE REACH 0


SECTOR$SELECT:
	;REG ACC = SECTOR TO ACCESS
	;NOTE: IF SECTOR IS INVALID, IT WILL HANG FOREVER

	DCR	A			;SEARCH FOR THE SECTOR *BEFORE*
	ANI	M$SECTOR$NUMBER		;REMOVE UPPER 4 BITS
	MOV	A,C			;STORE IN REG C

	IN	I$SHARED$STATUS$2	;GET THE COMMAND ACKNOWLEDGEMENT
	ANI	M$COMMAND$ACK		;EXTRACT THE CMD ACKNOWLEDGEMEN BIT
	XRI	M$COMMAND$ACK$TRUE	;COMPLIMENT THE BIT
	MOV	B,A			;STORE THE COPLIMENTED BIT IN REG B

	MVI	A,C$START$MOTORS	;MAKE SURE THE MOTORS ARE RUNNING
	OUT	O$SHARED$CONTROL	;SENT THE COMMAND TO SHARED CONTROL

	;FALL-THROUGH
WAITFOR$CMD$ACK:
	IN	I$SHARED$STATUS$2	;GET THE COMMAND ACKNOWLEDGEMENT
	ANI	M$COMMAND$ACK		;EXTRACT THE CMD ACKNOWLEDGEMEN BIT

	CMP	B			;CHECK IF THE BIT HAS COMPLIMENTED
	JNZ	WATIFOR$CMD$ACK		;IF NOT, LOOP. OTHERWISE CONTINUE

	;FALL-THROUGH
WAITFOR$SECTOR$MARK:
	IN	I$SHARED$STATUS$1	;GET THE SECTOR MARK 
	ANI	M$SECTOR$MARK		;EXTRACT THE SECTOR MARK BIT
	
	CPI	0			;CHECK IF THE BIT IS SET TO 0
	JNZ	WAITFOR$SECTOR$MARK	;LOOP UNTIL IT IS SET TO 0

	IN	I$SHARED$STATUS$2	;GET THE SECTOR NUMBER
	ANI	M$SECTOR$NUMBER		;REMOVE THE UPPER 4 BITS

	CMP	C			;CHECK IF WE ARE AT THE SECTOR NEEDED
	RZ				;RETURN, SECTOR IS VALID FOR 50 US

	JMP	WAITFOR$SECTOR$MARK	;LOOP UNTIL A MATCH IS FOUND



