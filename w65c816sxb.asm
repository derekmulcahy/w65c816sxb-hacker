;===============================================================================
; __        ____  ____   ____ ___  _  __  ______  ______
; \ \      / / /_| ___| / ___( _ )/ |/ /_/ ___\ \/ / __ )
;  \ \ /\ / / '_ \___ \| |   / _ \| | '_ \___ \\  /|  _ \
;   \ V  V /| (_) |__) | |__| (_) | | (_) |__) /  \| |_) |
;    \_/\_/  \___/____/ \____\___/|_|\___/____/_/\_\____/
;
; Basic Vector Handling for the W65C816SXB Development Board
;-------------------------------------------------------------------------------
; Copyright (C)2015 HandCoded Software Ltd.
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
; Timer2 in the VIA2 is used to time the ACIA transmissions and determine when
; the device is capable of sending another character.
;
;-------------------------------------------------------------------------------

                .list on
                .p816

                .include "w65c816.inc"
                .include "w65c816sxb.inc"

;===============================================================================
; Configuration
;-------------------------------------------------------------------------------

; USE_FIFO        =     0                     ; Build using USB FIFO as UART

                .if !USE_FIFO                 ; Need to configure ACIA when
                                              ; USB FIFO is not enabled.

BAUD_RATE       =     19200                   ; ACIA baud rate

;-------------------------------------------------------------------------------

TXD_COUNT       =     OSC_FREQ/(BAUD_RATE/11)

                .if      TXD_COUNT&$ffff0000
                messg   "TXD_DELAY does not fit in 16-bits"
                .endif

                .endif

;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------

                .segment "CODE"

                .import  Start
                .i8
                .a8
RESET:
                sei                             ; Stop interrupts
                ldx     #$ff                    ; Reset the stack
                txs

                lda     VIA1_IER                ; Ensure no via interrupts
                sta     VIA1_IER
                lda     VIA2_IER
                sta     VIA2_IER

                .if      USE_FIFO
                lda     #$1c                    ; Configure VIA for USB FIFO
                sta     VIA2_DDRB
                lda     #$18
                sta     VIA2_ORB
                .else
                stz     ACIA_CMD                ; Configure ACIA
                stz     ACIA_CTL
                stz     ACIA_SR

                lda     #%00011111              ; 8 bits, 1 stop bit, 19200 baud
                sta     ACIA_CTL
                lda     #%11001001              ; No parity, no interrupt
                sta     ACIA_CMD
                lda     ACIA_RXD                ; Clear receive buffer

                lda     #1<<5                   ; Put VIA2 T2 into timed mode
                trb     VIA2_ACR
                jsr     TxDelay                 ; And prime the timer
                .endif

                native                          ; Switch to native mode
                jmp     Start                   ; Jump to the application start

;===============================================================================
; Interrupt Handlers
;-------------------------------------------------------------------------------

; Handle IRQ and BRK interrupts in emulation mode.

IRQBRK:
                bra     *                       ; Loop forever

; Handle NMI interrupts in emulation mode.

NMIRQ:
                bra     *                       ; Loop forever

;-------------------------------------------------------------------------------

; Handle IRQ interrupts in native mode.

IRQ:
                bra     *                       ; Loop forever

; Handle IRQ interrupts in native mode.

BRK_:
                bra     *                       ; Loop forever

; Handle IRQ interrupts in native mode.

NMI:
                bra     *                       ; Loop forever

;-------------------------------------------------------------------------------

; COP and ABORT interrupts are not handled.

COP_:
                bra     *                       ; Loop forever

ABORT:
                bra     *                       ; Loop forever

;===============================================================================
; USB FIFO Interface
;-------------------------------------------------------------------------------

                .if      USE_FIFO

; Add the character in A to the FTDI USB FIFO transmit buffer. If the buffer
; is full wait for space to become available.

                .export  UartTx
UartTx:
                phx
                php
                short_ai
                ldx     #$00                    ; Make data port all input
                stx     VIA2_DDRA
                sta     VIA2_ORA                ; Save the output character
                lda     #%01
TxWait:         bit     VIA2_IRB                ; Is there space for more data
                bne     TxWait

                lda     VIA2_IRB                ; Strobe WR
                and     #$fb
                tax
                ora     #$04
                sta     VIA2_ORB
                lda     #$ff                    ; Make data port all output
                sta     VIA2_DDRA
                nop
                nop
                stx     VIA2_ORB                ; End strobe
                lda     VIA2_IRA
                ldx     #$00                    ; Make data port all output
                stx     VIA2_DDRA
                plp
                plx
                rts

; Read a character from the FTDI USB FIFO and return it in A. If no data is
; available then wait for some to arrive.

                .export  UartRx
UartRx:
                phx                             ; Save callers X
                php                             ; Save register sizes
                short_ai                        ; Make registers 8-bit
                lda     #$02                    ; Wait until data in buffer
RxWait:         bit     VIA2_IRB
                bne     RxWait

                lda     VIA2_IRB                ; Strobe /RD low
                ora     #$08
                tax
                and     #$f7
                sta     VIA2_ORB
                nop                             ; Wait for data to be available
                nop
                nop
                nop
                lda     VIA2_IRA                ; Read it
                stx     VIA2_ORB                ; And end the strobe
                plp                             ; Restore register sizes
                plx                             ; .. and callers X
                rts                             ; Done

