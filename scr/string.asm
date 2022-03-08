;-------------------------------------------------------------------------------
	; Ret: Nothing
	; Incoming: al - end-of-line char, {bx} - string ptr, si - counter di - pos on screen
	; destroy:  {di, si}
;-------------------------------------------------------------------------------
print PROC
	MOV   BP,SP
	CALL  _print
	RET   4
	ENDP
_print PROC
@@repeat:
	movsb
	INC   DI
	MOV   AL,DS:[SI]
	CMP   AL,0
	JNE  @@repeat
	RET
	ENDP

	;#.The main functions of the library (7 functions)
;-------------------------------------------------------------------------------
; Ret DI-resulting string  
; Incoming: ax-number to translate, dx-base of system, bx-ptr to string to fill
;-------------------------------------------------------------------------------

itoa proc
	PUSH  SI
	XOR   SI,SI                 ; Clear si counter
	PUSH  DX                    ; Push regs
	XOR   DX,DX
	CALL  _itoa                 ; Call executor
	POP   DX
	POP   SI
	RET
	ENDP
_itoa proc
	MOV   BP,SP                 ; Mov stack pointer
	MOV   CX,[BP + 2D]          ; Pull radix
@@decrease_by_order:            ; Start diving
	DIV   CX                    ; Div ax-number by radix
	CMP   DL,10
	JB  @@below_ten
	JAE @@aboth_ten
@@below_ten:
	ADD   DL,'0'                ; Add zero ascii-code
	JMP @@add_to_string
@@aboth_ten:
	ADD   DL,'8'                ; Add zero ascii-code
	JMP @@add_to_string
@@add_to_string:
	MOV   [BX + SI],DL          ; Set digit in number, (we have inversed number buffer)
	INC   SI                    ; ^-- (num: ax = 123 => buf:[321]) #we need reverse-func
	XOR   DX,DX                 ; Clear mod
	CMP   AX,0D                 ; If we have zero, number is translated to string
	JNE   @@decrease_by_order   ; Set next digit in string
	PUSH  DI
	MOV   CX,SI                 ; Set string len
	SHR   CX,1D                 ; Repeat reversing of digits (len-of-num / 2D)
	XOR   DI,DI
	DEC   SI                    ; Offset in buffer is less by 1D
@@reverse_string:
	MOV   AH,[BX + SI]          ; | Changing of numbers
	MOV   AL,[BX + DI]          ; |
	MOV   [BX + SI],AL          ; |
	MOV   [BX + DI],AH          ; |
	DEC   SI
	INC   DI
	loop  @@reverse_string      ; Continue changing of numbers (len-of-num / 2D).times
	POP   DI
	RET
	ENDP
