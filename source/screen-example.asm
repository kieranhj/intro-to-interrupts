\ ******************************************************************
\ *	Screen interrupt example.
\ * Using the User VIA so this can run alongside the MOS.
\ ******************************************************************

IRQ1V = &204
IRQ2V = &206
PAL_Black = 0 EOR 7
PAL_Blue  = 4 EOR 7

\\ Constants.
Vsync_position = 35
Total_rows = 39

us_per_scanline = 64            ; one scanline is 64us
us_per_row = 8*64               ; one character row is 8 scanlines

Scanline_to_interrupt_at = 128

\\ We set our Timer inside the Vsync interrupt
\\ We must wait until the end of the video frame, which is a total of 39 character rows.
\\ The interrupt is actually triggered 2 scanlines later so need to adjust for this.

\\ Setting Timer 2 in Vsync therefore has a value of:
\\  = (Total_rows - Vsync_position) * us_per_row
\\  - (2 * us_per_scanline)                             ; adjust for pulse delay
\\  + (Scanline_to_interrupt_at) * us_per_scanline

Timer2_Value_in_us = (Total_rows-Vsync_position)*us_per_row - 2*us_per_scanline + Scanline_to_interrupt_at*us_per_scanline

\ ******************************************************************
\ *	Zero page vars 
\ ******************************************************************

ORG &70
GUARD &9F

.timer_value    skip 2
.old_irq        skip 2

\ ******************************************************************
\ *	Code 
\ ******************************************************************

ORG &2000
GUARD &3000

.start

.main
{
    sei                                 ; disable CPU IRQs
    lda #&82                            ; A=%100000010 (enable vsync interrupt)
    sta &FE4E                           ; set Interrupt enable register on System VIA

    lda #&A0                            ; A=%10100000 (enable Timer 2 interrupt)
    sta &FE6E                           ; set Interrupt enable register on User VIA

    lda IRQ1V   : sta old_irq
    lda IRQ1V+1 : sta old_irq+1         ; save contents of IRQ1V

    lda #LO(irq_handler) : sta IRQ1V
    lda #HI(irq_handler) : sta IRQ1V+1  ; set new IRQ handler

    \\ Store our Timer value in ZP.
    lda #LO(Timer2_Value_in_us) : sta timer_value
    lda #HI(Timer2_Value_in_us) : sta timer_value+1

    cli                                 ; enable CPU IRQs
    rts
}

\ ******************************************************************
\ * IRQ handler
\ ******************************************************************

.irq_handler
{
    lda &FC : pha                       ; store A on the stack

    lda &FE4D                           ; read Interrupt flag register on System VIA
    and #&02                            ; check for vsync interrupt
    beq try_timer2

    \\ Set background colour to black.
    lda #PAL_Black
    sta &fe21                           ; ULA Palette register

    \\ Set one-shot Timer 2 in User VIA using value from ZP.
    lda timer_value   : sta &FE68       ; User VIA Reg 8 'Timer 2 low-order latch'
    lda timer_value+1 : sta &FE69       ; User VIA Reg 9 'Timer 2 high-order counter'
    jmp return_to_os

    .try_timer2
    lda &FE6D                           ; read Interrupt flag register on User VIA
    and #&20                            ; check for Timer 2 interrupt
    beq return_to_os                    ; if not then pass on to MOS IRQ handler

    \\ Clear Timer 2 interrupt flag by reading the Timer 2 low-order register.
    lda &FE68

    \\ Set the background to blue.
    lda #PAL_Blue
    sta &fe21                           ; ULA Palette register

    .return_to_os
    pla : sta &FC                       ; restore A register
    jmp (old_irq)                       ; jump to MOS IRQ handler
}

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "build/screen.bin", start, end, main
