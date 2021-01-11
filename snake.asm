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

MoveSnake PROC USES EBX EDX

; This procedure updates the framebuffer, thus moving the snake. The procedure
; starts from the snake tail, and searches for the next segment in the
; region of the current segment. All segments get updated, while the last
; segment gets erased (if no food has been eaten), and a new segment gets
; addded to the beginning of the snake, depending on the terminal input.
; This procedure also check if there has been a collision, and if the food was
; gobbled or not.

    CMP eTail, 1            ; Check if erase tail flag is set
    JNE NoETail             ; Don't erase the tail if flag is not set

        MOV DH, tR          ; Copy tail row index into DH
        MOV DL, tC          ; Copy tail column index into DL
        CALL accessIndex    ; Access framebuffer at given index
        DEC BX              ; Decrement value returned from framebuffer (this
                            ; gives us the value of the next segment)
        MOV search, BX      ; Copy value of next segment to search

        MOV BX, 0           ; Erase the value at current index from the
        CALL saveIndex      ; framebuffer (the snake tail)

        CALL GotoXY         ; Erase snake tail pixel from screen
        MOV EAX, white + (black * 16)
        CALL SetTextColor
        MOV AL, ' '
        CALL WriteChar

        PUSH EDX            ; Move cursor to bottom right side of the screen
        MOV DL, 79
        MOV DH, 23
        CALL GotoXY
        POP EDX

        MOV AL, DH          ; Copy tail row index into AL
        DEC AL              ; Get index of row above current row
        MOV rM, AL          ; Save index of row above current row
        ADD AL, 2           ; Get index of row below current row
        MOV rP, AL          ; Save index of row below current row

        MOV AL, DL          ; Copy tail column index into AL
        DEC AL              ; Get index of column left of current column
        MOV cM, AL          ; Save index of column left of current column
        ADD AL, 2           ; Get index of column right of current column
        MOV cP, AL          ; Save index of column right of current column

        CMP rP, 24          ; Check if new index is getting off screen
        JNE next1
            MOV rP, 0       ; Wrap the index around the screen

        next1:
        CMP cP, 80          ; Check if new index is getting off screen
        JNE next2
            MOV cP, 0       ; Wrap the index around the screen

        next2:
        CMP rM, 0           ; Check if new index is getting off screen
        JGE next3
            MOV rM, 23      ; Wrap the index around the screen

        next3:
        CMP cM, 0           ; Check if new index is getting off screen
        JGE next4
            MOV cM, 79      ; Wrap the index around the screen

        next4:

        MOV DH, rM          ; Copy row index of pixel above tail into DH
        MOV DL, tC          ; Copy column index of pixel above tail into DL
        CALL accessIndex    ; Access pixel value in framebuffer
        CMP BX, search      ; Check if pixel is the next segment of the snake
        JNE melseif1
            MOV tR, DH      ; Move tail to new location, if it is
            JMP mendif

        melseif1:
        MOV DH, rP          ; Copy row index of pixel below tail into DH
        CALL accessIndex    ; Acces pixel value in framebuffer
        CMP BX, search      ; Check if pixel is the next segment of the snake
        JNE melseif2
            MOV tR, DH      ; Move tail to new location, if it is
            JMP mendif

        melseif2:
        MOV DH, tR          ; Copy row index of pixel left of tail into DH
        MOV DL, cM          ; Copy column index of pixel left of tail into DH
        CALL accessIndex    ; Access pixel value in framebuffer
        CMP BX, search      ; Check if pixes is the next segment of the snake
        JNE melse
            MOV tC, DL      ; Move tail to new location, if it is
            JMP mendif

        melse:
            MOV DL, cP      ; Move tail to pixel right of tail
            MOV tC, DL

        mendif:

    NoETail:

    MOV eTail, 1            ; Set erase tail flag
    MOV DH, tR              ; Copy row index of tail into DH
    MOV DL, tC              ; Copy column index of tail into DL
    MOV tmpR, DH            ; Copy row index into memory
    MOV tmpC, DL            ; Copy column index into memory

    whileTrue:              ; Infinite loop for going over all the snake
                            ; segments and adjusting each value
        MOV DH, tmpR        ; Copy current row index into DH
        MOV DL, tmpC        ; Copy current column index into DL
        CALL accessIndex    ; Get pixel value form framebuffer
        DEC BX              ; Decrement pixel value to get the value of the
                            ; next snake segment
        MOV search, BX      ; Copy value of next segment into search

        PUSH EBX            ; Replace current segment value in framebuffer with
        ADD BX, 2           ; previous segment value (snake is moving, segments
        CALL saveIndex      ; are moving)
        POP EBX

        CMP BX, 0           ; Check if the current segment is the head of the
        JE break            ; snake

        MOV AL, DH          ; Copy row index of current segment into AL
        DEC AL              ; Get index of row above current row
        MOV rM, AL          ; Save index of row above current row
        ADD AL, 2           ; Get index of row below current row
        MOV rP, AL          ; Save index of row below current row

        MOV AL, DL          ; Copy column index of current segment into AL
        DEC AL              ; Get index of column left of current column
        MOV cM, AL          ; Save index of column left of current column
        ADD AL, 2           ; Get index of column right of current column
        MOV cP, AL          ; Save index of column right of current column

        CMP rP, 24          ; Check if new index is getting off screen
        JNE next21
            MOV rP, 0       ; Wrap index around screen

        next21:
        CMP cP, 80          ; Check if new index is getting off screen
        JNE next22
            MOV cP, 0       ; Wrap index around screen

        next22:
        CMP rM, 0           ; Check if index is getting off screen
        JGE next23
            MOV rM, 23      ; Wrap index around screen

        next23:
        CMP cM, 0           ; Check if index is getting off screen
        JGE next24
            MOV cM, 79      ; Wrap index around screen

        next24:

        MOV DH, rM          ; Copy row index of pixel above segment into DH
        MOV DL, tmpC        ; Copy column index of pixel above segment into DH
        CALL accessIndex    ; Access pixel value in framebuffer
        CMP BX, search      ; Check if pixel is the next segment of the snake
        JNE elseif21
            MOV tmpR, DH    ; Move index to new location, if it is
            JMP endif2

        elseif21:
        MOV DH, rP          ; Copy row index of pixel below segment into DH
        CALL accessIndex    ; Access pixel value in framebuffer
        CMP BX, search      ; Check if pixel is the next segment of the snake
        JNE elseif22
            MOV tmpR, DH    ; Move index to new location, if it is
            JMP endif2

        elseif22:
        MOV DH, tmpR        ; Copy row index of pixel left of segment into DH
        MOV DL, cM          ; Copy column index of pxl left of segment into DL
        CALL accessIndex    ; Access pixel value in framebuffer
        CMP BX, search      ; Check if pixel is the next segment of the snake
        JNE else2
            MOV tmpC, DL    ; Move index to new location if it is
            JMP endif2

        else2:
            MOV DL, cP      ; Move index to pixel right of segment
            MOV tmpC, DL

        endif2:
        JMP whileTrue       ; Continue loop until the snake head is reached

    break:

    MOV AL, hR              ; Copy head row index into AL
    DEC AL                  ; Get index of row above head row
    MOV rM, AL              ; Save index of row above head row
    ADD AL, 2               ; Get index of row below head row
    MOV rP, AL              ; Save index of row below head row

    MOV AL, hC              ; Copy head column index into AL
    DEC AL                  ; Get index of column left of head column
    MOV cM, AL              ; Save index of column left of head column
    ADD AL, 2               ; Get index of column right of head column
    MOV cP, AL              ; Save index of column right of head column

    CMP rP, 24              ; Check if new index is getting off screen
    JNE next31
        MOV rP, 0           ; Wrap index around screen

    next31:
    CMP cP, 80              ; Chekc if new index is getting off screen
    JNE next32
        MOV cP, 0           ; Wrap index around screen

    next32:
    CMP rM, 0               ; Check if new index is getting off sreen
    JGE next33
        MOV rM, 23          ; Wrap index around screen

    next33:
    CMP cM, 0               ; Check if new index is getting off screen
    JGE next34
        MOV cM, 79          ; Wrap index around screen

    next34:

    CMP d, 'w'              ; Check if input direction is up
    JNE elseif3
        MOV AL, rM          ; Move head row index to new location,
        MOV hR, AL          ; above current location
        JMP endif3

    elseif3:
    CMP d, 's'              ; Check if input direction is down
    JNE elseif32
        MOV AL, rP          ; Move head row index to new location,
        MOV hR, AL          ; below current location
        JMP endif3

    elseif32:
    CMP d, 'a'              ; Check if input direction is left
    JNE else3
        MOV AL, cM          ; Move head column index to new location,
        MOV hC, AL          ; left of current location
        JMP endif3

    else3:
        MOV AL, cP          ; Move head column index to new location,
        MOV hC, AL          ; right of current location

    endif3:

    MOV DH, hR              ; Copy new head row index into DH
    MOV DL, hC              ; Copy new head column index into DL

    CALL accessIndex        ; Get pixel value of new head location
    CMP BX, 0               ; Check if new head location is empty space
    JE NoHit                ; If the new head location is empty space, there
                            ; has been no collision
    MOV EAX, 4000           ; Set delay time to 4000ms
    MOV DH, 24              ; Move cursor to new location, to write game over
    MOV DL, 11              ; message
    CALL GotoXY
    MOV EDX, OFFSET hitS
    CALL WriteString

    CALL Delay              ; Call delay to pause game for 4 seconds
    MOV eGame, 1            ; Set end game flag

    RET                     ; Exit procedure

    NoHit:                  ; Part of procedure that handles the case where
    MOV BX, 1               ; there's been no collision
    CALL saveIndex          ; Write head value to new head location

    MOV cl, fC              ; Copy food column to memory
    MOV ch, fR              ; Copy food row to memory

    CMP cl, DL              ; Compare new head column and food column
    JNE foodNotGobbled      ; Food has not been eaten
    CMP ch, DH              ; Compare new head row and food row
    JNE foodNotGobbled      ; Food has not been eaten

    CALL createFood         ; Food has been eaten, create new food location
    MOV eTail, 0            ; Clear erase tail flag, so that snake grows in
                            ; next framebuffer update

    MOV EAX, white + (black * 16)
    CALL SetTextColor       ; Change background color to white on black

    PUSH EDX                ; Push EDX onto stack

    MOV DH, 24              ; Move cursor to new location, to update score
    MOV DL, 7
    CALL GotoXY
    MOV EAX, cScore         ; Move score to EAX and increment it
    INC EAX
    CALL WriteDec
    MOV cScore, EAX         ; Copy updated score value back into memory

    POP EDX                 ; Pop EDX off of stack

    foodNotGobbled:         ; Part of procedure that handles the case where
    CALL GotoXY             ; food has not been eaten (just adds head)
    MOV EAX, blue + (white * 16)
    CALL setTextColor       ; Change text color to blue on white
    MOV AL, ' '             ; Write whitesoace to new head location
    CALL WriteChar
    MOV DH, 24              ; Move cursor to bottom right side of screen
    MOV DL, 79
    CALL GotoXY

    RET                     ; Exit procedure

