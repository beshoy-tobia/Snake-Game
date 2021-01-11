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

startGame PROC USES EAX EBX ECX EDX
        MOV EAX, white + (black * 16)       ; Set text color to white on black
        CALL SetTextColor
        MOV DH, 24                          ; Move cursor to bottom lef side
        MOV DL, 0                           ; of screen, to write the score
        CALL GotoXY                         ; string
        MOV EDX, OFFSET scoreS
        CALL WriteString

        ; Get console input handle and store it in memory
        INVOKE getStdHandle, STD_INPUT_HANDLE
        MOV myHandle, EAX
        MOV ECX, 10

        ; Read two events from buffer
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead

       ; Main infinite loop
    more:

        ; Get number of events in input buffer
        INVOKE GetNumberOfConsoleInputEvents, myHandle, ADDR numInp
        MOV ECX, numInp

        CMP ECX, 0                          ; Check if input buffer is empty
        JE done                             ; Continue loop if buffer is empty

        ; Read one event from input buffer and save it at temp
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        MOV DX, WORD PTR temp               ; Check if EventType is KEY_EVENT,
        CMP DX, 1                           ; which is determined by 1st WORD
        JNE SkipEvent                       ; of INPUT_RECORD message

            MOV DL, BYTE PTR [temp+4]       ; Skip key released event
            CMP DL, 0
            JE SkipEvent
                MOV DL, BYTE PTR [temp+10]  ; Copy pressed key into DL

                CMP DL, 1Bh                 ; Check if ESC key was pressed and
                JE quit                     ; quit the game if it was

                CMP d, 'w'                  ; Check if current snake direction
                JE case1                    ; is vertical, and jump to case1 to
                CMP d, 's'                  ; handle direction change if the
                JE case1                    ; change is horizontal

                JMP case2                   ; Jump to case2 if the current
                                            ; direction is horizontal
                case1:
                    CMP DL, 25h             ; Check if left arrow was in input
                    JE case11
                    CMP DL, 27h             ; Check if right arrow was in input
                    JE case12
                    JMP SkipEvent           ; If up or down arrows were in
                                            ; input, no direction change
                    case11:
                        MOV newD, 'a'       ; Set new direction to left
                        JMP SkipEvent
                    case12:
                        MOV newD, 'd'       ; Set new direction to right
                        JMP SkipEvent

                case2:
                    CMP DL, 26h             ; Check if up arrow was in input
                    JE case21
                    CMP DL, 28h             ; Check if down arrow was in input
                    JE case22
                    JMP SkipEvent           ; If left of right arrows were in
                                            ; input, no direction change
                    case21:
                        MOV newD, 'w'       ; Set new direction to up
                        JMP SkipEvent
                    case22:
                        MOV newD, 's'       ; Set new direction to down
                        JMP SkipEvent

    SkipEvent:
        JMP more                            ; Continue main loop

    done:

        MOV BL, newD                        ; Set new direction as snake
                                            ; direction
        MOV d, BL
        CALL MoveSnake                      ; Update direction and position
        MOV EAX, DelTime                    ; Delay before next iteration (game
        CALL Delay                          ; speed is influenced this way)

        MOV BL, d                           ; Why is this needed?
        MOV newD, BL                        ; Maybe delete these two lines

        CMP eGame, 1                        ; Check if end game flag is set
        JE quit                             ; (from a collision)

        JMP more                            ; Continue main loop

        quit:
        CALL clearMem                       ; Set all game related things to
        MOV delTime, 100                    ; default, and go back to main
                                            ; menu
    RET

startGame ENDP