; Check if the receive buffer in the FIFO contains any data and return C=1 if
; there is some.

                .export  UartRxTest
UartRxTest:
                pha                             ; Save callers A
                php                             ; Save register sizes
                short_a                         ; Make A 8-bits
                lda     VIA2_IRB                ; Load status bits
                plp                             ; Restore register sizes
                ror     a                       ; Shift data available flag
                ror     a                       ; .. into carry
                pla                             ; Restore A
                rts                             ; Done

;===============================================================================
; ACIA Interface
;-------------------------------------------------------------------------------

                .else

; Wait until the Timer2 in VIA2 indicates that the last transmission has been
; completed then send the character in A and restart the timer.

                .export  UartTx
UartTx:
                pha                             ; Save the character
                php                             ; Save register sizes
                short_a                         ; Make A 8-bits
                pha
                lda     #1<<5
TxWait:         bit     VIA2_IFR                ; Has the timer finished?
                beq     TxWait
                jsr     TxDelay                 ; Yes, re-reload the timer
                pla
                sta     ACIA_TXD                ; Transmit the character
                plp                             ; Restore register sizes
                pla                             ; And callers A
                rts                             ; Done

TxDelay:
                lda     #<TXD_COUNT             ; Load VIA T2 with transmit
                sta     VIA2_T2CL               ; .. delay time
                lda     #>TXD_COUNT
                sta     VIA2_T2CH
                rts

; Fetch the next character from the receive buffer waiting for some to arrive
; if the buffer is empty.

                .export  UartRx
UartRx:
                php                             ; Save register sizes
                short_a                         ; Make A 8-bits
RxWait:
                lda     ACIA_SR                 ; Any data in RX buffer?
                and     #$08
                beq     RxWait                  ; No
                lda     ACIA_RXD                ; Yes, read it
                plp                             ; Restore register sizes
                rts                             ; Done

; Check if the receive buffer contains any data and return C=1 if there is
; some.

                .export  UartRxTest
UartRxTest:
                pha                             ; Save callers A
                php
                short_a
                lda     ACIA_SR                 ; Read the status register
                plp
                ror     a                       ; Shift RDRF bit into carry
                ror     a
                ror     a
                ror     a
                pla                             ; Restore A
                rts                             ; Done

                .endif

;===============================================================================
; ROM Bank Selection
;-------------------------------------------------------------------------------

; Select the flash ROM bank indicated by the two low order bits of A. The pins
; should be set to inputs when a hi bit is needed and a low output for a lo bit.

                .export RomSelect
RomSelect:
                php				; Ensure 8-bit A
                short_a
		ror	a			; Shift out bit 0
		php				; .. and save
		ror	a			; Shift out bit 1
		lda	#0			; Work out pattern
		bcs	*+4
		ora	#%11000000
		plp
		bcs	*+4
		ora	#%00001100
		sta	VIA2_PCR		; And set
		plp		
                rts                             ; Done

; Check if the select ROM bank contains WDC firmware. If it does return with
; the Z flag set.

                .export RomCheck
RomCheck:
		lda	VIA2_PCR		; WDC ROM selected?
		and	#%11001100
                rts

;===============================================================================
; Reset Vectors
;-------------------------------------------------------------------------------

                .segment "SHADOW"

; ShadowVectors   section offset $7ee0

                .res       4                       ; Reserved
                .word      COP_                    ; $FFE4 - COP(816)
                .word      BRK_                    ; $FFE6 - BRK(816)
                .word      ABORT                   ; $FFE8 - ABORT(816)
                .word      NMI                     ; $FFEA - NMI(816)
                .res       2                       ; Reserved
                .word      IRQ                     ; $FFEE - IRQ(816)

                .res       4
                .word      COP_                    ; $FFF4 - COP(C02)
                .res       2                       ; $Reserved
                .word      ABORT                   ; $FFF8 - ABORT(C02)
                .word      NMIRQ                   ; $FFFA - NMI(C02)
                .word      RESET                   ; $FFFC - RESET(C02)
                .word      IRQBRK                  ; $FFFE - IRQBRK(C02)

                ; ends

;------------------------------------------------------------------------------

;                 .segment "VECTORS"

; ; Vectors         section offset $ffe0

;                 .res       4                       ; Reserved
;                 .word      COP_                    ; $FFE4 - COP(816)
;                 .word      BRK_                    ; $FFE6 - BRK(816)
;                 .word      ABORT                   ; $FFE8 - ABORT(816)
;                 .word      NMI                     ; $FFEA - NMI(816)
;                 .res       2                       ; Reserved
;                 .word      IRQ                     ; $FFEE - IRQ(816)

;                 .res       4
;                 .word      COP_                    ; $FFF4 - COP(C02)
;                 .res       2                       ; $Reserved
;                 .word      ABORT                   ; $FFF8 - ABORT(C02)
;                 .word      NMIRQ                   ; $FFFA - NMI(C02)
;                 .word      RESET                   ; $FFFC - RESET(C02)
;                 .word      IRQBRK                  ; $FFFE - IRQBRK(C02)

                .end