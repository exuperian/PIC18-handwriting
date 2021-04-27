#include <xc.inc>
   
psect    data

; character table stores the actual images
    character_table:
	character_count:
	db 0x07   ; number of characters to read

	my_zero:
	db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00
	my_one:
	db 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00
	my_two:
	db 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	my_three:
	db 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	my_four:
	db 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	my_five:
	db 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00
	my_empty:
	db 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    characters:
	db "0", "1", "2", "3", "4", "5", 0x0    ; the ascii values of those images
	
; LOAD THE CHARACTER TABLE INTO MEMORY
    load_chars:
	movlb 0x2

	; set up table pointer
	movlw low highword(character_count)
	movwf TBLPTRU, A
	movlw high(character_count)
	movwf TBLPTRH, A
	movlw low(character_count)
	movwf TBLPTRL, A

	tblrd*+
	movff TABLAT, 0x20B  ; store the number of characters in 0x20B
	movff 0x20B, 0x205   ; copy number of chars to 0x05
	
	movlw 0x10           ; 16 bytes per character matrix
	clrf 0x206, B        ; zero out 0x206 to hold the total no of bytes
	
    mul_loop:                ; calculates the number of bytes to read in       
	addwf 0x206, B       ; ie adds 0x10 to memory loc 0x206 n times, where
	decfsz 0x205, B      ; n in the no of character to be read, stored in 0x205
	bra mul_loop

	movff 0x20B, 0x205   ; restore the char count to 0x205
	lfsr 0, 0x240        ; point the file register to the beginning of the library

    grid_read_loop:          ; for the no of bytes in the library, calc above
	tblrd*+              ; read them all in
	movff TABLAT, POSTINC0
	decfsz 0x206, B
	bra grid_read_loop


	lfsr 0, 0x230        ; now read in their ASCII values 
    chars_read_loop:
	tblrd*+
	movff TABLAT, POSTINC0
	decfsz 0x05, B
	bra chars_read_loop
	return     

	
    ; These two functions are currently unused but provide useful test data
    ; they load data into 0x214, where the touchscreen puts its results, bypassing it
    ; Designed to allow tests of the character recognition directly.
    
    ; Recall library (starting at 0x240), corresponding ascii values (starting at 0x230) and the number of such values (0x20B)

    load_test_grid:      ; bypass the touchscreen process and load data directly
	lfsr 0, 0x214    ; the address the touchscreen writes to
	movlb 0x02

	movlw low highword(my_one)
	movwf TBLPTRU, A
	movlw high(my_one)
	movwf TBLPTRH, A
	movlw low(my_one)
	movwf TBLPTRL, A

	movlw 0x10
	movwf 0x205, B  ; put 16 in as a counter

    test_loop:
	tblrd*+
	movff TABLAT, POSTINC0
	decfsz 0x205, B
	bra test_loop
	return

	; now you have an image in 0x214 as if the touchscreen has put it there

    ; DONE LOADING DATA



