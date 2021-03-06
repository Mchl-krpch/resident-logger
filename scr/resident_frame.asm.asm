;--------------------------------------------------------------------------------------------------------
; 		File:     resident_frame.asm
; 		Date:     march 2022 
; 	Purpose:
; 	- use the replacement of interrupts with your own, thereby making the
; 	  program running in the background and executing my instruction on pressing a key
;
; 	implemented:  [regular task, additional task]
; 	- Implemented the replacement of interrupts with macros and the rendering of the window
; 	  with macros - this helped to reduce a large number of lines of code and, in my opinion,
; 	  increased the readability of the code
; 	- Working with a multi-file project
; 	- Passing array offset to another file
; 	- Completion of the program as a resident
;
;	@Michael-krpch
;--------------------------------------------------------------------------------------------------------
	  locals            ; using locals in program
	  .186              ; use 186-processor commands
;--------------------------------------------------------------------------------------------------------
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

;--------------------------------------------------------------------------------------------------------
  ;  return default interrupt with address ES:[INT_ADDRESS] as default interrupt. macro use buffers
  ; OLD_OFFSET and OLD_SEGMENT to get old values and set int to default address
  ;  [save-convention] macro
;--------------------------------------------------------------------------------------------------------
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
	PUSH  CS
	POP   DS
	PUSH  ax bx cx dx
	MOV   origin_es,ES                          ; Save original value of es
	XOR   DI,DI
	MOV   ES,DI
	pop   dx cx bx ax

main_program PROC
	PUSH  ax bx cx dx
	CHANGE_INTERRUPT EIGHT, interrupt_8_offset, interrupt_8_segment, new_interrupt_8
	CHANGE_INTERRUPT NINE,  interrupt_9_offset, interrupt_9_segment, new_interrupt_9
	pop   dx cx bx ax
	CALL  terminate_resident
	ENDP

new_interrupt_8 PROC
	PUSH  SP BP                                 ; save stack registers
	MOV   BP,SP                                 ; create label in stack
	PUSH  AX 1111h BX CX DX                     ; save common-registers
	PUSH  DI SI DS ES                           ; save counters and segments
	PUSH  CS                                    ; | identify cs as ds segment
	POP   DS                                    ; |
	CMP   drow_flag,0                           ; check drow-flag
	JE    drow_nothing                          ; if it equiv to zero we dont drow a frame
drow_frame:
	PUSH  BP                                    ; save bp to 'drow-regs'-function
	CALL  set_video_segment                     ; identify video segment
	PUSH  offset colors                         ; choose color-config
	PUSH  DS                                    ; save ds to drow correctly
	CALL  drow_window                           ; drow
	POP  BP
	CALL  drow_regs                             ; drow regs
drow_nothing:
	POP  ES DS SI DI                            ; { return values
	POP  DX CX BX AX AX                         ; |
	POP  BP SP                                  ; }
	DB 0EAh
interrupt_8_offset  DW 0
interrupt_8_segment DW 0
	ENDP

new_interrupt_9 PROC
	PUSH AX BX CX DX DI SI SP BP DS ES          ; save regs
	PUSH  CS
	POP   DS
	IN    AL,60h
	CMP   AL,56                                 ; 'alt' scan code
	JE  @@stop_resident                         ; if user press alt-key we stop resident executing at all
	CMP   AL,29                                 ; 'left-ctrl' scan code
	JNE @@proc_end                              ; if user pres left-ctrl we dont drow frame for next press of left-ctrl button
@@change_drow_flag:
	call  set_video_segment
	MOV   AH,drow_flag                          ; { change value of drow-flag
	MOV   AL,changing_value                     ; |
	MOV   drow_flag,AL                          ; |
	MOV   changing_value,AH                     ; }
@@proc_end:
	POP  ES DS BP SP SI DI DX CX BX AX          ; return regs
	DB 0EAh                                     ; far jmp ptr
interrupt_9_offset  DW 0                            ; |   save-buffers
interrupt_9_segment DW 0                            ; | for old ptr of interrupt 9
@@stop_resident:
	CALL set_video_segment
	PUSH offset colors_empty                    ; set color config with only black symbols
	PUSH DS                                     ; move ds to drow window correctly
	CALL drow_window                            ; drow window
	XOR   DI,DI                                 ; | set to es zero-value
	MOV   ES,DI                                 ; |
	RESTORE_INTERRUPT EIGHT, interrupt_8_offset, interrupt_8_segment 
	RESTORE_INTERRUPT NINE,  interrupt_9_offset, interrupt_9_segment
	JMP @@proc_end
	RET
	ENDP

set_video_segment PROC
	PUSH  AX                                    ; save ax
	MOV   ES,origin_es                          ; return origin value to es 
	MOV   AX,VIDEO_PTR                          ; | set video-segment offset to es
	MOV   ES,AX                                 ; |
	POP   AX                                    ; return ax
	RET
	ENDP

terminate_resident PROC
	MOV   DX,offset program_space               ;   terminate the program but
	SHR   DX,4                                  ; we leave it as resident programm
	INC   DX                                    ; by function 3100h
	MOV   AX,3100h                              ; (programm size we set in paragraphs)
	INT   21h                                   ; call exit interrupt
	ENDP

drow_flag      DB 1
changing_value DB 0

INCLUDE frame.asm
INCLUDE string.asm

program_space:
end start