MoveSnake ENDP

createFood PROC USES EAX EBX EDX
redo:                       ; Loop for food position generation
    MOV EAX, 24                 ; Generate a radnom integer in the
    CALL RandomRange            ; range 0 to numRows - 1
    MOV DH, AL

    MOV EAX, 80                 ; Generate a radnom integer in the
    CALL RandomRange            ; range 0 to numCol - 1
    MOV DL, AL

    CALL accessIndex            ; Get content of generated location

    CMP BX, 0                   ; Check if content is empty space
    JNE redo                    ; Loop until location is empty space

    MOV fR, DH                  ; Set food row value
    MOV fC, DL                  ; Set food column value

    MOV EAX, white + (cyan * 16); Set text color to white on cyan
    CALL setTextColor
    CALL GotoXY                 ; Move cursor to generated position
    MOV AL, ' '                 ; Write whitespace to terminal
    CALL WriteChar

    RET

createFood ENDP

accessIndex PROC USES EAX ESI EDX
MOV BL, DH      ; Copy row index into BL
    MOV AL, 80      ; Copy multiplication constant for row number
    MUL BL          ; Mulitply row index by 80 to get framebuffer segment
    PUSH DX         ; Push DX onto stack
    MOV DH, 0       ; Clear upper byte of DX to get only column index
    ADD AX, DX      ; Add column offset to row segment to get pixel address
    POP DX          ; Pop DX off of stack
    MOV ESI, 0      ; Clear indexing register
    MOV SI, AX      ; Copy generated address into indexing register
    SHL SI, 1       ; Multiply address by 2 since the elements are of type WORD

    MOV BX, a[SI]   ; Copy framebuffer content into BX register

    RET

accessIndex ENDP

saveIndex PROC USES EAX ESI EDX
PUSH EBX        ; Save EBX on stack
    MOV BL, DH      ; Copy row number to BL
    MOV AL, 80      ; Copy multiplication constant for row number
    MUL BL          ; Multiply row index by 80 to get framebuffer segment
    PUSH DX         ; Push DX onto stack
    MOV DH, 0       ; Clear DH register, to access the column number
    ADD AX, DX      ; Add column offset to get the array index
    POP DX          ; Pop old address off of stack
    MOV ESI, 0      ; Clear indexing register
    MOV SI, AX      ; Move generated address into ESI register
    POP EBX         ; Pop EBX off of stack
    SHL SI, 1       ; Multiply address by two, because elements
                    ; are of type WORD
    MOV a[SI], BX   ; Save BX into array

    RET

saveIndex ENDP

