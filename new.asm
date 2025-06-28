.MODEL SMALL
.STACK 100h

.DATA
    msg_welcome     DB "Instruction Set Simulator in Assembly", 13, 10, "$"
    msg_input       DB 13, 10, "Enter instruction (e.g., MOV AX, 5): $"
    msg_invalid     DB 13, 10, "Invalid or Unsupported Instruction!$"
    msg_div_zero    DB 13, 10, "Error: Division by zero!$"
    msg_result      DB 13, 10, "Registers after execution:", 13, 10, "$"
    msg_ax          DB "AX = $"
    msg_bx          DB 13, 10, "BX = $"
    msg_cx          DB 13, 10, "CX = $"
    msg_dx          DB 13, 10, "DX = $"
    
    input_buffer    DB 50, ?, 50 DUP(?) 
    regAX           DW 0
    regBX           DW 0
    regCX           DW 0
    regDX           DW 0
    OPCODE          DB 3 DUP(?) 
    msg_add_result   DB 13, 10, "ADD operation completed.$"
msg_mov_result   DB 13, 10, "MOV operation executed.$"

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    LEA DX, msg_welcome
    CALL PRINT_STRING

INPUT_LOOP:
    LEA DX, msg_input
    CALL PRINT_STRING
    LEA DX, input_buffer
    CALL GET_STRING
    CALL TO_UPPERCASE
    CALL PARSE_INSTRUCTION
    CALL DISPLAY_REGISTERS
    JMP INPUT_LOOP
MAIN ENDP

DISPLAY_REGISTERS PROC
    LEA DX, msg_result
    CALL PRINT_STRING
    LEA DX, msg_ax
    CALL PRINT_STRING
    MOV AX, regAX
    CALL PRINT_NUMBER
    LEA DX, msg_bx
    CALL PRINT_STRING
    MOV AX, regBX
    CALL PRINT_NUMBER
    LEA DX, msg_cx
    CALL PRINT_STRING
    MOV AX, regCX
    CALL PRINT_NUMBER
    LEA DX, msg_dx
    CALL PRINT_STRING
    MOV AX, regDX
    CALL PRINT_NUMBER
    RET
DISPLAY_REGISTERS ENDP

PRINT_STRING PROC
    MOV AH, 09H
    INT 21H
    RET
PRINT_STRING ENDP

GET_STRING PROC
    MOV AH, 0AH
    INT 21H
    ; Null-terminate the string
    MOV SI, DX
    ADD SI, 2
    XOR CH, CH
    MOV CL, [SI-1]   ; Length of input
    ADD SI, CX
    MOV BYTE PTR [SI], 0
    RET
GET_STRING ENDP

TO_UPPERCASE PROC
    LEA SI, input_buffer + 2
    MOV CL, input_buffer + 1
    XOR CH, CH
    JCXZ END_TO_UPPERCASE
TO_UPPER_LOOP:
    MOV AL, [SI]
    CMP AL, 'a'
    JL SKIP_CONV
    CMP AL, 'z'
    JG SKIP_CONV
    SUB AL, 32
    MOV [SI], AL
SKIP_CONV:
    INC SI
    LOOP TO_UPPER_LOOP
END_TO_UPPERCASE:
    RET
TO_UPPERCASE ENDP

SKIP_SPACES PROC
    SKIP_LOOP:
        CMP BYTE PTR [SI], ' '
        JNE END_SKIP
        INC SI
        JMP SKIP_LOOP
    END_SKIP:
        RET
SKIP_SPACES ENDP

PARSE_INSTRUCTION PROC
    LEA SI, input_buffer + 2
    CALL SKIP_SPACES
    
    ; Copy 3-character opcode to buffer
    MOV DI, OFFSET OPCODE
    MOV CX, 3
COPY_OPCODE:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_OPCODE
    
    ; Compare opcode using exact byte comparison
    CMP OPCODE[0], 'M'
    JNE CHECK_ADD
    CMP OPCODE[1], 'O'
    JNE CHECK_MUL  ; Check for MUL if not MOV
    CMP OPCODE[2], 'V'
    JNE CHECK_MUL  ; Check for MUL if not MOV
    CALL HANDLE_MOV
    RET
    
