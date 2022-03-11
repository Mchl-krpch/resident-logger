	  locals            ; using locals in program
	  .186              ; use 186-processor commands
;--------------------------------------------------------------------------------------------------------
	.model tiny
	  .code
	  org 100h

start:
	MOV   AX,0b800h
	MOV   ES,AX
	MOV   ES:[0],01f00h

	MOV   AX,1111h
	MOV   BX,2222h
	MOV   CX,3333h
	MOV   DX,3333h
@@repeat:
	MOV   AX,1111h
	IN   AL,60h
	CMP  AL,1
	JNE  @@repeat


	MOV   AX,4c00h
	INT  21h

end start
