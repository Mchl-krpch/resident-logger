;--------------------------------------------------------------------------------------------------------
  ;  prepares registers for the function of drawing one line to the frame
  ; LEFT, CENTER, RIGHT - symbols in COLOR_CONFIG:[...] array
  ; COLOR_CONFIG is array of symbols to drow frame
  ;  [save-convention]
;--------------------------------------------------------------------------------------------------------
LINE_WRAPPER macro LEFT, CENTER, RIGHT, COLOR_CONFIG
	PUSH  BX AX CX                        ; save 
	MOV   DS,parent_ds                    ; | get parent regs
	MOV   SI,parent_si                    ; | to calculate right offset
	MOV   AX,[DS:[SI] + LEFT]             ; { get right left boarder symbol
	PUSH  AX                              ; }
	MOV   AX,[DS:[SI] + CENTER]           ; { get right window symbol
	PUSH  AX                              ; }
	MOV   AX,[DS:[SI] + RIGHT]            ; { get right RIGHT boarder symbol
	PUSH  AX                              ; }
	MOV   DS,child_ds                     ; return child regs
	MOV   SI,child_si                     ; to execute line properly
	MOV   AX,[word ptr DS:win_props + 4]  ; { Get line settings
	SUB   AX,2                            ; |
	PUSH  AX                              ; |
	MOV   AX,[word ptr DS:win_props + 0]  ; |
	PUSH  AX                              ; }
	CALL  drow_line                       ; call executable line
	POP   CX AX BX                        ; return values
	ENDM

;--------------------------------------------------------------------------------------------------------
  ;  translates the register value into hexadecimal number system and displays it on the screen,
  ; having previously received the offset in the video segment
  ;  [save-convention]
;--------------------------------------------------------------------------------------------------------
UPDATE_REG macro REG, VALUE
	PUSH  BX DX                           ; save regs
	MOV   SI,offset REG                   ; set string offset to 'print'
	PUSH  DI                              ; set di for 'print'
	PUSH  SI                              ; set si for 'print'
	CALL  print                           ; call header-print
	MOV   AX,VALUE                        ; set value to translate for 'itoa'
	MOV   BX,offset itoa_string           ; set string offset to drow to 'itoa'
	MOV   DX,16                           ; set radix value for 'itoa'
	CALL  itoa                            ; translate value to hex
	MOV   SI,BX
	PUSH  DI                              ; set di value for 'print'
	PUSH  SI                              ; set si value for 'print'
	CALL  print                           ; print reg value
	POP   DX BX DI                        ; return regs
	ENDM

;--------------------------------------------------------------------------------------------------------
  ;  drowint window function (use only offset of color config as argument)
;--------------------------------------------------------------------------------------------------------
drow_window PROC
	MOV   BP,SP
	CALL  define_import_offsets
	PUSH  BX SI                           ; save regs
	PUSH  BX CX                           ; {   calculate upper 
	MOV   BX,offset win_props             ; | offset for frame
	MOV   AX,160                          ; |
	MOV   CX,[BX + 2]                     ; | 
	MUL   CX                              ; |
	MOV   DI,AX                           ; |
	POP   CX BX                           ; }
	LINE_WRAPPER 10, 4, 8, BP + 2         ; drow upper line
	MOV   CX,[word ptr DS:win_props + 6]  ; { create a cycle for drow line
	SUB   CX,2                            ; |
@@drow_window_line:
	LINE_WRAPPER  6, 2, 6, BP + 2         ; | drow window line
	loop @@drow_window_line               ; }
	LINE_WRAPPER  12, 4, 14, BP + 2
	POP   SI BX
	RET   4
	ENDP

;--------------------------------------------------------------------------------------------------------
  ; get parent values of ds and offset values
;--------------------------------------------------------------------------------------------------------
define_import_offsets PROC
	MOV   child_ds,DS                     ; {  save ds and si in this
	MOV   child_si,SI                     ; } file to child buffers
	MOV   AX,[BP + 2]                     ; {   move parent ds, si
	MOV   parent_ds,AX                    ; | to parent buffers
	MOV   AX,[BP + 4]                     ; |
	MOV   parent_si,AX                    ; }
	RET
	ENDP

