\ Intro to Interrupts on the BBC Micro (part #2)
\ Kieran Connell, vABUG Masterclass #2, 10/09/2020.
\ https://github.com/kieranhj/intro-to-interrupts



.Goals
; Play music in the background
; Time sprite plot routines relative to the raster, to avoid flicker
; Run any code that has to be regular / time critical
; Change MODE or colour palette at specific points on the screen
; Do something else whilst disk or tape is loading
; Advanced graphics (CRTC) effects like Vertical Rupture
; Stable raster…











.System_and_User_VIAs
; See New Advanced User Guide, pp. 380 for details.
; 16 registers mapped into Sheila address space.

.System_VIA => &FE40 - &FE4F
.User_VIA   => &FE60 - &FE6F

'Reg  System VIA  User VIA  Write                          Read'
 0    &FE40       &FE60     Output register B              Input register B
 1    &FE41       &FE61     Output register A              Input register A
 2    &FE42       &FE62     Data direction register B
 3    &FE43       &FE63     Data direction register A
 4    &FE44       &FE64     Timer 1 low-order latch        Timer 1 low-order counter
 5    &FE45       &FE65     Timer 1 high-order counter     Timer 1 high-order counter
 6    &FE46       &FE66     Timer 1 low-order latch        Timer 1 low-order latch
 7    &FE47       &FE67     Timer 1 high-order latch       Timer 1 high-order latch
 8    &FE48       &FE68     Timer 2 low-order latch        Timer 2 low-order counter
 9    &FE49       &FE69     Timer 2 high-order counter     Timer 2 high-order counter
 A    &FE4A       &FE6A     Shift register
 B    &FE4B       &FE6B     Auxiliary control register
 C    &FE4C       &FE6C     Peripheral control register
 D    &FE4D       &FE6D     Interrupt flag register
 E    &FE4E       &FE6E     Interrupt enable register
 F    &FE4F       &FE6F     Same as register 1 but with no handshake (ORA/IRA)






.System_VIA 'Interrupt enable register' &FE4E ; Reg 14

Bit 7 6 5 4 3 2 1 0
    | | | | | | | |
    | | | | | | | +------  CA2           <-- keyboard
    | | | | | | +--------  CA1           <-- vsync pulse from 6845 CRTC
    | | | | | +----------  Shift reg
    | | | | +------------  CB2           <-- light pen strobe from 6845 CRTC
    | | | +--------------  CB1           <-- ADC
    | | +----------------  Timer 2       <-- one-shot or pulse
    | +------------------  Timer 1       <-- one-shot or continuous
    +--------------------  Set (1) / clear (0)

.eg 'disable all interrupts on System VIA':

    lda #&7F : sta &FE4E      ; A=%01111111

.eg 'enable vsync and Timer 1 interrupts on System VIA':

    lda #&C2 : sta &FE4E      ; A=%11000010






.System_VIA 'Interrupt flag register' &FE4D ; Reg 13

Bit 7 6 5 4 3 2 1 0        Set by                  Cleared by
    | | | | | | | |
    | | | | | | | +------  Key press               Read or write Reg 1
    | | | | | | +--------  Vsync pulse             Read or write Reg 1
    | | | | | +----------  8 bits shifted          Read or write Shift register
    | | | | +------------  Light pen strobe        Read or write Reg 0
    | | | +--------------  EOC from ADC            Read or write Reg 0
    | | +----------------  Time-out of Timer 2     Read Timer 2 low or write Timer 2 high
    | +------------------  Time-out of Timer 1     Read Timer 1 low or read Timer 1 high
    +--------------------  Any active interrupt    Clear all interrupts

.eg 'check if Vsync occured on System VIA':

    lda &FE4D : and #&02      ; A=%00000010 if flag is set for vsync

.eg 'clear Timer 1 interrupt flag on System VIA':

    lda &FE44                 ; A=Timer 1 low-order counter






.Running_code_at_Vsync
; Play music in the background
; Do something else whilst disk or tape is loading

Q. 'What is Vsync?'
A. Pulse generated by the video chip that tells the TV electron beam to return to the top-left
   corner of the CRT.

Q. 'When does Vsync happen?'
A. By default at 50Hz (every 20ms) after the visible portion of the screen has been displayed.

\ Look at vsync-example.asm








.Running_code_on_Timers
; Run any code that has to be regular / time critical

Q. 'How do timers work?'
A. Count down at 1MHz = 1,000,000 ticks a second.
   Timers are two bytes: the low-order and high-order counters.
   Timer values are 16-bits = 65,535 max ticks ~= 0.066s max delay.
   When the timer counter reaches 0 the corresponding interrupt flag is set.

Q. 'When does the timer start counting down?'
A. Only when the _high-order_ counter register is written.
   At the same time the low-order counter is automatically loaded from the low-order latch.

.eg 'set Timer 1 on System VIA to count 10,000 ticks':

    lda #LO(10000) : sta &FE44  ; A=&10 written to Timer 1 low-order _latch_
                                ;       has no effect on the currently running timer!
    lda #HI(10000) : sta &FE45  ; A=&27 written to Timer 1 high-order _counter_
                                ;       low-order counter loaded from low-order latch
                                ;       Timer 1 starts counting down from 10000




Q. What are 'continuous' (or 'free-run') and 'one-shot' timer ?
A. All timers set the corresponding interrupt flag when reaching 0.
   'One-shot' timers stop counting after reaching 0.
   'Continuous' (or 'free-run') timers are reloaded with a new value from the _latch_ registers.
   
   It takes 2us for the latch value to be loaded into the counter registers!
   Only Timer 1 can run in 'continuous' mode.
   Timer mode is set using the Auxiliary control register (Reg 11).
   See New Advanced User Guide pp 395.

.eg 'set Timer 1 on System VIA to generate continuous interrupts':

    lda #&40 : sta &FE4B        ; A=%01000000 (Timer 1 control = continuous)

.eg 'set Timer 1 on System VIA to count 5,000 ticks _after_ the current timer has reached 0':

    lda #LO(5000) : sta &FE46   ; A=&88 written to Timer 1 low-order latch
    lda #HI(5000) : sta &FE47   ; A=&13 written to Timer 1 high-order latch
                                ;       has no effect on the currently running timer!

\ Look at 100hz-example.asm






.Setting_up_a_Timer_relative_to_Vsync
; Change MODE or colour palette at specific points on the screen
; Advanced graphics (CRTC) effects like Vertical Rupture

'Set the Timer value in the Vsync interrupt handler.'
'Now we need to be a bit more specific about _when_ the Vsync interrupt occurs.'

   There are 39 character rows per frame (usually only 32 are visible).
   Vsync position is usually at row 34/35 (depends on *TV settings).
   Vsync interrupt occurs 2 scanlines _after_ the pulse.

   One scanline is 64us and there are 8 scanlines per character row*.

   So Timer value = a delay until the end of the frame
                  - adjustment for Vsync pulse delay
                  + a delay until the desired scanline.

.eg delay from vsync at position 35 to scanline 128 = (39 - 35) * 8 * 64
                                                     - 2 * 64
                                                     + 128 * 64
                                                     = 158 * 64 = 10112

\ Look at screen-example.asm






.Setting_a_dynamic_Timer
; Time sprite plot routines relative to the raster, to avoid flicker

Q. What causes sprites to flicker?
A. When bytes of screen memory are modified at the same time as when those bytes are being sent to the display.

   The CRTC video chip generates screen addresses at either 1MHz or 2MHz, so 40 or 80 bytes per scanline*.
   The Video ULA fetches whatever is in RAM for each address and sends pixels to the display*.
   If our sprite routine (erase / EOR / plot) does not complete before that screen address is sent (the raster),
   then flickering or tearing can occur.

Q. How to make sure a plot routine completes before the raster?
A. 'Set a Timer so we call the routine _after_ the raster has passed the vertical position of the sprite on screen.'
   NB. this is just one approach, many others are possible!

.eg If a sprite is erased and plotted at scanline 100, and is 16 pixels high, then we aim to call the routine
    _no earlier_ than scanline 100+16=116. As long as it completes before the raster reaches scanline 100 again,
    there will be no flicker.

\ Look at sprite-example.asm







.Using_System_VIA_without_an_IRQ_handler
; Stable raster…
'Left as an exercise for the reader!'
