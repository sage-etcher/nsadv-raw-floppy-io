
;
; https://github.com/sage-etcher/i8080timer.git
;

;
;  Copyright 2024 Sage I. Hendricks  
;
;  Licensed under the Apache License, Version 2.0 (the "License");  
;  you may not use this file except in compliance with the License.  
;  You may obtain a copy of the License at  
;
;      http://www.apache.org/licenses/LICENSE-2.0
;
;  Unless required by applicable law or agreed to in writing, software  
;  distributed under the License is distributed on an "AS IS" BASIS,  
;  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
;  See the License for the specific language governing permissions and  
;  limitations under the License.  
; 


;PROCEDURES ASSUME THE SYSTEM IS RUNNING A 4MHZ Z80A CPU

;MAGIC NUMBERS FOR SLEEP BASES
;MAGIC NUMBER EQUATION: (DESIRED_CYCLES - 100) / 50
SLEEPMILLI	EQU	78	; 1 MILLISECOND PER ITERATION
SLEEPMICRO	EQU	2	; 50 MICROSECONDS PER ITERATION

;GIVEN A BASE VALUE AND # OF ITERATOINS, SLEEP FOR A GIVEN TIME
;ALWAYS TAKES 22 CYCLES (5.5 MICRO SECONDS) LONGER THAN GIVEN VALUE
;ABOVE IS *NOT* ACOUNTING FOR CALL OR MVIS TO ENTER THE PROCEDURE
SLEEP:
	;REG B = MAGIC NUMBER VALUE FOR 1 ITERATION (CONSTANT)
	;REG C = NUMBER OF ITERATIONS

	;INIT TAKES 7 CYCLES
	;LOOP ITERATION TAKES 51+SLEEP$STEP
	;LAST LOOP ITERATION TAKES 15

	MVI	A,0		;INITIALZE THE ITERATOR TO 0

	;FALL-THROUGH
SLEEP$LOOP:
	CMP	C		;CHECK IF THE TWO VALUES ARE EQUAL
	RZ			;IF THEY ARE, STOP SLEEPING

				;DONT PUSH/POP, MEMORY SPEED IS UNRELIABLE
				;AND TIMINGS ARE VVV SENSITIVE
	MOV	E,A		;STORE ITERATOR VALUE IN REG E TEMPORARILY

	CALL	SLEEP$STEP	;SLEEP FOR JUST UNDER THE GIVEN BASE

	MOV	A,E		;RESTORE ITERATOR TO REG ACC

	INR	A		;INCREMENT TO NEXT VALUE
	JMP	SLEEP$LOOP	;LOOP BACK FOR NEXT SLEEP$STEP
;HELPER PROCEDURE FOR SLEEP 
SLEEP$STEP:
	;REG B = NUMBER OF ITERATION

	;INIT TAKES 34 CYCLES
	;LOOP ITERATION TAKES 50 
	;LAST LOOP ITERATION TAKES 15

	MVI	A,0		;USE REG ACC AS AN ITERATOR

	;TRASH NOP INSTRUCTIONS FOR TIMING (27 CYCLES)
	MOV	A,A		;5
	MOV	A,A		;5
	MOV	A,A		;5
	NOP			;4
	NOP			;4
	NOP			;4

	;FALL-THROUGH
SLEEP$STEP$LOOP:
	CMP	B		;CHECK REG ACC AND REG B
	RZ			;IF THE TWO ARE EQUAL, STOP LOOPING

	;TRASH NOP INSTRUCTIONS FOR TIMING (26 CYCLES)
	MOV	A,A		;5
	MOV	A,A		;5
	NOP			;4
	NOP			;4
	NOP			;4
	NOP			;4

	INR	A		;MOVE A TO NEXT VALUE
	JMP	SLEEP$STEP$LOOP	;AND LOOP BACK TO THE TOP
	