CHECK_ADD:
    CMP OPCODE[0], 'A'
    JNE CHECK_SUB
    CMP OPCODE[1], 'D'
    JNE CHECK_SUB
    CMP OPCODE[2], 'D'
    JNE CHECK_SUB
    CALL HANDLE_ADD
    RET
    
CHECK_SUB:
    CMP OPCODE[0], 'S'
    JNE CHECK_DIV  ; Check for DIV if not SUB
    CMP OPCODE[1], 'U'
    JNE CHECK_DIV
    CMP OPCODE[2], 'B'
    JNE CHECK_DIV
    CALL HANDLE_SUB
    RET
    
CHECK_MUL:
    CMP OPCODE[0], 'M'
    JNE CHECK_DIV
    CMP OPCODE[1], 'U'
    JNE CHECK_DIV
    CMP OPCODE[2], 'L'
    JNE CHECK_DIV
    CALL HANDLE_MUL
    RET
    
CHECK_DIV:
    CMP OPCODE[0], 'D'
    JNE CHECK_INC
    CMP OPCODE[1], 'I'
    JNE CHECK_INC
    CMP OPCODE[2], 'V'
    JNE CHECK_INC
    CALL HANDLE_DIV
    RET
    
CHECK_INC:
    CMP OPCODE[0], 'I'
    JNE CHECK_DEC
    CMP OPCODE[1], 'N'
    JNE CHECK_DEC
    CMP OPCODE[2], 'C'
    JNE CHECK_DEC
    CALL HANDLE_INC
    RET
    
CHECK_DEC:
    CMP OPCODE[0], 'D'
    JNE INVALID_INST
    CMP OPCODE[1], 'E'
    JNE INVALID_INST
    CMP OPCODE[2], 'C'
    JNE INVALID_INST
    CALL HANDLE_DEC
    RET
    
INVALID_INST:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
PARSE_INSTRUCTION ENDP

HANDLE_MOV PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_MOV
    MOV BX, AX  ; Save register index
    
    ; Skip register name (2 characters)
    ADD SI, 2
    CALL SKIP_SPACES
    
    ; Check for comma
    CMP BYTE PTR [SI], ','
    JNE GET_VALUE_MOV
    INC SI
    CALL SKIP_SPACES
    
GET_VALUE_MOV:
    CALL READ_IMM
    ; Update correct register based on index
    CMP BL, 0
    JE SET_AX
    CMP BL, 1
    JE SET_BX
    CMP BL, 2
    JE SET_CX


    ; Must be DX if we got here
    MOV regDX, AX
    LEA DX, msg_mov_result
CALL PRINT_STRING

    RET
    
SET_AX:
    MOV regAX, AX
    RET
    
SET_BX:
    MOV regBX, AX
    RET
    
SET_CX:
    MOV regCX, AX
    RET
    
INVALID_REG_MOV:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_MOV ENDP

HANDLE_ADD PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_ADD
    MOV BX, AX  ; Save register index
    
    ; Skip register name
    ADD SI, 2
    CALL SKIP_SPACES
    
    ; Check for comma
    CMP BYTE PTR [SI], ','
    JNE GET_VALUE_ADD
    INC SI
    CALL SKIP_SPACES
    
GET_VALUE_ADD:
    CALL READ_IMM
    ; Update correct register
    CMP BL, 0
    JE ADD_AX
    CMP BL, 1
    JE ADD_BX
    CMP BL, 2
    JE ADD_CX

    

    ; Must be DX if we got here
    ADD regDX, AX
    LEA DX, msg_add_result
CALL PRINT_STRING
    RET
    
ADD_AX:
    ADD regAX, AX
    RET
    
ADD_BX:
    ADD regBX, AX
    RET
    
ADD_CX:
    ADD regCX, AX
    RET
    
