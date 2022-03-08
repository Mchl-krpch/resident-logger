

	  locals            ; using locals in program
	  .186              ; use 186-processor commands

	.model tiny

	  .code
	EXIT_CODE = 04C00h
	PAUSE_VAL = 00000h
	VIDEO_PTR = 0B800h
	NINE  = 09h * 4
	EIGHT = 08h * 4
	  org 100h

;--------------------------------------------------------------------------------------------------------
  ;  Change interrupt at address ES:[INT_ADDRESS] with offset OLD_OFFSET to a new one
  ; with offset NEW_OFFSET with saving old ptr (to OLD_OFFSET) and old segment (to OLD_SEGMENT) buffers
  ;  [save-convention] macro
;--------------------------------------------------------------------------------------------------------
CHANGE_INTERRUPT macro INT_ADDRESS, OLD_OFFSET, OLD_SEGMENT, NEW_OFFSET
	PUSH  AX                                    ; save ax
	MOV   AX,ES:[INT_ADDRESS]                   ; {   saving old segment and offset 
	MOV   OLD_OFFSET,AX                         ; | to buffers 'OLD_OFFSET' and 'OLD_SEGMENT'
	MOV   AX,ES:[INT_ADDRESS + 2]               ; |
	MOV   OLD_SEGMENT,AX                        ; }
	MOV   AX,CS                                 ; {   save cs and offset of function of jmp
	cli                                         ; | as interrupt
	MOV   ES:[INT_ADDRESS],offset NEW_OFFSET    ; |
	MOV   ES:[INT_ADDRESS + 2],AX               ; |
	sti                                         ; }
	POP   AX                                    ; return ax value
	ENDM

RESTORE_INTERRUPT macro INT_ADDRESS, OLD_OFFSET, OLD_SEGMENT
	PUSH  DI SI AX BX                           ; save regs
	MOV   DI,offset OLD_OFFSET                  ; { move data to registers
	MOV   SI,offset OLD_SEGMENT                 ; |
	MOV   AX,[DI]                               ; |
	MOV   BX,[SI]                               ; }
	cli                                         ; stop interrupts
	MOV   ES:[INT_ADDRESS],AX                   ; { move regs values to interrupt
	MOV   ES:[INT_ADDRESS + 2],BX               ; }
	sti                                         ; continue interrupts work
	POP   BX AX SI DI
	ENDM

start:
	MOV   origin_es,ES                          ; Save original value of es
	XOR   DI,DI
main_program PROC
	  ; #1 replace our interrupts
	MOV   ES,DI
	CHANGE_INTERRUPT EIGHT, interrupt_8_offset, interrupt_8_segment, new_interrupt_8
	CALL  terminate_resident
	ENDP

new_interrupt_8 PROC
	PUSH AX BX CX DX DI SI SP BP DS ES
	PUSH  CS
	POP   DS
	CALL  set_video_segment
	PUSH  offset colors2
	PUSH  DS
	CALL  drow_window
	CALL  drow_regs
	POP  ES DS BP SP SI DI DX CX BX AX
	DB 0EAh
interrupt_8_offset  DW 0
interrupt_8_segment DW 0
	RET
	ENDP

set_video_segment PROC
	PUSH  AX
	MOV   ES,origin_es
	MOV   AX,VIDEO_PTR
	MOV   ES,AX
	POP   AX
	RET
	ENDP

terminate_resident PROC
	MOV   DX,offset program_space
	SHR   DX,4
	INC   DX
	MOV   AX,3100h
	INT   21h
	ENDP

          origin_es DW 0                 ; maybe unusable

ax_reg DB 'ax ', 0
bx_reg DB 'bx ', 0
cx_reg DB 'cx ', 0
dx_reg DB 'dx ', 0
di_reg DB 'di ', 0
si_reg DB 'si ', 0

INCLUDE string.asm
INCLUDE frame.asm

program_space:
end start