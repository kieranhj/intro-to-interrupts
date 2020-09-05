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

Timer1_Value_in_us = (Total_rows-Vsync_position)*us_per_row - 2*us_per_scanline + Scanline_to_interrupt_at*us_per_scanline
Timer1_Latch_in_us = Total_rows * us_per_row

\ ******************************************************************
\ *	Zero page vars 
\ ******************************************************************

ORG &70
GUARD &9F

.timer_value    skip 2
.plot_y         skip 1

.readptr        skip 2
.writeptr       skip 2
.plot_lines     skip 1

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
    lda #&7F
    sta &FE4E
    lda #&C2                            ; A=%100000010 (enable vsync interrupt)
    sta &FE4E                           ; set Interrupt enable register on System VIA

    lda #0 : sta plot_y

    \\ Wait for vsync.
	{
		lda #&02
		.vsync_wait
		bit &FE4D
		beq vsync_wait
        sta &FE4D
	}

    lda #LO(Timer1_Value_in_us) : sta &FE44
    lda #HI(Timer1_Value_in_us) : sta &FE45
    lda #LO(Timer1_Latch_in_us - 2) : sta &FE46
    lda #HI(Timer1_Latch_in_us - 2) : sta &FE47

    .main_loop

IF 1
    \\ Set one-shot Timer 2 in User VIA using value from ZP.

    \\ Do something else here!

    \\ Wait for Timer 1.
    {
		lda #&40
		.timer_wait
		bit &FE4D
		beq timer_wait
        lda &FE44
    }
ENDIF

    lda #PAL_Green : sta &FE21
    
    ldy plot_y : jsr delete_sprite_at_Y

    lda #PAL_Blue : sta &FE21

    {
        ldy plot_y
        iny
        cpy #255-64
        bcc ok
        ldy #0
        .ok
        sty plot_y
    }
    jsr plot_sprite_at_Y

    lda #PAL_Black : sta &FE21

    jmp main_loop
    rts
}

\ ******************************************************************
\ * IRQ handler
\ ******************************************************************

include "source/plot.asm"

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "build/plot.bin", start, end, main
