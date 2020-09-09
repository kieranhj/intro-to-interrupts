\ ******************************************************************
\ *	Sprite plotting example.
\ * Dynamically sets Timer 2 in the System VIA during the Vsync interrupt handler.
\ ******************************************************************

IRQ1V = &204
IRQ2V = &206
PAL_Black = 0 EOR 7
PAL_Green = 2 EOR 7
PAL_Blue  = 4 EOR 7
oswrch = &FFEE
osbyte = &FFF4
INKEY_D = -51
INKEY_F = -68

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

Timer2_Base_in_us = (Total_rows-Vsync_position)*us_per_row - 2*us_per_scanline
Timer2_Value_in_us = Timer2_Base_in_us + Scanline_to_interrupt_at*us_per_scanline

MACRO SETBG_COL col
{
    lda debug_rasters : beq no_debug
    lda #&00 + col : sta &FE21
    lda #&10 + col : sta &FE21
    lda #&40 + col : sta &FE21
    lda #&50 + col : sta &FE21
    .no_debug
}
ENDMACRO

\ ******************************************************************
\ *	Zero page vars 
\ ******************************************************************

ORG &70
GUARD &9F

.old_irq        skip 2
.plot_flag      skip 1

.readptr        skip 2
.writeptr       skip 2

.old_y          skip 1
.plot_y         skip 1
.plot_v         skip 1

.timer_hi       skip 1

.debounce_d     skip 1
.debug_rasters  skip 1

.debounce_f     skip 1
.fixed_timer    skip 1

\ ******************************************************************
\ *	Code 
\ ******************************************************************

ORG &1900
GUARD &3000

.start

.main
{
    \\ Set MODE 1.
    lda #22 : jsr oswrch
    lda #1 : jsr oswrch

	\\ Turn off interlace & cursor.
	lda #8 : sta &FE00                  ; CRTC Register 8 'Interlace & delay'
	lda #&C0 : sta &FE01                ; A=%1100000

    sei                                 ; disable CPU IRQs
    lda #&A2                            ; A=%10100010 (enable vsync and Timer 2 interrupt)
    sta &FE4E                           ; set Interrupt enable register on System VIA

    lda #&00                            ; A%=00000000 (Timer 2 control = one-shot)
    sta &FE4B                           ; set Auxiliary control register on System VIA

    lda IRQ1V   : sta old_irq
    lda IRQ1V+1 : sta old_irq+1         ; save contents of IRQ1V

    lda #LO(irq_handler) : sta IRQ1V
    lda #HI(irq_handler) : sta IRQ1V+1  ; set new IRQ handler
    cli

    \\ Init vars.
    jsr init

    .main_loop
    \\ Check for keys.
    jsr check_keys

    \\ Move sprite.
    jsr move_sprite

    \\ Wait for flag to plot.
    {
        .wait_for_flag
        lda plot_flag
        beq wait_for_flag
        dec plot_flag
    }

    \\ Set background colour to green.
    SETBG_COL PAL_Green

    \\ Erase old sprite.
    ldy old_y : jsr delete_sprite_at_Y

    \\ Set background colour to blue.
    SETBG_COL PAL_Blue

    \\ Plot sprite in new position.
    ldy plot_y : jsr plot_sprite_at_Y

    \\ Set background colour to black.
    SETBG_COL PAL_Black

    jmp main_loop
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

    \\ Handle Vsync interrupt.

    \\ If using a fixed timer just set the plot flag.
    lda fixed_timer
    bne set_plot_flag

    \\ Calculate dynamic timer based on vertical position of sprite 'plot_y'.

    \\ Timer value
    \\  = (Total_rows - Vsync_position) * us_per_row        <-- fixed
    \\  - (2 * us_per_scanline)                             <-- fixed
    \\  + (Scanline_to_interrupt_at) * us_per_scanline      <-- calculate from (plot_y + SPRITE_HEIGHT)

    \\ Timer value = Timer2_Base_in_us + (plot_y + SPRITE_HEIGHT) * 64

    lda #0 : sta timer_hi                       ; set timer high byte to 0.
    
    \\ Add sprite height to plot_y.
    clc
    lda plot_y
    adc #SPRITE_HEIGHT
    rol timer_hi                                ; carry to high byte.

    \\ Multiply (plot_y + SPRITE_HEIGHT) by 64.
    rol a : rol timer_hi                        ; x2
    rol a : rol timer_hi                        ; x4
    rol a : rol timer_hi                        ; x8
    rol a : rol timer_hi                        ; x16
    rol a : rol timer_hi                        ; x32
    rol a : rol timer_hi                        ; x64

    \\ Add Timer2_Base_in_us
    adc #LO(Timer2_Base_in_us) : sta &FE48      ; System VIA Reg 8 'Timer 2 low-order latch'
    lda timer_hi
    adc #HI(Timer2_Base_in_us) : sta &FE49      ; System VIA Reg 9 'Timer 2 high-order counter'
    jmp return_to_os

    .try_timer2
    lda &FE4D
    and #&20
    beq return_to_os

    \\ Clear Timer 2 interrupt flag by reading the Timer 2 low-order register.
    lda &FE48

    \\ Set the flag to call sprite routine.
    .set_plot_flag
    inc plot_flag

    .return_to_os
    pla : sta &FC                       ; restore A register
    jmp (old_irq)                       ; jump to MOS IRQ handler
}

include "source/sprite-plot.asm"

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "build/sprite.bin", start, end, main
