    #include <xc.inc>
    #include "character_lib.s"    
    #include "recognition.s"
    #include "touchscreen.s"
    
    ; WRITTEN BY ALEX HODGES AND BRODIE ALLAN
    ; MARCH 2021

    psect code, abs
	org 0x0

    setup:                ; standard PIC18 initialization
	bcf CFGS
	bsf EEPGD
	goto main

    main:
	call load_chars   ; in character_lib; load library from flash to RAM
	call setup_ADC    ; in touchscreen.s; prepare ADC for conversion
	clrf TRISD        ; set PORTD to output to show operating
	goto operate

    operate:
	call setup_table  ; in touchscreen.s; zero out RAM used to store input character
	call read_loop    ; in touchscreen.s; run touchscreen read loop until PORTJ press

	clrf TRISH        ; set PORTH to output result
	call score_all    ; in recognition.s; calcualte the best match and put in WREG
	movwf LATH        ; display the output
	call long_delay   ; wait so that PORTJ butoon press definitely released

	bra operate       ; start all over again


	; TABLE OF MEMORY USED, ALL IN BANK 2

	; 0x00 - delay counter for long_delay
	; 0x01 - delay counter for delay_inner
	; 0x02 - delay counter for delay

	; 0x02 - internal counter for convert function
	; 0x03 - the value 16, used in the convert function
	; 0x04 - the result from the convert function (though also moved to WREG)

	; 0x05 - descending counter for looping through saved character grids. Used
	       ; in load_chars and score_all
	; 0x06 - how many bytes used to store saved char matrices

	; 0x07 - counter used in setup_table

	; 0x08 - score of each individual letters. Used by score_single_grid
	; 0x09 - running best score
	; 0x0A - offset of running best score

	; 0x0B - number of saved letters available
	; 0x0C - internal logic for score_single
	; 0x0D - the offset of each letter used in score_all

	; 0x10 - raw x value from touchscreen
	; 0x11 - raw y value from touchscreen
	; 0x12 - scaled x value from touchscreen
	; 0x13 - scaled y value from touchscreen

	; 0x14 : 0x24 - grid of read in touchscreen values
	; 0x30 : 0x35 - "0", "1", "2", "3", "4", "5"
	; 0x40 : 0x50 - grid for "0"
	; 0x50 : 0x60 - grid for "1"
	; 0x60 : 0x70 - grid for "2"
	; 0x70 : 0x80 - grid for "3"
	; 0x80 : 0x90 - grid for "4"
	; 0x90 : 0xA0 - grid for "5"

	end main
