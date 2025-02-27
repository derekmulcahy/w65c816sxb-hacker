;==============================================================================
; __        ____  ____   ____ ___  _  __  ______  ______
; \ \      / / /_| ___| / ___( _ )/ |/ /_/ ___\ \/ / __ )
;  \ \ /\ / / '_ \___ \| |   / _ \| | '_ \___ \\  /|  _ \
;   \ V  V /| (_) |__) | |__| (_) | | (_) |__) /  \| |_) |
;    \_/\_/  \___/____/ \____\___/|_|\___/____/_/\_\____/
;
; Western Design Center W65C816SXB Development Board Hardware Definitions
;------------------------------------------------------------------------------
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
;==============================================================================
; Notes:
;
; All of the current stock of W65C51 ACIAs have a silicon bug that causes the
; 'Transmit Data Register Empty' (TDRE) bit in the status register to be stuck
; high making it impossible to tell when the transmitter is ready for the next
; data byte.
;
;------------------------------------------------------------------------------

OSC_FREQ        =     8000000                 ; SXB runs at 8MHz

;==============================================================================
; W65C51 ACIA
;------------------------------------------------------------------------------

ACIA_RXD        =     $7f80
ACIA_TXD        =     $7f80
ACIA_SR         =     $7f81
ACIA_CMD        =     $7f82
ACIA_CTL        =     $7f83

;==============================================================================
; W65C21 PIA
;------------------------------------------------------------------------------

PIA_PIA         =     $7fa0
PIA_DDRA        =     $7fa0
PIA_CRA         =     $7fa1
PIA_PIB         =     $7fa2
PIA_DDRB        =     $7fa2
PIA_CRB         =     $7fa3

;==============================================================================
; W65C22 VIA
;------------------------------------------------------------------------------

VIA1_ORB        =     $7fc0
VIA1_IRB        =     $7fc0
VIA1_ORA        =     $7fc1
VIA1_IRA        =     $7fc1
VIA1_DDRB       =     $7fc2
VIA1_DDRA       =     $7fc3
VIA1_T1CL       =     $7fc4
VIA1_T1CH       =     $7fc5
VIA1_T1LL       =     $7fc6
VIA1_T1LH       =     $7fc7
VIA1_T2CL       =     $7fc8
VIA1_T2CH       =     $7fc9
VIA1_SR         =     $7fca
VIA1_ACR        =     $7fcb
VIA1_PCR        =     $7fcc
VIA1_IFR        =     $7fcd
VIA1_IER        =     $7fce
VIA1_ORAN       =     $7fcf
VIA1_IRAN       =     $7fcf

;------------------------------------------------------------------------------

VIA2_ORB        =     $7fe0
VIA2_IRB        =     $7fe0
VIA2_ORA        =     $7fe1
VIA2_IRA        =     $7fe1
VIA2_DDRB       =     $7fe2
VIA2_DDRA       =     $7fe3
VIA2_T1CL       =     $7fe4
VIA2_T1CH       =     $7fe5
VIA2_T1LL       =     $7fe6
VIA2_T1LH       =     $7fe7
VIA2_T2CL       =     $7fe8
VIA2_T2CH       =     $7fe9
VIA2_SR         =     $7fea
VIA2_ACR        =     $7feb
VIA2_PCR        =     $7fec
VIA2_IFR        =     $7fed
VIA2_IER        =     $7fee
VIA2_ORAN       =     $7fef
VIA2_IRAN       =     $7fef
