;-------------------------------------------------------------------------------
  ; Ret: Nothing
  ; Incoming: al - end-of-line char, {bx} - string ptr, si - counter di - pos on screen
  ; destroy:  {di, si}
;-------------------------------------------------------------------------------
print PROC
	CALL  _print
	RET
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

;-------------------------------------------------------------------------------
  ; Ret DI-resulting string  
  ; Incoming: ax-number to translate, dx-base of system, bx-ptr to string to fill
;-------------------------------------------------------------------------------
itoa_16 proc
	PUSH  SI AX CX
	MOV   SI,3
	MOV   CX,16
@@again:
	PUSH  DI
	XOR   DI,DI
@@delenie:
	CMP   AX,CX
	JB  @@end_del
	SUB   AX,CX
	ADD   DI,1
	JMP @@delenie
@@end_del:
	MOV   DX,AX
	MOV   AX,DI
	POP   DI
	CMP   DX,10
	JB  @@below_ten
	JAE @@aboth_ten
@@below_ten:
	ADD   DL,'0'                ; Add zero ascii-code
	JMP @@add_to_string
@@aboth_ten:
	ADD   DL,'8'                ; Add zero ascii-code
	JMP @@add_to_string
@@add_to_string:
	MOV   [BX + SI],DL
	DEC   SI
	CMP   SI,0
	JE @@out
	JMP @@again
@@out:
	MOV   [BX],DL
	POP   CX AX SI
	RET
	ENDP