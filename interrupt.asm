;Author: Mehmet Serefoglu
;Github-repo: https://github.com/mhmtsrfglu/Assembly-interrupt.git

;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to


                                            ; make it known to linker.
			.data
	.bss is_increasing, 1
	.bss is_increasing_former, 1
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main_loop:
	bis.b #01000001b, &P1DIR ; Set green and red led as an input
	bic.b #00001000b, &P1DIR ; Set Push-button as input.
	bis.b #01000000b, &P1OUT ; Turn the green led on.
	bic.b #00000001b, &P1OUT ; Red led off.
	bic.b #00001000b, &P1SEL
	bis.b #00001000b, &P1REN ; Enable internal resistor.
	bis.b #00001000b, &P1OUT ; Make it pull-out. http://www.resistorguide.com/pull-up-resistor_pull-down-resistor/
	bis.b #00001000b, &P1IE  ; Enable interrupts.
	eint
	mov #0, R5
	mov #0, R13 ;Flag=0,we will check wheather an intterupt occurs

	bis.b #10110110b,&P1DIR ;set output pins for P1.*
	bic.b #10110110b,&P1OUT ;control output pins for P1.*
	bis.b #00000011b,&P2DIR ;set output pins for P2.*
	bic.b #00000011b,&P2OUT ;control output pins for P2.*

check_pin:
	cmp #1, R13 ;if flag = 1 then decrement 7segment 9 to 0
	jeq pin_dec

pin_inc: ;increment 7segment 0 to 9
	mov #arr_1, R10 ;Ascending order array 0,1,2... located in #arr_1 and store in R10 register
	mov #arr_2, R12 ;Ascending order array 0,1,2... located in #arr_1 and store in R12 register
	mov #0, R7 ;counter paremeter in R7 register, we will use this compare with #NUMBERS_MAX like for loop, R7 < #NUMBERS_MAX then do somethings else do something else
	mov #NUMBERS_MAX, R9 
	jmp write_next

pin_dec: ;decrement 7segment 9 to 0
	mov #arr_1_reverse, R10
	mov #arr_2_reverse, R12
	mov #0, R7
	mov #NUMBERS_MAX, R9
	jmp write_next

write_next: ;write array elements to 7segment
	mov.b @R10, &P1OUT ;R9
	mov.b @R12, &P2OUT ;R9
	mov #N_ITERS_WAIT, R11
	call #wait_hede ;to obtain a delay.
	add #1,R7
	add #1,R10
	add #1,R12
	cmp R7, R9
	jne write_next
	jmp main_loop

wait_hede
	push R6
	push R8
	mov R11, R6
dec_val:
	dec	R6
	mov #N_CYCLES, R8
dec_val_1:
	dec R8
	cmp #0, R8
	jne dec_val_1
	cmp #0,	R6
	jne dec_val
	pop R8
	pop R6
	ret

P1_ISR:
	bic.b  #00001000b ,&P1IFG
	mov #0, R5
wait
	inc R5
	cmp #N_ITERS, R5

	jnz wait;continue
	mov #0, R5
	bit.b #00001000b, &P1IN
	jnz continue_0
	bis.b #01000000b, &P1OUT
	bic.b #00000001b, &P1OUT

	jmp continue
continue_0:
	bis.b #00000001b, &P1OUT
	bic.b #01000000b, &P1OUT
	mov #1,R13 ; if interrup then flag = 1
	jmp check_pin

continue
;	mov.b R5, &is_increasing_former

	reti
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

 ;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect   ".int02"
            .short  P1_ISR



;-----------
; Data
;-----------
			.data
			;arr_0	db	#00111111b, #00000110b, #01011011b, #01001111b, #01110110b;,
					;#01101101b, #01111101b, #00000111b, #11111111b, #01101111b

arr_1	.byte	0xFE, 0x5C, 0xEE, 0x7E, 0x5C, 0x7A, 0xFA, 0x5E, 0xFE, 0x7E ;P1BITS WITH GREEN LED
arr_2	.byte	0x01, 0x00, 0x02, 0x02, 0x03, 0x03, 0x03, 0x00, 0x03, 0x03 ;P2BITS 
arr_1_reverse	.byte	0x3F, 0xBF, 0x1F, 0xBB, 0x3B, 0x1D ,0x3F, 0xAF, 0x1D, 0xBF ;REVERSE P1 PINS WITH RED LED
arr_2_reverse	.byte	0x03, 0x03, 0x00, 0x03, 0x03, 0x03, 0x02, 0x02, 0x00, 0x01 ;P2 BITS


NUMBERS_MAX	.set	0x0a
N_ITERS	.set	0x195;0x1209
N_CYCLES .set	0x0a
N_ITERS_WAIT	.set	0x5209
