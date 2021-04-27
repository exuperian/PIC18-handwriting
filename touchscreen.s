#include <xc.inc>

    
    
    ; NEXT SECTION ABOUT TOUCHSCREEN OPERATION

    setup_table:
	movlb 0x02
	; initialize an 16-byte array full of zeros
	movlw 16
	movwf 0x207, B  ; set 16 in 0x07 as the counter

	movlw 0x214  ; starting location of the array
	lfsr 0, 0x214  
	
    clear_loc:
	clrf POSTINC0, A
	decfsz 0x07, B
	bra clear_loc
	return   

    setup_ADC:
	; set to be left justified, acquisition time,
	movlw 00011011B
	banksel ADCON2
	movwf ADCON2, B

	; set single ended, V_ref
	banksel ADCON1
	movlw 10110000B
	movwf ADCON1, B

	; set RF2 and RF5 as analogue input
	banksel ANCON0
	clrf ANCON0, B
	bsf ANCON0, 5, B
	bsf ANCON0, 7, B

	; turn ADC on
	banksel ADCON0
	bsf ADON

	; reset banksel
	movlb 0x00

	; set up PORTE as output, PORTF as input
	setf TRISF, A    ; all input
	clrf TRISE, A    ; all output
	clrf PORTE, A   ; all grounded

	return

    read_x_setup:
	; uses the DRIVEA and READX pins on RE4 and RF5
	; turn on DRIVEA

	clrf LATE, A
	bsf RE4

	; set RF5 as  input
	banksel ADCON0
	movlw 0101001B  ; channel AN10 (AKA RF5) is selected
	movwf ADCON0, B
	movlb 0x00
	return

    read_y_setup:
	; uses the DRIVEB and READY pins on RE5 and RF2
	; turn on DRIVEA
	clrf LATE, A
	bsf RE5

	; set RF2 as input
	banksel ADCON0
	movlw 0011101B  ; channel AN7 (AKA RF2) is selected
	movwf ADCON0, B
	movlb 0x00
	return

    run_adc:
	; make ADC run, using a polling approach
	banksel ADCON0
	bsf GO    ; set conversion running
    poll:
	btfsc GO  ; if conversion done
	bra poll  ; loop

	; now should be a value in ADRESH
	banksel ADRESH
	movf ADRESH, W, B
	call delay

	return


    read_position:
	; read in the current position and store x in 0x210, y in 0x211
	movlb 0x02
	call read_x_setup
	call run_adc
	movlb 0x02
	movwf 0x210, B

	call read_y_setup
	call run_adc
	movlb 0x02
	movwf 0x211, B
	return

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    convertX:
	; takes an 8-bit number in WREG and scales to being between 0 to 3 (inclusive)
	movlb 0x02
	movwf 0x202, B  ; hold target number momentarily
	movlw 0x0E     ; put 12h in WREG # NEED TO CHANGE IF CHANGE NUMB CELLS
	movwf 0x203, B  ; mov 18 to 0x03

	movlw -1      ; put -1 in WREG
	movwf 0x204, B  ; put -1 in 0x204 as a counter
	movlw 0x14
	subwf 0x202
	movf 0x202, W, B ; return target number to WREG

    subtractX:
	incf 0x204, B    ; increment the counter
	subfwb 0x203, W, B  ; subtract 8 from WREG
	bnn subtractX
	; 0x204 = number subs needed (coordinate)
	movf 0x204, W, B ; put the counter in WREG
	return    

    convertY:
	; takes an 8-bit number in WREG and scales to being between 0 to 3 (inclusive)
	movlb 0x02
	movwf 0x202, B  ; hold target number momentarily
	movlw 0x0D     ; put 15h in WREG # NEED TO CHANGE IF CHANGE NUMB CELLS
	movwf 0x203, B  ; mov 14 to 0x03

	movlw -1      ; put -1 in WREG
	movwf 0x204, B  ; put -1 in 0x204 as a counter
	movlw 0x1E
	subwf 0x202
	movf 0x202, W, B ; return target number to WREG

    subtractY:
	incf 0x204, B    ; increment the counter
	subfwb 0x203, W, B  ; subtract 64 from WREG
	bnn subtractY
	; 0x204 = number subs needed (coordinate)
	movf 0x04, W, B ; put the counter in WREG
	return    
    convert_to_coords:
	; takes the raw x, y values from the ADC, stored in 0x210 and 0x211, & puts coords in 0x212 and 0x213
	movlb 0x02
	movf 0x210, W, B    ; x position from ADC
	call convertX        ; x coordinate
	movwf 0x212, B   ; column number in 0x212

	movf 0x211, W, B    ; y position from ADC
	call convertY        ; y coordinate
	movwf 0x213, B   ; row number in 0x213  int[(0x212, 0x213)] £{0,3}
	return
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; convert into an array index

    update_table:
	lfsr 0, 0x214
	movf   0x213, W   ; better than multiplication!
	addwf    0x213, W
	addwf    0x213, W
	addwf    0x213, W
	addwf    0x212, W, B   ; offset in WREG now
	addwf FSR0
	setf INDF0, A   ; set that cell to 0xFF
	return

    delay_inner:
	movlb 0x02
	movlw 0x40
	movwf 0x201, B
    inside_1:
	decfsz 0x201, B
	bra inside_1
	return

    delay:
	setf 0x202, B
    inside:
	call delay_inner
	decfsz 0x202, B
	bra inside
	return

    long_delay:
	movlb 0x02
	movlw 0x30
	movwf 0x200, B
    long_inside:
	call delay
	decfsz 0x200
	bra long_inside
	return

    read_loop:
	; when called, run until button on PORTJ is pressed, then return with pattern in table
    ;    call setup_read_cycle  ; prepare ADC and empty table at 0x214
	clrf TRISD

    read_inner_loop:
	movlb 0x02
	call read_y_setup
	call run_adc
	movff 0xFC4, 0x211      ; move from ADRESH

	call read_x_setup
	call run_adc
     ;   movlb 0x02
	movff  0xFC4, 0x210     ; move from ADRESH to 0x210

	call convert_to_coords
	call update_table      ; updates the table at 0x214 with that touch
	
	movlb 0x02
	call delay             ; wait a moment

	incf PORTD             ; visual way to tell still running
	movlw 0xFE             ; check if PORTD has cycled back round
	cpfslt PORTD
	clrf PORTD

	tstfsz PORTJ           ; check if PORTJ pressed
	goto fin_loop          ; if pressed, break out of loop
	goto read_inner_loop   ; if not pressed, go again

    fin_loop:
	setf PORTD
	return

     ; END TOUCHSCREEN OPERATION    