INVALID_REG_ADD:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_ADD ENDP

HANDLE_SUB PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_SUB
    MOV BX, AX  ; Save register index
    
    ; Skip register name
    ADD SI, 2
    CALL SKIP_SPACES
    
    ; Check for comma
    CMP BYTE PTR [SI], ','
    JNE GET_VALUE_SUB
    INC SI
    CALL SKIP_SPACES
    
GET_VALUE_SUB:
    CALL READ_IMM
    ; Update correct register
    CMP BL, 0
    JE SUB_AX
    CMP BL, 1
    JE SUB_BX
    CMP BL, 2
    JE SUB_CX
    ; Must be DX if we got here
    SUB regDX, AX
    RET
    
SUB_AX:
    SUB regAX, AX
    RET
    
SUB_BX:
    SUB regBX, AX
    RET
    
SUB_CX:
    SUB regCX, AX
    RET
    
INVALID_REG_SUB:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_SUB ENDP

HANDLE_MUL PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_MUL
    MOV BX, AX  ; Save register index
    
    ; Skip register name
    ADD SI, 2
    CALL SKIP_SPACES
    
    ; Check for comma
    CMP BYTE PTR [SI], ','
    JNE GET_VALUE_MUL
    INC SI
    CALL SKIP_SPACES
    
GET_VALUE_MUL:
    CALL READ_IMM
    ; Update correct register
    CMP BL, 0
    JE MUL_AX
    CMP BL, 1
    JE MUL_BX
    CMP BL, 2
    JE MUL_CX
    ; Must be DX if we got here
    MOV CX, AX
    MOV AX, regDX
    MUL CX
    MOV regDX, AX
    RET
    
MUL_AX:
    MOV CX, AX
    MOV AX, regAX
    MUL CX
    MOV regAX, AX
    RET
    
MUL_BX:
    MOV CX, AX
    MOV AX, regBX
    MUL CX
    MOV regBX, AX
    RET
    
MUL_CX:
    MOV CX, AX
    MOV AX, regCX
    MUL CX
    MOV regCX, AX
    RET
    
INVALID_REG_MUL:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_MUL ENDP

HANDLE_DIV PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_DIV
    MOV BX, AX  ; Save register index
    
    ; Skip register name
    ADD SI, 2
    CALL SKIP_SPACES
    
    ; Check for comma
    CMP BYTE PTR [SI], ','
    JNE GET_VALUE_DIV
    INC SI
    CALL SKIP_SPACES
    
GET_VALUE_DIV:
    CALL READ_IMM
    ; Check for division by zero
    CMP AX, 0
    JE DIV_ZERO
    
    ; Update correct register
    CMP BL, 0
    JE DIV_AX
    CMP BL, 1
    JE DIV_BX
    CMP BL, 2
    JE DIV_CX
    ; Must be DX if we got here
    MOV CX, AX
    MOV AX, regDX
    XOR DX, DX
    DIV CX
    MOV regDX, AX
    RET
    
DIV_AX:
    MOV CX, AX
    MOV AX, regAX
    XOR DX, DX
    DIV CX
    MOV regAX, AX
    RET
    
DIV_BX:
    MOV CX, AX
    MOV AX, regBX
    XOR DX, DX
    DIV CX
    MOV regBX, AX
    RET
    
DIV_CX:
    MOV CX, AX
    MOV AX, regCX
    XOR DX, DX
    DIV CX
    MOV regCX, AX
    RET
    
DIV_ZERO:
    LEA DX, msg_div_zero
    CALL PRINT_STRING
    RET
    
INVALID_REG_DIV:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_DIV ENDP

HANDLE_INC PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_INC
    
    ; Skip the register name (2 characters)
    ADD SI, 2
    
    ; Update correct register
    CMP AL, 0
    JE INC_AX
    CMP AL, 1
    JE INC_BX
    CMP AL, 2
    JE INC_CX
    ; Must be DX if we got here
    INC regDX
    RET
    
INC_AX:
    INC regAX
    RET
    
INC_BX:
    INC regBX
    RET
    