;--------------------------------------------------------------------------------------------------------
  ; drow-line function (use 3 symbols from stack {left-border, window, right-border}symbol)
;--------------------------------------------------------------------------------------------------------
drow_line PROC
	MOV   BP,SP                           ; make stake great again
	ADD   DI,[BP + 2]                     ; add offset by left sight of screen
	MOV   AX,[BP + 6]                     ; move left boarder symbol in current string
	stosw                                 ; move next char to screens
	MOV   CX,[BP + 4]                     ; calculate len of inner symbols in window
	MOV   AX,[BP + 8]                     ; move window sym
	rep stosw                             ; fill window space
	MOV   AX,[BP + 10]                    ; move left boarder symbol
	stosw                                 ; move it to screen
	CALL  round_up_di_to_next_string      ; | this string can be write only 50/80 symbols for exambple
	RET   10                              ; | so we add to di 30 symbols more
	ENDP

;--------------------------------------------------------------------------------------------------------
  ; rounds up di value to new string for example you have only di=50 and it rounds up di to 80
  ; and it will be new string offset in video-segment
;--------------------------------------------------------------------------------------------------------
round_up_di_to_next_string PROC
	PUSH  CX                              ; save cx
	MOV   CX,160                          ; add string len (80 * 2) 80 - screen len
	SUB   CX,[word ptr DS:win_props + 0]  ; { number of remaining characters
	SUB   CX,[word ptr DS:win_props + 4]  ; |
	SUB   CX,[word ptr DS:win_props + 4]  ; }
	ADD   DI,CX                           ; | add this number to di to get new string on
	POP   CX                              ; | screen 
	RET
	ENDP

;--------------------------------------------------------------------------------------------------------
  ; drows registers in frame
  ; incoming: di
  ; destroy:  di
;--------------------------------------------------------------------------------------------------------
drow_regs PROC
	CALL  calculate_first_reg_place
	PUSH  DI
	UPDATE_REG ax_reg,BP
	ADD   DI,160
	PUSH  DI
	UPDATE_REG bx_reg,SI
	ADD   DI,160
	PUSH  DI
	UPDATE_REG cx_reg,DI
	ADD   DI,160
	PUSH  DI
	UPDATE_REG dx_reg,SI
	ADD   DI,160
	PUSH  DI
	UPDATE_REG di_reg,CS
	ADD   DI,160
	PUSH  DI
	UPDATE_REG si_reg,BP
	RET
	ENDP

;--------------------------------------------------------------------------------------------------------
  ; computing first register place in frame
;--------------------------------------------------------------------------------------------------------
calculate_first_reg_place PROC
	PUSH  AX BX
	MOV   AX,[word ptr DS:win_props + 2]
	INC   AX
	MOV   BX,160
	MUL   BX
	MOV   BX,[word ptr DS:win_props + 0]
	ADD   BX,4
	ADD   AX,BX
	MOV   DI,AX
	POP   BX AX
	RET
	ENDP

parent_ds DW 0
parent_si DW 0

child_ds DW 0
child_si DW 0
itoa_string DB '    ',0

win_props:
DW 00086h  ; skip of left pixels       [  0]
DW 00003h  ; skip top pixels           [  2]
DW 0000Bh  ; width                     [  4]
DW 00008h  ; height                    [  6] 

colors:
DW 00000h  ; black background          [  0] # BRUSHES
DW 01f00h  ; window background         [  2]
DW 01FC4h  ; horisontAL border         [  4]
DW 01FB3h  ; verticAL border           [  6]
DW 01FDAh  ; left upper corner         [  8] # CORNERS
DW 01FBFh  ; right upper corner        [ 10]
DW 01FD9h  ; right down corner         [ 12]
DW 01FC0h  ; left down corner          [ 14]

colors2:
DW 00000h  ; black background          [  0] # BRUSHES
DW 00f00h  ; window background         [  2]
DW 00fcdh  ; horisontAL border         [  4]
DW 00fbah  ; verticAL border           [  6]
DW 00Fc9h  ; left upper corner         [  8] # CORNERS
DW 00fbbh  ; right upper corner        [ 10]
DW 00fbch  ; right down corner         [ 12]
DW 00fc8h  ; left down corner          [ 14]