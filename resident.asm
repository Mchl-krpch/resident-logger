;-------------------------------------------------------------------------------
;       Date: Feb 2022           
;       File: resident.asm
;
; 		Resident program for capturing register value changesalso implemented a function 
;   that captures pressing
;
; 		Purpose:
; - To unleash the potential of commands that replace several 
;   operations with registers (thereby hanging up the readability of the code)
;
; 		Ideas:  [.cdecl, pascal]:conventions
; - Implement parameter passing according to different conventions
;   in the language,
;   interrupts.
;
;   @Michael-krpch
;-------------------------------------------------------------------------------
	locals                  ; Use of local labels in the program
	.186                    ; Specialization of the program to work with the processor 186
;-------------------------------------------------------------------------------

	.model tiny             ; using memory model for small programs

;-------------------------------------------------------------------------------
		.code   ; The library uses wrappers
	 EXIT_CODE = 04C00h
	 PAUSE_VAL = 00000h
	 VIDEO_PTR = 0B800h
	 RADIX_SYS = 2
	 RADIX_DEG = 4
		org 100h
;-------------------------------------------------------------------------------

start:
	MOV   BX,offset colors
	PUSH  BX
	MOV   BX,offset win_props
	PUSH  BX
	PUSH  [BX]
	PUSH  [BX + 2]
	PUSH  [BX + 4]
	CALL  setVideo
	CALL  drow_window           ;
	CALL  exit_program

drow_window proc                    ; [Pascal] style
	PUSH  BX
	MOV   BP,SP
	MOV   AX,[BP + 6]
	MOV   DX,160
	MUL   DX
	MOV   DI,AX
	CALL  drow_upper_line
	MOV   CX,1

@@print_string:
	MOV   AX,[BP + 6]
	ADD   AX,CX
	MOV   DX,160
	MUL   DX
	MOV   DI,AX
	CALL  drow_win_line

	ADD   CX,1
	PUSH  BX
	MOV   BX,offset win_props
	MOV   DX,[BX + 6d]
	ADD   DX,1
	POP   BX
	CMP   CX,DX
	JB @@print_string

	MOV   AX,[BP + 6]
	ADD   AX,CX
	MOV   DX,160
	MUL   DX
	MOV   DI,AX
	CALL  drow_down_line

	POP   BX
	RET   4
	ENDP

drow_upper_line proc                ; [Pascal] style
	PUSH  CX
	PUSH  AX
	PUSH  DX
	MOV   BX,[BP + 12]
	MOV   DX,[BP + 8]
	MOV   CX,[BP + 4]
	; #---------------------------------------------
	ADD   DI,DX
	MOV   AX,[BX + 8]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
@@fill_line:
	MOV   AX,[BX + 4]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	loop  @@fill_line
	MOV   AX,[BX + 10]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	; #---------------------------------------------
	POP  DX
	POP  AX
	POP  CX
	RET
	ENDP

drow_win_line proc                ; [Pascal] style
	PUSH  CX
	PUSH  AX
	PUSH  DX
	MOV   BX,[BP + 12]
	MOV   DX,[BP + 8]
	MOV   CX,[BP + 4]
	; #---------------------------------------------
	ADD   DI,DX
	MOV   AX,[BX + 6]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
@@fill_line:
	MOV   AX,[BX + 2]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	loop  @@fill_line
	MOV   AX,[BX + 6]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	; #---------------------------------------------
	POP  DX
	POP  AX
	POP  CX
	RET
	ENDP

drow_down_line proc                ; [Pascal] style
	PUSH  CX
	PUSH  AX
	PUSH  DX
	MOV   BX,[BP + 12]
	MOV   DX,[BP + 8]
	MOV   CX,[BP + 4]
	; #---------------------------------------------
	ADD   DI,DX
	MOV   AX,[BX + 14]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
@@fill_line:
	MOV   AX,[BX + 4]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	loop  @@fill_line
	MOV   AX,[BX + 12]           ; Copy si-symbol to AL
	MOV   es:[di],AX            ; Puts it on the screen
	ADD   DI,2
	; #---------------------------------------------
	POP  DX
	POP  AX
	POP  CX
	RET
	ENDP

setVideo proc                       ; [ safe ] style
	PUSH  AX
	MOV   AX,VIDEO_PTR
	MOV   es,AX
	POP   AX
	RET
	ENDP

	; #end of the program (by 21st interrupt)
exit_program proc                   ; #programm finalist.
	XOR   AX,AX
	MOV   AX,EXIT_CODE              ; (uses interrupt 21) = 04C00H
	INT   21h                       ; interrupt
	RET
	ENDP

win_props:; #attributes of screen
	DW    00070h	; #09 skip of left pixels	[+ 0d]
	DW    00002h	; #10 skip top pixels 		[+ 2d]
	DW    00010h	; #11 width                     [+ 4d]
	DW    00003h	; #12 height                    [+ 6d] 
	DW    00000h    ; #13 animation frame           [+ 8d]
	DW    00000h	; #14 current pos in line       [+10d]
	DW    00000h 	; #15 current line in frame     [+12d]
	DW    00000h	; #16 current config

colors:; #colors config №1
	DW    00000h 	; #01 black background		[+ 0d] # BRUSHES
	DW    01f00h 	; #02 window background		[+ 2d]
	DW    01fcdh 	; #03 horisontAL border		[+ 4d]
	DW    01fbah 	; #04 verticAL border		[+ 6d]
	DW    01Fc9h 	; #05 left upper corner		[+ 8d] # CORNERS
	DW    01fbbh 	; #06 right upper corner	[+10d]
	DW    01fbch 	; #07 right down corner		[+12d]
	DW    01fc8h 	; #08 left down corner		[+14d]

end start