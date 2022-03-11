;===============================================================================
;  ______  ______        _   _            _
; / ___\ \/ / __ )      | | | | __ _  ___| | _____ _ __
; \___ \\  /|  _ \ _____| |_| |/ _` |/ __| |/ / _ \ '__|
;  ___) /  \| |_) |_____|  _  | (_| | (__|   <  __/ |
; |____/_/\_\____/      |_| |_|\__,_|\___|_|\_\___|_|
;
; A program for Hacking your W65C265SXB or W65C816SXB
;-------------------------------------------------------------------------------
; Copyright (C),2015-2018 Andrew Jacobs
; All rights reserved.
;
; CC65 conversion by Derek Mulcahy.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;===============================================================================
; Notes:
;
; This program provides a simple monitor that you can use to inspect the memory
; in your SXB and reprogram parts of the flash ROM.
;
;-------------------------------------------------------------------------------

                .list on
                .p816

                .include "w65c816.inc"

;===============================================================================
;-------------------------------------------------------------------------------

.macro          MNEM  P,Q,R
                .word     ((((P-'@')<<5)|(Q-'@'))<<5)|(R-'@')
.endmacro

;===============================================================================
; ASCII Character Codes
;-------------------------------------------------------------------------------

SOH             =     $01
EOT             =     $04
ACK             =     $06
BEL             =     $07
BS              =     $08
LF              =     $0a
CR              =     $0d
NAK             =     $15
CAN             =     $18
ESC             =     $1b
DEL             =     $7f

;===============================================================================
;-------------------------------------------------------------------------------

OP_ADC          =     0<<1
OP_AND          =     1<<1
OP_ASL          =     2<<1
OP_BCC          =     3<<1
OP_BCS          =     4<<1
OP_BEQ          =     5<<1
OP_BIT          =     6<<1
OP_BMI          =     7<<1
OP_BNE          =     8<<1
OP_BPL          =     9<<1
OP_BRA          =     10<<1
OP_BRK          =     11<<1
OP_BRL          =     12<<1
OP_BVC          =     13<<1
OP_BVS          =     14<<1
OP_CLC          =     15<<1
OP_CLD          =     16<<1
OP_CLI          =     17<<1
OP_CLV          =     18<<1
OP_CMP          =     19<<1
OP_COP          =     20<<1
OP_CPX          =     21<<1
OP_CPY          =     22<<1
OP_DEC          =     23<<1
OP_DEX          =     24<<1
OP_DEY          =     25<<1
OP_EOR          =     26<<1
OP_INC          =     27<<1
OP_INX          =     28<<1
OP_INY          =     29<<1
OP_JML          =     30<<1
OP_JMP          =     31<<1
OP_JSL          =     32<<1
OP_JSR          =     33<<1
OP_LDA          =     34<<1
OP_LDX          =     35<<1
OP_LDY          =     36<<1
OP_LSR          =     37<<1
OP_MVN          =     38<<1
OP_MVP          =     39<<1
OP_NOP          =     40<<1
OP_ORA          =     41<<1
OP_PEA          =     42<<1
OP_PEI          =     43<<1
OP_PER          =     44<<1
OP_PHA          =     45<<1
OP_PHB          =     46<<1
OP_PHD          =     47<<1
OP_PHK          =     48<<1
OP_PHP          =     49<<1
OP_PHX          =     50<<1
OP_PHY          =     51<<1
OP_PLA          =     52<<1
OP_PLB          =     53<<1
OP_PLD          =     54<<1
OP_PLP          =     55<<1
OP_PLX          =     56<<1
OP_PLY          =     57<<1
OP_REP          =     58<<1
OP_ROL          =     59<<1
OP_ROR          =     60<<1
OP_RTI          =     61<<1
OP_RTL          =     62<<1
OP_RTS          =     63<<1
OP_SBC          =     64<<1
OP_SEC          =     65<<1
OP_SED          =     66<<1
OP_SEI          =     67<<1
OP_SEP          =     68<<1
OP_STA          =     69<<1
OP_STP          =     70<<1
OP_STX          =     71<<1
OP_STY          =     72<<1
OP_STZ          =     73<<1
OP_TAX          =     74<<1
OP_TAY          =     75<<1
OP_TCD          =     76<<1
OP_TCS          =     77<<1
OP_TDC          =     78<<1
OP_TRB          =     79<<1
OP_TSB          =     80<<1
OP_TSC          =     81<<1
OP_TSX          =     82<<1
OP_TXA          =     83<<1
OP_TXS          =     84<<1
OP_TXY          =     85<<1
OP_TYA          =     86<<1
OP_TYX          =     87<<1
OP_WAI          =     88<<1
OP_WDM          =     89<<1
OP_XBA          =     90<<1
OP_XCE          =     91<<1

MD_ABS          =     0<<1                    ; a
MD_ACC          =     1<<1                    ; A
MD_ABX          =     2<<1                    ; a,x
MD_ABY          =     3<<1                    ; a,y
MD_ALG          =     4<<1                    ; al
MD_ALX          =     5<<1                    ; al,x
MD_AIN          =     6<<1                    ; (a)
MD_AIX          =     7<<1                    ; (a,x)
MD_DPG          =     8<<1                    ; d
MD_STK          =     9<<1                    ; d,s
MD_DPX          =     10<<1                   ; d,x
MD_DPY          =     11<<1                   ; d,x
MD_DIN          =     12<<1                   ; (d)
MD_DLI          =     13<<1                   ; [d]
MD_SKY          =     14<<1                   ; (d,s),y
MD_DIX          =     15<<1                   ; (d,x)
MD_DIY          =     16<<1                   ; (d),y
MD_DLY          =     17<<1                   ; [d],y
MD_IMP          =     18<<1                   ;
MD_REL          =     19<<1                   ; r
MD_RLG          =     20<<1                   ; rl
MD_MOV          =     21<<1                   ; xyc
MD_IMM          =     22<<1                   ; # (A or M)
MD_INT          =     23<<1                   ; # (BRK/COP/WDM)
MD_IMX          =     24<<1                   ; # (X or Y)

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

                 .segment "ZEROPAGE"

                 .org     $20

FLAGS:           .res      1                       ; Emulated processor flags
BUFLEN:          .res      1                       ; Command buffer length
BANK:            .res      1                       ; Memory bank

ADDR_S:          .res      3                       ; Start address
ADDR_E:          .res      3                       ; End address

BLOCK:           .res      1                       ; XMODEM block number
RETRIES:         .res      1                       ; Retry count
SUM:             .res      1                       ; Checksum

TEMP:            .res      4                       ; Scratch workspace

                 .segment "BSS"

                 .org      $0200

BUFFER:          .res      256                     ; Command buffer

;===============================================================================
; Initialisation
;-------------------------------------------------------------------------------

                .segment "CODE"

                .org $039b

                .export  Start
                .import  UartRx
                .import  UartTx
                .import  UartRxTest
                .import  RomSelect
                .import  RomCheck
Start:
                short_a                         ; Configure register sizes
                long_i
                jsr     TxCRLF
                ldx     #TITLE                  ; Display application title
                jsr     TxStr

                stz     BANK                    ; Reset default bank

;===============================================================================
; Command Processor
;-------------------------------------------------------------------------------

NewCommand:
                stz     BUFLEN                  ; Clear the buffer
ShowCommand:
                short_i
                jsr     TxCRLF                  ; Move to a new line

                lda     #'.'                    ; Output the prompt
                jsr     UartTx

                ldx     #0
DisplayCmd:     cpx     BUFLEN                  ; Any saved characters
                beq     ReadCommand
                lda     BUFFER,x                ; Yes, display them
                jsr     UartTx
                inx
                bra     DisplayCmd

RingBell:
                lda     #BEL                    ; Make a beep
                jsr     UartTx

ReadCommand:
                jsr     UartRx                  ; Wait for character

                cmp     #ESC                    ; Cancel input?
                beq     NewCommand              ; Yes, clear and restart
                cmp     #CR                     ; End of command?
                beq     ProcessCommand          ; Yes, start processing

                cmp     #BS                     ; Back space?
                beq     BackSpace
                cmp     #DEL                    ; Delete?
                beq     BackSpace

                cmp     #' '                    ; Printable character
                bcc     RingBell                ; No.
                cmp     #DEL
                bcs     RingBell                ; No.
                sta     BUFFER,x                ; Save the character
                inx
                jsr     UartTx                  ; Echo it and repeat
                bra     ReadCommand

BackSpace:
                cpx     #0                      ; Buffer empty?
                beq     RingBell                ; Yes, beep and continue
                dex                             ; No, remove last character
                lda     #BS
                jsr     UartTx
                jsr     TxSpace
                lda     #BS
                jsr     UartTx
                bra     ReadCommand             ; And retry

ProcessCommand:
                stx     BUFLEN                  ; Save final length
                ldy     #0                      ; Load index for start

                jsr     SkipSpaces              ; Fetch command character
                bcs     NewCommand              ; None, empty command

;===============================================================================
; B - Select Memory Bank
;-------------------------------------------------------------------------------

                cmp     #'B'                    ; Select memory bank?
                bne     NotMemoryBank

                ldx     #BANK                   ; Parse bank
                jsr     GetByte
                bcc     *+5
                jmp     ShowError
                jmp     NewCommand
NotMemoryBank:

;===============================================================================
; D - Disassemble Memory
;-------------------------------------------------------------------------------

                cmp     #'D'                    ; Memory display?
                bne     NotDisassemble

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError
                ldx     #ADDR_E                 ; Parse end address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError

                php
                pla
                sta     FLAGS

Disassemble:
                jsr     TxCRLF
                lda     ADDR_S+2                ; Show memory address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2
                jsr     TxSpace

                jsr     TxCodeBytes             ; Show code bytes
                jsr     TxSymbolic              ; And instruction

                lda     [ADDR_S]                ; Fetch opcode again
                pha
                ldy     #1

                cmp     #$18                    ; CLC?
                bne     NotCLC
                lda     #C_FLAG
                bra     DoREP
NotCLC:
                cmp     #$38                    ; SEC?
                bne     NotSEC
                lda     #C_FLAG
                bra     DoSEP
NotSEC:
                cmp     #$c2                    ; REP?
                bne     NotREP
                lda     [ADDR_S],Y
DoREP:          trb     FLAGS
                bra     NextOpcode
NotREP:
                cmp     #$e2                    ; SEP?
                bne     NextOpcode
                lda     [ADDR_S],Y
DoSEP:          tsb     FLAGS

NextOpcode:
                pla
                jsr     OpcodeSize

                clc
                adc     ADDR_S+0                ; And move start address on
                sta     ADDR_S+0
                bcc     *+4
                inc     ADDR_S+1

                sec                             ; Exceeded the end address?
                sbc     ADDR_E+0
                lda     ADDR_S+1
                sbc     ADDR_E+1
                bmi     Disassemble             ; No, show more

                jmp     NewCommand              ; Done
NotDisassemble:

;===============================================================================
; E - Erase ROM bank
;-------------------------------------------------------------------------------

                cmp     #'E'                    ; Erase bank?
                bne     NotEraseBank

                jsr     CheckSafe

                .ifdef   W65C265SXB
                lda     BCR                     ; Save mask rom state
                pha
                lda     #$80                    ; Then ensure disabled
                tsb     BCR
                .endif

                lda     #$00                    ; Set start address
                sta     ADDR_S+0
                lda     #$80
                sta     ADDR_S+1
EraseLoop:
                lda     #$aa                    ; Unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$80                    ; Signal erase
                sta     $8000+$5555
                lda     #$aa
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$30                    ; Sector erase
                sta     (ADDR_S)

EraseWait:
                lda     (ADDR_S)                ; Wait for erase to finish
                cmp     #$FF
                bne     EraseWait

                clc                             ; Move to next sector
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     EraseLoop               ; Repeat until end of memory

                .ifdef   W65C265SXB
                pla                             ; Restore mask ROM state
                sta     BCR
                .endif

                jmp     NewCommand              ; And start over

EraseFailed:
                long_i                          ; Warn that erase failed
                ldx     #ERASE_FAILED
                jsr     TxStr
                .i8
                jmp     NewCommand              ; And start over
NotEraseBank:

;===============================================================================
; F - WDC Mask ROM Enable/Disable
;-------------------------------------------------------------------------------

                .ifdef   W65C265SXB
                cmp     #'F'
                bne     NotMaskROM

                jsr     SkipSpaces              ; Find first argument
                bcs     MaskFail                ; Success?

                cmp     #'0'                    ; Check bank is 0..3
                beq     MaskOff
                cmp     #'1'
                beq     MaskOn
MaskFail:
                jmp     ShowError

MaskOn:
                lda     #$80                    ; Enable mask ROM
                trb     BCR
                jmp     NewCommand

MaskOff:
                lda     #$80                    ; Disable mask ROM
                tsb     BCR
                jmp     NewCommand

NotMaskROM:
                .endif

;===============================================================================
; G - Goto
;-------------------------------------------------------------------------------

                cmp     #'G'                    ; Invoke code
                bne     NotGoto

                ldx     #ADDR_S                 ; Parse execution address
                jsr     GetAddr
                bcs     *+5
                jmp     [ADDR_S]                ; Run from address
                jmp     ($FFFC)                 ; Otherwise reset
NotGoto:

;===============================================================================
; H - Hunt for RAM
;-------------------------------------------------------------------------------

                cmp     #'H'                    ; Hunt for RAM
                beq     *+5
                jmp     NotHunt

                stz     ADDR_S+0                ; Start at $00:0000
                stz     ADDR_S+1
                stz     ADDR_S+2

HuntStart:
                lda     [ADDR_S]                ; Is byte is writeable?
                pha
                eor     #$ff
                sta     [ADDR_S]
                cmp     [ADDR_S]
                beq     HuntFound               ; Yes

                pla
                clc                             ; Try the next block
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     HuntStart
                inc     ADDR_S+2
                bne     HuntStart
                jmp     NewCommand              ; Reached end of RAM

HuntFound:
                jsr     TxCRLF
                lda     ADDR_S+2                ; Print start address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2

                lda     #'-'
                jsr     UartTx

HuntEnd:
                pla                             ; Restore memory bytes
                sta     [ADDR_S]
                clc                             ; Try the next block
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     HuntNext
                inc     ADDR_S+2
                beq     HuntDone

HuntNext:
                lda     [ADDR_S]                ; Is byte is writeable?
                pha
                eor     #$ff
                sta     [ADDR_S]
                cmp     [ADDR_S]
                beq     HuntEnd                 ; Yes, keep looking

                pla
                sec                             ; Print end address
                lda     ADDR_S+0
                sbc     #1
                pha
                lda     ADDR_S+1
                sbc     #0
                pha
                lda     ADDR_S+2
                sbc     #0
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                pla
                jsr     TxHex2
                pla
                jsr     TxHex2
                bra     HuntStart

HuntDone:
                lda     #$ff                    ; Pring FF:FFFF
                pha
                pha
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                pla
                jsr     TxHex2
                pla
                jsr     TxHex2
                jmp     NewCommand
NotHunt:

;===============================================================================
; M - Display Memory
;-------------------------------------------------------------------------------

                cmp     #'M'                    ; Memory display?
                bne     NotMemoryDisplay

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError
                ldx     #ADDR_E                 ; Parse end address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError

DisplayMemory:
                jsr     TxCRLF
                lda     ADDR_S+2                ; Show memory address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2

                ldy     #0                      ; Show sixteen bytes of data
ByteLoop:       jsr     TxSpace
                lda     [ADDR_S],y
                jsr     TxHex2
                iny
                cpy     #16
                bne     ByteLoop

                jsr     TxSpace
                lda     #'|'
                jsr     UartTx
                ldy     #0                      ; Show sixteen characters
CharLoop:       lda     [ADDR_S],Y
                jsr     IsPrintable
                bcs     *+4
                lda     #'.'
                jsr     UartTx
                iny
                cpy     #16
                bne     CharLoop
                lda     #'|'
                jsr     UartTx

                clc                             ; Bump the display address
                tya
                adc     ADDR_S+0
                sta     ADDR_S+0
                bcc     *+4
                inc     ADDR_S+1

                sec                             ; Exceeded the end address?
                sbc     ADDR_E+0
                lda     ADDR_S+1
                sbc     ADDR_E+1
                bmi     DisplayMemory           ; No, show more

                jmp     NewCommand
NotMemoryDisplay:

;===============================================================================
; R - Select ROM Bank
;-------------------------------------------------------------------------------

                cmp     #'R'                    ; ROM Bank?
                bne     NotROMBank              ; No

                jsr     SkipSpaces              ; Find first argument
                bcc     *+5                     ; Success?
BankFail:       jmp     ShowError               ; No

                cmp     #'0'                    ; Check bank is 0..3
                bcc     BankFail
                cmp     #'3'+1
                bcs     BankFail

                jsr     RomSelect               ; Switch ROM banks
                jmp     NewCommand              ; Done
NotROMBank:

;===============================================================================
; S - S19 Record
;-------------------------------------------------------------------------------

                cmp     #'S'                    ; S19?
                beq     *+5
                jmp     NotS19

                jsr     NextChar                ; Get record type
                bcs     S19Fail
                cmp     #'1'                    ; Only process type 1
                bne     S19Done

                ldx     #ADDR_E                 ; Get byte count
                jsr     GetByte
                bcs     S19Fail
                lda     ADDR_E                  ; Use as initial checksum
                sta     SUM
                dec     ADDR_E                  ; REMOVE!!!
                ; Byte count not included in the S19 byte count field
                beq     S19Fail

                ldx     #ADDR_S                 ; Get address
                jsr     GetAddr
                bcs     S19Fail
                lda     ADDR_S+0                ; Add to checksum
                adc     ADDR_S+1
                clc
                adc     SUM
                sta     SUM
                dec     ADDR_E
                beq     S19Fail
                dec     ADDR_E
                beq     S19Fail

S19Load:
                ldx     #TEMP                   ; Fetch a data byte
                jsr     GetByte
                bcs     S19Fail
                lda     TEMP
                adc     SUM
                sta     SUM
                dec     ADDR_E
                beq     S19Fail

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteS19                ; No
                lda     ADDR_S+1
                bpl     WriteS19                ; No

                .ifdef   W65C265SXB
                cmp     #$df                    ; Register page?
                beq     NoWrite
                .endif

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555
WriteS19:
                lda     TEMP                    ; Write the value
                sta     [ADDR_S]

NoWrite:
                inc     ADDR_S+0                ; Bump address by one
                bne     *+4
                inc     ADDR_S+1

                lda     ADDR_E                  ; Reached checksum?
                cmp     #1
                bne     S19Load

                ldx     #TEMP                   ; Yes, read it
                jsr     GetByte
                bcs     S19Fail
                lda     TEMP
                adc     SUM
                cmp     #$ff                    ; Checksum correct?
                bne     S19Fail

S19Done:        jmp     NewCommand              ; Get

S19Fail:
                long_i                          ; Display error message
                ldx     #INVALID_S19
                jsr     TxStr
                .i8
                jmp     NewCommand              ; And start over
NotS19:

;===============================================================================
; W - Write memory
;-------------------------------------------------------------------------------

                cmp     #'W'                    ; Write memory?
                bne     NotWrite

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError

                bit     ADDR_S+1                ; Load into ROM area?
                bpl     *+5
                jsr     CheckSafe               ; Yes, check selection

                ldx     #ADDR_E                 ; Parse value byte
                jsr     GetByte                 ; Is there a value?
                bcc     *+5
                jmp     NewCommand              ; No.

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteMemory             ; No
                bit     ADDR_S+1
                bpl     WriteMemory             ; No

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555
WriteMemory:
                lda     ADDR_E                  ; Write the value
                sta     [ADDR_S]

                inc     ADDR_S+0                ; Bump address by one
                bne     *+4
                inc     ADDR_S+1

                lda     #'W'                    ; Build command for next byte
                jsr     StartCommand
                lda     #' '
                jsr     BuildCommand
                lda     ADDR_S+1                ; Add the next address
                jsr     BuildByte
                lda     ADDR_S+0
                jsr     BuildByte
                lda     #' '
                jsr     BuildCommand
                jmp     ShowCommand             ; And prompt for data

NotWrite:

;===============================================================================
; X - XMODEM Receive
;-------------------------------------------------------------------------------

                cmp     #'X'                    ; XModem upload?
                beq     *+5                     ; Yes.
                jmp     NotXModem

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     *+5
                jmp     ShowError

                bit     ADDR_S+1                ; Load into ROM area?
                bpl     *+5
                jsr     CheckSafe               ; Yes, check selection

                long_i                          ; Display waiting message
                ldx     #WAITING
                jsr     TxStr
                jsr     TxCRLF
                short_i
                stz     BLOCK                   ; Reset the block number
                inc     BLOCK

ResetRetries:
                lda     #10                     ; Reset the retry counter
                sta     RETRIES

TransferWait:
                stz     TEMP+0                  ; Clear timeout counter
                stz     TEMP+1
                lda     #.lobyte(-20)
                sta     TEMP+2
TransferPoll:
                jsr     UartRxTest              ; Any data yet?
                bcs     TransferScan
                inc     TEMP+0
                bne     TransferPoll
                inc     TEMP+1
                bne     TransferPoll
                inc     TEMP+2
                bne     TransferPoll
                dec     RETRIES
                beq     TimedOut
                jsr     SendNAK                 ; Send a NAK
                bra     TransferWait

TimedOut:
                long_i
                ldx     #TIMEOUT
                jsr     TxStr
                .i8
                jmp     NewCommand

TransferScan:
                jsr     UartRx                  ; Wait for SOH or EOT
                cmp     #EOT
                beq     TransferDone
                cmp     #SOH
                bne     TransferWait
                jsr     UartRx                  ; Check the block number
                cmp     BLOCK
                bne     TransferError
                jsr     UartRx                  ; Check inverted block
                eor     #$ff
                cmp     BLOCK
                bne     TransferError

                ldy     #0
                sty     SUM                     ; Clear the check sum
TransferBlock:
                jsr     UartRx
                pha

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteByte               ; No
                lda     ADDR_S+1
                bpl     WriteByte               ; No

                .ifdef   W65C265SXB
                cmp     #$df                    ; Register page?
                beq     WriteSkip
                .endif

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555

WriteByte:
                pla
                sta     [ADDR_S],Y

WriteWait:
                cmp     [ADDR_S],Y              ; Wait for write
                bne     WriteWait
                bra     *+3

WriteSkip:
                pla

                clc                             ; Add to check sum
                adc     SUM
                sta     SUM
                iny
                cpy     #128
                bne     TransferBlock
                jsr     UartRx                  ; Check the check sum
                cmp     SUM
                bne     TransferError           ; Failed
                clc
                tya
                adc     ADDR_S+0                ; Bump address one block
                sta     ADDR_S+0
                bcc     *+4
                inc     ADDR_S+1

                jsr     SendACK                 ; Acknowledge block
                inc     BLOCK                   ; Bump block number
                jmp     TransferWait

TransferError:
                jsr     SendNAK                 ; Send a NAK
                jmp     TransferWait            ; And try again

TransferDone:
                jsr     SendACK                 ; Acknowledge transmission
                jmp     NewCommand              ; Done

SendACK:
                lda     #ACK
                jmp     UartTx

SendNAK:
                lda     #NAK
                jmp     UartTx

NotXModem:

;===============================================================================
; ? - Help
;-------------------------------------------------------------------------------

                cmp     #'?'                    ; Help command?
                bne     NotHelp

                long_i
                ldx     #HELP                   ; Output help string
                jsr     TxStr
                .i8
                jmp     NewCommand
NotHelp:

;-------------------------------------------------------------------------------

ShowError:
                long_i
                ldx     #ERROR                  ; Output error message
                jsr     TxStr
                .i8
                jmp     NewCommand

;===============================================================================
;-------------------------------------------------------------------------------

; Checks if an expendable ROM bank is currently selected. If the bank with the
; WDC firmware is selected then warn and accept a new command.

CheckSafe:
                jsr     RomCheck                ; WDC ROM selected?
                beq     *+3
                rts                             ; No, save to change

                pla                             ; Discard return address
                pla
                long_i                          ; Complain about bank
                ldx     #NOT_SAFE
                jsr     TxStr
                .i8
                jmp     NewCommand              ; And start over

;===============================================================================
; Byte and Word Parsing
;-------------------------------------------------------------------------------

; Parse a hex byte from the command line and store it at the location indicated
; by the X register.

GetByte:
                stz     a:0,x                   ; REMOVE a: Set the target address
                jsr     SkipSpaces              ; Skip to first real character
                bcc     *+3
                rts                             ; None found
                jsr     IsHexDigit              ; Must have at least one digit
                bcc     ByteFail
                jsr     AddDigit
                jsr     NextChar
                bcs     ByteDone
                jsr     IsHexDigit
                bcc     ByteDone
                jsr     AddDigit
ByteDone:       clc
                rts
ByteFail:       sec
                rts

; Parse an address from the command line and store it at the location indicated
; by the X register.

GetAddr:
                stz     a:0,x                   ; REMOVE a: Set the target address
                stz     a:1,x                   ; REMOVE a: 
                lda     BANK
                sta     a:2,x                   ; REMOVE a: 
                jsr     SkipSpaces              ; Skip to first real character
                bcc     *+3
                rts                             ; None found

                jsr     IsHexDigit              ; Must have at least one digit
                bcc     AddrFail
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
AddrDone:       clc                             ; Carry clear got an address
                rts
AddrFail:       sec                             ; Carry set -- failed.
                rts

; Add a hex digit to the 16-bit value being build at at the location indicated
; by X.

AddDigit:
                sec                             ; Convert ASCII to binary
                sbc     #'0'
                cmp     #$0a
                bcc     *+4
                sbc     #7

                asl     a:0,x                     ; Shift up one nybble
                rol     a:1,x
                asl     a:0,x
                rol     a:1,x
                asl     a:0,x
                rol     a:1,x
                asl     a:0,x
                rol     a:1,x

                ora     a:0,x                     ; Merge in new digit
                sta     a:0,x                     ; .. and save
                rts

;===============================================================================
; Command Line Parsing and Building
;-------------------------------------------------------------------------------

; Get the next character from the command buffer updating the position in X.
; Set the carry if the end of the buffer is reached.

NextChar:
                cpy     BUFLEN                  ; Any characters left?
                bcc     *+3
                rts
                lda     BUFFER,y
                iny
                jmp     ToUpperCase

; Skip over any spaces until a non-space character or the end of the string
; is reached.

SkipSpaces:
                jsr     NextChar                ; Fetch next character
                bcc     *+3                     ; Any left?
                rts                             ; No
                cmp     #' '                    ; Is it a space?
                beq     SkipSpaces              ; Yes, try again
                clc
                rts                             ; Done

; Clear the buffer and the add the command character in A.

StartCommand:
                stz     BUFLEN                  ; Clear the character count

; Append the character in A to the command being built updating the length.

BuildCommand:
                ldy     BUFLEN
                inc     BUFLEN
                sta     BUFFER,y
                rts

; Convert the value in A into hex characters and append to the command buffer.

BuildByte:
                pha                             ; Save the value
                lsr     a                       ; Shift MS nybble down
                lsr     a
                lsr     a
                lsr     a
                jsr     HexToAscii              ; Convert to ASCII
                jsr     BuildCommand            ; .. and add to command
                pla                             ; Pull LS nybble
                jsr     HexToAscii              ; Convert to ASCII
                jmp     BuildCommand            ; .. and add to command

;===============================================================================
; Character Classification
;-------------------------------------------------------------------------------

; If the character in MD_ACC is lower case then convert it to upper case.

ToUpperCase:
                jsr     IsLowerCase             ; Test the character
                bcc     *+4
                sbc     #32                     ; Convert lower case
                clc
                rts                             ; Done

; Determine if the character in MD_ACC is a lower case letter. Set the carry if it
; is, otherwise clear it.

                .a8
IsLowerCase:
                cmp     #'a'                    ; Between a and z?
                bcc     ClearCarry
                cmp     #'z'+1
                bcs     ClearCarry
SetCarry:       sec
                rts
ClearCarry:     clc
                rts

; Determine if the character in MD_ACC is a hex character. Set the carry if it is,
; otherwise clear it.

                .a8
IsHexDigit:
                cmp     #'0'                    ; Between 0 and 9?
                bcc     ClearCarry
                cmp     #'9'+1
                bcc     SetCarry
                cmp     #'A'                    ; Between MD_ACC and F?
                bcc     ClearCarry
                cmp     #'F'+1
                bcc     SetCarry
                bra     ClearCarry

; Determine if the character in MD_ACC is a printable character. Set the carry if it
; is, otherwise clear it.

                .a8
IsPrintable:
                cmp     #' '
                bcc     ClearCarry
                cmp     #DEL
                bcc     SetCarry
                bra     ClearCarry

;===============================================================================
; Display Utilities
;-------------------------------------------------------------------------------

; Display the value in MD_ACC as two hexadecimal digits.

TxHex2:
                pha                             ; Save the original byte
                lsr     a                       ; Shift down hi nybble
                lsr     a
                lsr     a
                lsr     a
                jsr     UartHex                 ; Display
                pla                             ; Recover data byte

; Display the LSB of the value in MD_ACC as a hexadecimal digit using decimal
; arithmetic to do the conversion.

UartHex:
                jsr     HexToAscii              ; Convert to ASCII
                jmp     UartTx                  ; And display

; Convert a LSB of the value in MD_ACC to a hexadecimal digit using decimal
; arithmetic.

HexToAscii:
                and     #$0f                    ; Strip out lo nybble
                sed                             ; Convert to ASCII
                clc
                adc     #$90
                adc     #$40
                cld
                rts                             ; Done

; Display the string of characters starting a the memory location pointed to by
; X (16-bits).

                .a8
                .i16
TxStr:
                lda     a:0,x                     ; Fetch the next character
                bne     *+3                     ; Return it end of string
                rts
                jsr     UartTx                  ; Otherwise print it
                inx                             ; Bump the pointer
                bra     TxStr                   ; And repeat

; Display a CR/LF control character s=ence.

TxCRLF:
                jsr     TxCR                    ; Transmit a CR
                lda     #LF                     ; Followed by a LF
                jmp     UartTx

TxCR:
                lda     #CR                     ; Transmit a CR
                jmp     UartTx

TxSpace:
                lda     #' '                    ; Transmit a space
                jmp     UartTx

;===============================================================================
;-------------------------------------------------------------------------------

;

                .a8
                .i8
TxCodeBytes:
                lda     [ADDR_S]                ; Fetch the opcode
                jsr     OpcodeSize              ; and work out its size
                tax
                ldy     #0                      ; Clear byte count
CodeLoop:
                lda     [ADDR_S],Y              ; Fetch a byte of code
                jsr     TxHex2
                jsr     TxSpace
                iny
                dex
                bne     CodeLoop
PadLoop:
                cpy     #4                      ; Need to pad out?
                bne     *+3
                rts
                jsr     TxSpace
                jsr     TxSpace
                jsr     TxSpace
                iny
                bra     PadLoop

;

                .a8
                .i8
TxSymbolic:
                lda     [ADDR_S]                ; Fetch opcode
                pha
                jsr     TxOpcode
                pla
                jsr     TxOperand
                rts

;

                .a8
                .i8
TxOpcode:
                php                             ; Save register sizes
                tax                             ; Work out the mnemonic
                lda     OPCODES,x
                tax
                long_a
                lda     MNEMONICS,x

                pha                             ; Save last character
                lsr     a                       ; Shift second down
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                pha                             ; Save it
                lsr     a                       ; Shift first down
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                jsr     ExpandMnem              ; Print first
                pla
                jsr     ExpandMnem              ; .. second
                pla
                jsr     ExpandMnem              ; .. and third
                plp
                jsr     TxSpace
                rts

ExpandMnem:
                clc
                and     #$1f                    ; Expand letter code
                adc     #'@'
                jmp     UartTx

;

                .a8
                .i8
TxOperand:
                tax                             ; Work out addressing mode
                lda     MODES,x
                tax
                jmp     (MODE_SHOW,x)

MODE_SHOW:
                .word     TxAbsolute              ; a
                .word     TxAccumulator           ; A
                .word     TxAbsoluteX             ; a,x
                .word     TxAbsoluteY             ; a,y
                .word     TxLong                  ; al
                .word     TxLongX                 ; al,x
                .word     TxAbsoluteIndirect      ; (a)
                .word     TxAbsoluteXIndirect     ; (a,x)
                .word     TxDirect                ; d
                .word     TxStack                 ; d,s
                .word     TxDirectX               ; d,x
                .word     TxDirectY               ; d,y
                .word     TxDirectIndirect        ; (d)
                .word     TxDirectIndirectLong    ; [d]
                .word     TxStackIndirectY        ; (d,s),y
                .word     TxDirectXIndirect       ; (d,x)
                .word     TxDirectIndirectY       ; (d),y
                .word     TxDirectIndirectLongY   ; [d],y
                .word     TxImplied               ;
                .word     TxRelative              ; r
                .word     TxRelativeLong          ; rl
                .word     TxMove                  ; xyc
                .word     TxImmediateM            ; # (A & M)
                .word     TxImmediateByte         ; # (BRK/COP/WDM)
                .word     TxImmediateX            ; # (X or Y)


TxAccumulator:
                lda     #'A'
                jmp     UartTx

TxImmediateM:
                lda     #M_FLAG
                bit     FLAGS
                beq     TxImmediateWord
                bra     TxImmediateByte

TxImmediateX:
                lda     #X_FLAG
                bit     FLAGS
                beq     TxImmediateWord
                bra     TxImmediateByte

TxImplied:
                rts

TxMove:
                lda     #'$'
                jsr     UartTx
                ldy     #1
                lda     [ADDR_S],Y
                jsr     TxHex2
                lda     #','
                jsr     UartTx
                lda     #'$'
                jsr     UartTx
                iny
                lda     [ADDR_S],Y
                jmp     TxHex2

TxImmediateByte:
                lda     #'#'
                jsr     UartTx
                bra     TxDirect

TxImmediateWord:
                lda     #'#'
                jsr     UartTx
                bra     TxAbsolute

TxStack:
                jsr     TxDirect
                lda     #','
                jsr     UartTx
                lda     #'S'
                jmp     UartTx

TxDirect:
                lda     #'$'
                jsr     UartTx
                ldy     #1
                lda     [ADDR_S],Y
                jmp     TxHex2

TxDirectX:
                jsr     TxDirect
TxX:            lda     #','
                jsr     UartTx
                lda     #'X'
                jmp     UartTx

TxDirectY:
                jsr     TxDirect
TxY_:           lda     #','
                jsr     UartTx
                lda     #'Y'
                jmp     UartTx

TxAbsolute:
                lda     #'$'
                jsr     UartTx
                ldy     #2
                lda     [ADDR_S],Y
                jsr     TxHex2
                dey
                lda     [ADDR_S],Y
                jmp     TxHex2

TxAbsoluteX:
                jsr     TxAbsolute
                bra     TxX

TxAbsoluteY:
                jsr     TxAbsolute
                bra     TxY_

TxLong:
                lda     #'$'
                jsr     UartTx
                ldy     #3
                lda     [ADDR_S],Y
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                dey
                lda     [ADDR_S],Y
                jsr     TxHex2
                dey
                lda     [ADDR_S],Y
                jmp     TxHex2

TxLongX:
                jsr     TxLong
                bra     TxX

TxAbsoluteIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxAbsolute
                lda     #')'
                jmp     UartTx

TxAbsoluteXIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxAbsoluteX
                lda     #')'
                jmp     UartTx

TxDirectIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxDirect
                lda     #')'
                jmp     UartTx

TxDirectXIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxDirectX
                lda     #')'
                jmp     UartTx

TxDirectIndirectY:
                lda     #'('
                jsr     UartTx
                jsr     TxDirect
                lda     #')'
                jsr     UartTx
                jmp     TxY_

TxDirectIndirectLong:
                lda     #'['
                jsr     UartTx
                jsr     TxDirect
                lda     #']'
                jmp     UartTx

TxDirectIndirectLongY:
                jsr     TxDirectIndirectLong
                jmp     TxY_

TxStackIndirectY:
                lda     #'('
                jsr     UartTx
                jsr     TxStack
                lda     #')'
                jsr     UartTx
                jmp     TxY_

TxRelative:
                ldx     ADDR_S+1                ; Work out next PC
                lda     ADDR_S+0
                clc
                adc     #2
                bcc     *+3
                inx

                pha                             ; Add relative offset
                ldy     #1
                lda     [ADDR_S],y
                bpl     *+3
                dex
                clc
                adc     1,s
                sta     1,s
                bcc     *+3
                inx
                bra     TxAddr

TxRelativeLong:
                ldx     ADDR_S+1                ; Work out next PC
                lda     ADDR_S+0
                clc
                adc     #3
                bcc     *+3
                inx

                clc                             ; Add relative offset
                ldy     #1
                adc     [ADDR_S],y
                pha
                iny
                txa
                adc     [ADDR_S],Y
                tax

TxAddr:
                lda     #'$'                    ; Print address
                jsr     UartTx
                txa
                jsr     TxHex2
                pla
                jmp     TxHex2

;  Returns the size of the opcode in A given the current flag settings.

                .a8
                .i8
OpcodeSize:
                tax                             ; Work out addressing mode
                lda     MODES,x
                tax
                jmp     (MODE_SIZE,x)

MODE_SIZE:
                .word     Size3                   ; a
                .word     Size1                   ; A
                .word     Size3                   ; a,x
                .word     Size3                   ; a,y
                .word     Size4                   ; al
                .word     Size4                   ; al,x
                .word     Size3                   ; (a)
                .word     Size3                   ; (a,x)
                .word     Size2                   ; d
                .word     Size2                   ; d,s
                .word     Size2                   ; d,x
                .word     Size2                   ; d,y
                .word     Size2                   ; (d)
                .word     Size2                   ; [d]
                .word     Size2                   ; (d,s),y
                .word     Size2                   ; (d,x)
                .word     Size2                   ; (d),y
                .word     Size2                   ; [d],y
                .word     Size1                   ;
                .word     Size2                   ; r
                .word     Size3                   ; rl
                .word     Size3                   ; xyc
                .word     TestM                   ; # (A & M)
                .word     Size2                   ; # (BRK/COP/WDM)
                .word     TestX                   ; # (X or Y)

TestM:
                lda     #M_FLAG                 ; Is M bit set?
                and     FLAGS
                beq     Size3                   ; No, word
                bra     Size2                   ; else byte

TestX:
                lda     #X_FLAG                 ; Is X bit set?
                and     FLAGS
                beq     Size3                   ; No, word
                bra     Size2                   ; else byte

Size1:          lda     #1
                rts
Size2:          lda     #2
                rts
Size3:          lda     #3
                rts
Size4:          lda     #4
                rts

OPCODES:
                .byte      OP_BRK,OP_ORA,OP_COP,OP_ORA     ; 00
                .byte      OP_TSB,OP_ORA,OP_ASL,OP_ORA
                .byte      OP_PHP,OP_ORA,OP_ASL,OP_PHD
                .byte      OP_TSB,OP_ORA,OP_ASL,OP_ORA
                .byte      OP_BPL,OP_ORA,OP_ORA,OP_ORA     ; 10
                .byte      OP_TRB,OP_ORA,OP_ASL,OP_ORA
                .byte      OP_CLC,OP_ORA,OP_INC,OP_TCS
                .byte      OP_TRB,OP_ORA,OP_ASL,OP_ORA
                .byte      OP_JSR,OP_AND,OP_JSL,OP_AND     ; 20
                .byte      OP_BIT,OP_AND,OP_ROL,OP_AND
                .byte      OP_PLP,OP_AND,OP_ROL,OP_PLD
                .byte      OP_BIT,OP_AND,OP_ROL,OP_AND
                .byte      OP_BMI,OP_AND,OP_AND,OP_AND     ; 30
                .byte      OP_BIT,OP_AND,OP_ROL,OP_AND
                .byte      OP_SEC,OP_AND,OP_DEC,OP_TSC
                .byte      OP_BIT,OP_AND,OP_ROL,OP_AND
                .byte      OP_RTI,OP_EOR,OP_WDM,OP_EOR     ; 40
                .byte      OP_MVP,OP_EOR,OP_LSR,OP_EOR
                .byte      OP_PHA,OP_EOR,OP_LSR,OP_PHK
                .byte      OP_JMP,OP_EOR,OP_LSR,OP_EOR
                .byte      OP_BVC,OP_EOR,OP_EOR,OP_EOR     ; 50
                .byte      OP_MVN,OP_EOR,OP_LSR,OP_EOR
                .byte      OP_CLI,OP_EOR,OP_PHY,OP_TCD
                .byte      OP_JMP,OP_EOR,OP_LSR,OP_EOR
                .byte      OP_RTS,OP_ADC,OP_PER,OP_ADC     ; 60
                .byte      OP_STZ,OP_ADC,OP_ROR,OP_ADC
                .byte      OP_PLA,OP_ADC,OP_ROR,OP_RTL
                .byte      OP_JMP,OP_ADC,OP_ROR,OP_ADC
                .byte      OP_BVS,OP_ADC,OP_ADC,OP_ADC     ; 70
                .byte      OP_STZ,OP_ADC,OP_ROR,OP_ADC
                .byte      OP_SEI,OP_ADC,OP_PLY,OP_TDC
                .byte      OP_JMP,OP_ADC,OP_ROR,OP_ADC
                .byte      OP_BRA,OP_STA,OP_BRL,OP_STA     ; 80
                .byte      OP_STY,OP_STA,OP_STX,OP_STA
                .byte      OP_DEY,OP_BIT,OP_TXA,OP_PHB
                .byte      OP_STY,OP_STA,OP_STX,OP_STA
                .byte      OP_BCC,OP_STA,OP_STA,OP_STA     ; 90
                .byte      OP_STY,OP_STA,OP_STX,OP_STA
                .byte      OP_TYA,OP_STA,OP_TXS,OP_TXY
                .byte      OP_STZ,OP_STA,OP_STZ,OP_STA
                .byte      OP_LDY,OP_LDA,OP_LDX,OP_LDA     ; A0
                .byte      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                .byte      OP_TAY,OP_LDA,OP_TAX,OP_PLB
                .byte      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                .byte      OP_BCS,OP_LDA,OP_LDA,OP_LDA     ; B0
                .byte      OP_LDA,OP_LDY,OP_LDX,OP_LDA
                .byte      OP_CLV,OP_LDA,OP_TSX,OP_TYX
                .byte      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                .byte      OP_CPY,OP_CMP,OP_REP,OP_CMP     ; C0
                .byte      OP_CPY,OP_CMP,OP_DEC,OP_CMP
                .byte      OP_INY,OP_CMP,OP_DEX,OP_WAI
                .byte      OP_CPY,OP_CMP,OP_DEC,OP_CMP
                .byte      OP_BNE,OP_CMP,OP_CMP,OP_CMP     ; D0
                .byte      OP_PEI,OP_CMP,OP_DEC,OP_CMP
                .byte      OP_CLD,OP_CMP,OP_PHX,OP_STP
                .byte      OP_JML,OP_CMP,OP_DEC,OP_CMP
                .byte      OP_CPX,OP_SBC,OP_SEP,OP_SBC     ; E0
                .byte      OP_CPX,OP_SBC,OP_INC,OP_SBC
                .byte      OP_INX,OP_SBC,OP_NOP,OP_XBA
                .byte      OP_CPX,OP_SBC,OP_INC,OP_SBC
                .byte      OP_BEQ,OP_SBC,OP_SBC,OP_SBC     ; F0
                .byte      OP_PEA,OP_SBC,OP_INC,OP_SBC
                .byte      OP_SED,OP_SBC,OP_PLX,OP_XCE
                .byte      OP_JSR,OP_SBC,OP_INC,OP_SBC

MODES:
                .byte      MD_INT,MD_DIX,MD_INT,MD_STK     ; 00
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 10
                .byte      MD_DPG,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_ACC,MD_IMP
                .byte      MD_ABS,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_ABS,MD_DIX,MD_ALG,MD_STK     ; 20
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 30
                .byte      MD_DPX,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_ACC,MD_IMP
                .byte      MD_ABX,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_IMP,MD_DIX,MD_INT,MD_STK     ; 40
                .byte      MD_MOV,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 50
                .byte      MD_MOV,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_ALG,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_IMP,MD_DIX,MD_IMP,MD_STK     ; 60
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                .byte      MD_AIN,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 70
                .byte      MD_DPX,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_AIX,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_REL,MD_DIX,MD_RLG,MD_STK     ; 80
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 90
                .byte      MD_DPX,MD_DPX,MD_DPY,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_ABS,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_IMX,MD_DIX,MD_IMX,MD_STK     ; A0
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; B0
                .byte      MD_DPX,MD_DPX,MD_DPY,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_ABX,MD_ABX,MD_ABY,MD_ALX
                .byte      MD_IMX,MD_DIX,MD_INT,MD_STK     ; C0
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; D0
                .byte      MD_IMP,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_AIN,MD_ABX,MD_ABX,MD_ALX
                .byte      MD_IMX,MD_DIX,MD_INT,MD_STK     ; E0
                .byte      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                .byte      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                .byte      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                .byte      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; F0
                .byte      MD_IMP,MD_DPX,MD_DPX,MD_DLY
                .byte      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                .byte      MD_AIX,MD_ABX,MD_ABX,MD_ALX

MNEMONICS:
                MNEM    'A','D','C'
                MNEM    'A','N','D'
                MNEM    'A','S','L'
                MNEM    'B','C','C'
                MNEM    'B','C','S'
                MNEM    'B','E','Q'
                MNEM    'B','I','T'
                MNEM    'B','M','I'
                MNEM    'B','N','E'
                MNEM    'B','P','L'
                MNEM    'B','R','A'
                MNEM    'B','R','K'
                MNEM    'B','R','L'
                MNEM    'B','V','C'
                MNEM    'B','V','S'
                MNEM    'C','L','C'
                MNEM    'C','L','D'
                MNEM    'C','L','I'
                MNEM    'C','L','V'
                MNEM    'C','M','P'
                MNEM    'C','O','P'
                MNEM    'C','P','X'
                MNEM    'C','P','Y'
                MNEM    'D','E','C'
                MNEM    'D','E','X'
                MNEM    'D','E','Y'
                MNEM    'E','O','R'
                MNEM    'I','N','C'
                MNEM    'I','N','X'
                MNEM    'I','N','Y'
                MNEM    'J','M','L'
                MNEM    'J','M','P'
                MNEM    'J','S','L'
                MNEM    'J','S','R'
                MNEM    'L','D','A'
                MNEM    'L','D','X'
                MNEM    'L','D','Y'
                MNEM    'L','S','R'
                MNEM    'M','V','N'
                MNEM    'M','V','P'
                MNEM    'N','O','P'
                MNEM    'O','R','A'
                MNEM    'P','E','A'
                MNEM    'P','E','I'
                MNEM    'P','E','R'
                MNEM    'P','H','A'
                MNEM    'P','H','B'
                MNEM    'P','H','D'
                MNEM    'P','H','K'
                MNEM    'P','H','P'
                MNEM    'P','H','X'
                MNEM    'P','H','Y'
                MNEM    'P','L','A'
                MNEM    'P','L','B'
                MNEM    'P','L','D'
                MNEM    'P','L','P'
                MNEM    'P','L','X'
                MNEM    'P','L','Y'
                MNEM    'R','E','P'
                MNEM    'R','O','L'
                MNEM    'R','O','R'
                MNEM    'R','T','I'
                MNEM    'R','T','L'
                MNEM    'R','T','S'
                MNEM    'S','B','C'
                MNEM    'S','E','C'
                MNEM    'S','E','D'
                MNEM    'S','E','I'
                MNEM    'S','E','P'
                MNEM    'S','T','A'
                MNEM    'S','T','P'
                MNEM    'S','T','X'
                MNEM    'S','T','Y'
                MNEM    'S','T','Z'
                MNEM    'T','A','X'
                MNEM    'T','A','Y'
                MNEM    'T','C','D'
                MNEM    'T','C','S'
                MNEM    'T','D','C'
                MNEM    'T','R','B'
                MNEM    'T','S','B'
                MNEM    'T','S','C'
                MNEM    'T','S','X'
                MNEM    'T','X','A'
                MNEM    'T','X','S'
                MNEM    'T','X','Y'
                MNEM    'T','Y','A'
                MNEM    'T','Y','X'
                MNEM    'W','A','I'
                MNEM    'W','D','M'
                MNEM    'X','B','A'
                MNEM    'X','C','E'

;===============================================================================
; String Literals
;-------------------------------------------------------------------------------

TITLE:          .byte      CR,LF
                .ifdef   W65C265SXB
                .byte      "W65C265SXB"
                .else
                .byte      "W65C816SXB"
                .endif
                .byte      "-Hacker [18.06]",0

ERROR:          .byte      CR,LF,"Error - Type ? for help",0

ERASE_FAILED:   .byte      CR,LF,"Erase failed",0
WRITE_FAILED:   .byte      CR,LF,"Write failed",0
NOT_SAFE:       .byte      CR,LF,"WDC ROM Bank Selected",0
INVALID_S19:    .byte      CR,LF,"Invalid S19 record",0

WAITING:        .byte      CR,LF,"Waiting for XMODEM transfer to start",0
TIMEOUT:        .byte      CR,LF,"Timeout",0

HELP:           .byte      CR,LF,"B bb           - Set memory bank"
                .byte      CR,LF,"D ssss eeee    - Disassemble memory in current bank"
                .byte      CR,LF,"E              - Erase ROM area"
                .ifdef   W65C265SXB
                .byte      CR,LF,"F 0-1          - Disable/Enable WDC ROM"
                .byte      CR,LF,"H              - Hunt for RAM"
                .endif
                .byte      CR,LF,"G [xxxx]       - Run from bb:xxxx or invoke reset vector"
                .byte      CR,LF,"M ssss eeee    - Display memory in current bank"
                .byte      CR,LF,"R 0-3          - Select ROM bank 0-3"
                .byte      CR,LF,"S...           - Process S19 record"
                .byte      CR,LF,"W xxxx yy      - Set memory at xxxx to yy"
                .byte      CR,LF,"X xxxx         - XMODEM receive to bb:xxxx"
                .byte      0

                .end