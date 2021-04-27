#include <xc.inc>

    ; COMPARISON LOGIC

    score_single_grid:
	; expects a 16-byte grid starting at 0x214 from touchscreen
	; a grid held in FSR0 so I can read it properly

	movlb 0x02
	movlw 0x10      ; put 16 in WREG
	movwf 0x06, B   ; put in 0x06 as a counter
	lfsr 1, 0x214   ; put the touchscreen array in FSR1, array to compare to in FSR0
	movlw 0x10      
	movwf 0x208, B  ;  0x08 holds the score, start at 16 deduct for missing

    single_score_loop:
	; for my sanity, reserve 0x20E and 0x20F to hold the pair of bits
	; 0x20E should hold the grid being compared to
	; 0x20F should hold the touchscreen grid
	; 0x202 is the current index

	movf POSTINC0, W, A
	movwf 0x20E, B
	movf POSTINC1, W, A

	cpfseq 0x20E, B  ; if they match, skip
	decf 0x208       ; else deduct one point

	decfsz 0x206, 1  ; decrement the counter
	bra single_score_loop
	return     ; returns with score in 0x08


    score_all:
	movlb 0x02
	lfsr 0, 0x240    ; beginning of library in FSR0
	clrf 0x209, B    ; running best score holder, start low
	clrf 0x20D, B    ; counter for which character we?re on
	clrf 0x20A, B
	movf 0x20B, W, B
	movwf 0x205, B  ; how many characters available to test

    score_loop:
	call score_single_grid

	; now expect a score in 0x208
	movf 0x08, W, B  ; score in WREG

	cpfsgt 0x09, 1   ; if the current best score is less than W #chceck Ws later if needed
	movff 0x20D, 0x20A  ; put the current offset in 0x0A
	

	cpfsgt 0x209, 1   ; again, if W is a new high score
	movwf 0x209, B ; update the new high score
	

	incf 0x20D, B  ; update the counter;

	decfsz 0x205, B
	bra score_loop

	; now the offset of the letter with the best score should be in 0x20A
	lfsr 0, 0x230    ; 0x30 = loaded ascii characters from earlier
	movf 0x20A,W, B   ; put the offset into W
	; movlw 0x01    ; override the results and make the score 1
	addwf FSR0, 1
	movf INDF0, W
	; Finally, the ascii version should be in WREG

	return

    ; DONE WITH THE COMPARISON LOGIC