INC_CX:
    INC regCX
    RET
    
INVALID_REG_INC:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_INC ENDP

HANDLE_DEC PROC
    CALL SKIP_SPACES
    CALL PARSE_REGISTER
    CMP AL, 0FFh
    JE INVALID_REG_DEC
    
    ; Skip the register name (2 characters)
    ADD SI, 2
    
    ; Update correct register
    CMP AL, 0
    JE DEC_AX
    CMP AL, 1
    JE DEC_BX
    CMP AL, 2
    JE DEC_CX
    ; Must be DX if we got here
    DEC regDX
    RET
    
DEC_AX:
    DEC regAX
    RET
    
DEC_BX:
    DEC regBX
    RET
    
DEC_CX:
    DEC regCX
    RET
    
INVALID_REG_DEC:
    LEA DX, msg_invalid
    CALL PRINT_STRING
    RET
HANDLE_DEC ENDP

PARSE_REGISTER PROC
    ; Check for AX
    MOV AL, [SI]
    CMP AL, 'A'
    JNE CHECK_B
    CMP BYTE PTR [SI+1], 'X'
    JNE INVALID_REG_PARSER
    MOV AL, 0
    RET
    
CHECK_B:
    ; Check for BX
    CMP AL, 'B'
    JNE CHECK_C
    CMP BYTE PTR [SI+1], 'X'
    JNE INVALID_REG_PARSER
    MOV AL, 1
    RET
    
CHECK_C:
    ; Check for CX
    CMP AL, 'C'
    JNE CHECK_D
    CMP BYTE PTR [SI+1], 'X'
    JNE INVALID_REG_PARSER
    MOV AL, 2
    RET
    
CHECK_D:
    ; Check for DX
    CMP AL, 'D'
    JNE INVALID_REG_PARSER
    CMP BYTE PTR [SI+1], 'X'
    JNE INVALID_REG_PARSER
    MOV AL, 3
    RET
    
INVALID_REG_PARSER:
    MOV AL, 0FFh
    RET
PARSE_REGISTER ENDP

READ_IMM PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR AX, AX        ; Clear result
    MOV BX, 10        ; Base 10 multiplier
    
SKIP_ND:
    ; Skip non-digit characters
    MOV CL, [SI]
    CMP CL, 0         ; End of string?
    JE END_READ
    CMP CL, '0'
    JB NOT_DIGIT
    CMP CL, '9'
    JBE START_CONV
    
NOT_DIGIT:
    INC SI
    JMP SKIP_ND
    
START_CONV:
    ; Convert digit string to number
CONV_LOOP:
    MOV CL, [SI]
    CMP CL, 0         ; End of string?
    JE END_CONV
    CMP CL, '0'
    JB END_CONV
    CMP CL, '9'
    JA END_CONV
    
    ; Multiply current value by 10
    XOR DX, DX
    MUL BX
    
    ; Add new digit
    SUB CL, '0'
    XOR CH, CH
    ADD AX, CX
    
    ; Next character
    INC SI
    JMP CONV_LOOP
    
END_CONV:
    POP DX
    POP CX
    POP BX
    RET
    
END_READ:
    POP DX
    POP CX
    POP BX
    RET
READ_IMM ENDP

PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Handle zero case
    CMP AX, 0
    JNE NOT_ZERO
    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP END_PRINT

NOT_ZERO:
    ; Prepare for digit conversion
    XOR CX, CX        ; Digit counter
    MOV BX, 10        ; Divisor

DIVIDE:
    XOR DX, DX
    DIV BX            ; AX = quotient, DX = remainder
    PUSH DX           ; Save digit
    INC CX            ; Increase digit count
    TEST AX, AX       ; Continue until quotient is zero
    JNZ DIVIDE

PRINT_LOOP:
    POP DX            ; Get digit
    ADD DL, '0'       ; Convert to ASCII
    MOV AH, 02H       ; Print character
    INT 21H
    LOOP PRINT_LOOP

END_PRINT:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

END MAIN