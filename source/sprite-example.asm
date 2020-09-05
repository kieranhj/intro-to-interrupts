\ ******************************************************************
\ *	Screen interrupt example.
\ * Using the User VIA so this can run alongside the MOS.
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
    lda #22 : jsr oswrch
    lda #1 : jsr oswrch
	\\ Turn off interlace & cursor
	lda #8 : sta &fe00
	lda #&c0 : sta &fe01

    sei                                 ; disable CPU IRQs
    lda #&A2                            ; A=%100000010 (enable vsync interrupt)
    sta &FE4E                           ; set Interrupt enable register on System VIA

    lda #&00
    sta &FE4B

    lda IRQ1V   : sta old_irq
    lda IRQ1V+1 : sta old_irq+1         ; save contents of IRQ1V

    lda #LO(irq_handler) : sta IRQ1V
    lda #HI(irq_handler) : sta IRQ1V+1  ; set new IRQ handler
    cli

    \\ Init vars.
    lda #0 : sta plot_y
    sta plot_v: sta plot_flag

    lda #1 : sta debug_rasters
    sta fixed_timer

    .main_loop
    \\ Check for keys.
    jsr check_keys

    \\ Wait for flag to plot.
    {
        .wait_for_flag
        lda plot_flag
        beq wait_for_flag
        dec plot_flag
    }

    \\ Erase old sprite.
    SETBG_COL PAL_Green
    ldy plot_y : jsr delete_sprite_at_Y

    \\ Move sprite and plot in new position.
    SETBG_COL PAL_Blue
    jsr move_sprite
    ldy plot_y : jsr plot_sprite_at_Y

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

    lda fixed_timer
    bne set_plot_flag

    \\ Set one-shot Timer 2.  
    lda #0 : sta timer_hi
    clc
    lda plot_y
    adc #64
    rol timer_hi

    rol a : rol timer_hi
    rol a : rol timer_hi
    rol a : rol timer_hi
    rol a : rol timer_hi
    rol a : rol timer_hi
    rol a : rol timer_hi
    adc #LO(Timer2_Base_in_us) : sta &FE48
    lda timer_hi
    adc #HI(Timer2_Base_in_us) : sta &FE49
    jmp return_to_os

    .try_timer2
    lda &FE4D
    and #&20
    beq return_to_os

    lda &FE48

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
