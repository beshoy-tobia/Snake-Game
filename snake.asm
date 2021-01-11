TITLE Snake.asm
INCLUDE Irvine32.inc

initSnake PROC USES EBX EDX

; This procedure initializes the snake to the default position
; in the center of the screen, written by mario hany

    MOV DH, 13      ; Set row number to 13
    MOV DL, 47      ; Set column number to 47
    MOV BX, 1       ; First segment of snake
    CALL saveIndex  ; Write to framebuffer

    MOV DH, 14      ; Set row number to 14
    MOV DL, 47      ; Set column number to 47
    MOV BX, 2       ; Second segment of snake
    CALL saveIndex  ; Write to framebuffer

    MOV DH, 15      ; Set row number to 15
    MOV DL, 47      ; Set column number to 47
    MOV BX, 3       ; Third segment of snake
    CALL saveIndex  ; Write to framebuffer

    MOV DH, 16      ; Set row number to 16
    MOV DL, 47      ; Set column number to 47
    MOV BX, 4       ; Fourth segment of snake
    CALL saveIndex  ; Write to framebuffer

    RET

initSnake ENDP

clearMem PROC

; This procedure clears the framebuffer, resets the snake position and length,
; and sets all the game related flags back to their default value.

    MOV DH, 0               ; Set the row register to zero
    MOV BX, 0               ; Set the data register to zero

    oLoop:                  ; Outer loop for matrix indexing (for rows)
        CMP DH, 24          ; Count for 24 rows and break if row number is 24
                            ; (since indexing starts form 0)
        JE endOLoop

        MOV DL, 0           ; Set the column number to zero

        iLoop:              ; Inner loop for matrix indexing (for columns)
            CMP DL, 80      ; Count for 80 columns and
            JE endILoop     ; break if column number is 80

            CALL saveIndex  ; Call procedure for writing to the framebuffer
                            ; based on the DH and DL registers
            INC DL          ; Increment column number
            JMP iLoop       ; Continue inner loop

    endILoop:               ; End of innter loop
        INC DH              ; Increment row number
        JMP oLoop           ; Continue outer loop

endOLoop:                   ; End of outer loop
    MOV tR, 16              ; Reset coordinates of
    MOV tC, 47              ; snake tail (row and column)
    MOV hR, 13              ; Reset coordinates of
    MOV hC, 47              ; snake head (row and column)

    MOV eGame, 0            ; Clear the end game flag
    MOV eTail, 1            ; Set the erase tail flag (no food eaten)
    MOV d, 'w'              ; Set current direction to up
    MOV newD, 'w'           ; Set new direction to up
    MOV cScore, 0           ; Reset total score

    RET
clearMem ENDP
