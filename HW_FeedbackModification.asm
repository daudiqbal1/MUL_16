; -----------------------------------------------------------
; Microcontroller Based Systems Homework
; Author name: Iqbal Daud
; Neptun code: X32SQC
; -------------------------------------------------------------------
; Task description: 
;   Multiplication of two 16 bit unsigned integers being in the internal memory. 
;   The result should be a 32 bit unsigned integer.
;   Inputs: Operand and result addresses (pointers)
;   Output: Result starting at the given address
; -------------------------------------------------------------------


; Definitions
; -------------------------------------------------------------------

; Address symbols for creating pointers

INPUT1_ADR  EQU 0x20
INPUT2_ADR  EQU 0x30
OUTPUT_ADR  EQU 0x40


; Test data for input parameters
; (Try also other values while testing your code.)

; Input 1: 300 (Hexadecimal: 0x012C)
INPUT1_H    EQU 0x01    ; High byte
INPUT1_L    EQU 0x2C    ; Low byte

; Input 2: 400 (Hexadecimal: 0x0190)
INPUT2_H    EQU 0x01    ; High byte
INPUT2_L    EQU 0x90    ; Low byte


; Interrupt jump table
ORG 0x0000;
    SJMP  MAIN                  ; Reset vector

; Beginning of the user program
ORG 0x0033

; -------------------------------------------------------------------
; MAIN program
; -------------------------------------------------------------------
; Purpose: Prepare the inputs and call the converter subroutines
; -------------------------------------------------------------------

MAIN:

    ; Prepare input parameters for the subroutine

    MOV R0,  #INPUT1_ADR    ; Initialize operand 1 in the internal data memory
    MOV @R0, #INPUT1_H      ; (big endian: high byte to low address)
    INC R0                  ; | Inc moves to the next register, so the Low bit will be stored in the adjacent register
    MOV @R0, #INPUT1_L      ; |

    MOV R1,  #INPUT2_ADR    ; Initialize operand 2 in the internal data memory
    MOV @R1, #INPUT2_H      ; (big endian: high byte to low address)
    INC R1                  ; |
    MOV @R1, #INPUT2_L      ; |

    MOV R0, #INPUT1_ADR     ; Input parameter 1 (address of operand 1)
    MOV R1, #INPUT2_ADR     ; Input parameter 2 (address of operand 2)
    MOV R2, #OUTPUT_ADR     ; Input parameter 3 (address of output)

; Infinite loop: Call the subroutine repeatedly
LOOP:

    CALL MUL_U16

    SJMP  LOOP




; ===================================================================           
;                           SUBROUTINE(S)
; ===================================================================           


; -------------------------------------------------------------------
; MUL_U16
; -------------------------------------------------------------------
; Purpose: Multiplication of two 16-bit unsigned integers
; -------------------------------------------------------------------
; INPUT(S):
;   R0 - Address of operand 1 (big endian)
;   R1 - Address of operand 2 (big endian)
;   R2 - Address of 32-bit result (big endian)
; OUTPUT(S): 
;   Result at the given address
; MODIFIES:
;   R0, R1, R2, R3, R5, R6, PSW, A and B
; -------------------------------------------------------------------

MUL_U16:

;Storing Values of Registers on Stack
    PUSH PSW;
    PUSH AR0;
    PUSH AR1;
    PUSH AR2;
    PUSH AR3;
    PUSH AR4;
    PUSH AR5;
    PUSH AR6;

;STEP1: Starting with the multiplication of INPUT1_L and INPUT2_L (bxd) 
;Storing the output in R3 and R4
    
    INC R0;             //incremented the register for INPUT1_L
    INC R1;             //also incremented for INPUT2_L
    MOV A, @R0;
    MOV B, @R1;
    MUL AB;             //product of INPUT1_L and INPUT2_L, in documentation I represented it with bxd
    MOV R3, A;          //Low byte of the product, Storing the result of multiplication for later use.
    MOV R4, B;          //High byte of Product

;STEP 2: Multiplication of INPUT1_H and INPUT2_H (axc)
;Storing the output in R5 and R6

    DEC R0;             //decremented for getting INPUT1_H
    DEC R1;             //decremented for getting INPUT2_H
    MOV A, @R0;
    MOV B, @R1;
    MUL AB;             //INPUT1_H x INPUT2_H (axc)
    MOV R5, A;          //A is low byte in all multiplcations
    MOV R6, B;          //B is high byte in all multiplications

;STEP 3: Multiplication of INPUT1_H and  INPUT2_L (axd), and addition operations
;The Output will be added to the existing outputs in R3, R4, R5 and R6
    
    INC R1;             //incremented to get INPUT2_L
    MOV A, @R0;
    MOV B, @R1;
    MUL AB;             //INPUT1_H x INPUT2_L (axd)
    ADD A, R4;          //Adding Low Byte of axd to High Byte of bxd    
    MOV R4, A;          //Storing result in R4
    MOV A, B;           //Moving value of B to A to perform ADD/ADDC
    ADDC A, R5;         //Add with carry from [ADD A, R4] to A and Low Byte of axc
    MOV R5, A;          //Storing result in R5
    MOV A, R6;          //Moving to A for ADD/ADDC 
    ADDC A, #00H;       //Adding carry from [ADD A, R5] to High Byte of axc, #00H is added as an immediate value
    MOV R6, A;          //Storing result in R6

;STEP 4: Multiplication of INPUT1_L and INPUT2_H (bxc) and Additions with the stored values in R3, R4, R5 and R6

    INC R0;               //incremented to get INPUT1_L
    DEC R1;               //decremented to get INPUT2_H
    MOV A, @R0;
    MOV B, @R1;
    MUL AB;               //INPUT1_L x INPUT2_H (bxc)
    ADD A, R4;            //Adding Sum of High Byte of bxd and Low Byte of axd to A
    MOV R4, A;            //Storing result in R4
    MOV A, B;               
    ADDC A, R5;           //Add with carry from [ADD A, R4] to A and Result stored in R5 
    MOV R5, A;              
    MOV A, R6;
    ADDC A, #00H;         //Adding carry from [ADD A, R5] to A  
    MOV R6, A;


;STEP 5: Writing Outputs in the Output Address
;For this we will first need to move the Address of R2 to R0, then store the output 1 by 1 using A to the output address
;The results are stored in registers R6, R5, R4 and R3, R6 is the highest Byte and R3 is the lowest byte, Output is stored as Big Endian

    MOV A, R2;
    MOV R0, A;      //Using R0 for writing to output for its indirect addressing property
    MOV A, R6;      //Storing value of R6 in A, for writing to output
    MOV @R0, A;     //Value from accumulator is stored in the address pointed by @R0
    INC R0;
    MOV A, R5;
    MOV @R0, A;
    INC R0;
    MOV A, R4;
    MOV @R0, A;
    INC R0;
    MOV A, R3;
    MOV @R0, A;


;Restoring Values of registers from Stack

    POP AR6;
    POP AR5;
    POP AR4;
    POP AR3;
    POP AR2;
    POP AR1;
    POP AR0;
    POP PSW;


    RET


END

