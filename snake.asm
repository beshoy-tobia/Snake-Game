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
