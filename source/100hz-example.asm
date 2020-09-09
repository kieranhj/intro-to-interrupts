\ ******************************************************************
\ *	100Hz Interrupt example.
\ * Using the User VIA so this can run alongside the MOS.
\ ******************************************************************

IRQ1V = &204
IRQ2V = &206

\\ Remember 6522 VIA timers run at 1MHz!
\\ It takes 2us to latch the new timer value.
Timer1_Value_in_us = 10000             ; 10000us = 10ms = 100Hz

\ ******************************************************************
\ *	Zero page vars 
\ ******************************************************************

ORG &70
GUARD &9F

.timer_count    skip 1
.old_irq        skip 2

\ ******************************************************************
\ *	Code 
\ ******************************************************************

ORG &1900
GUARD &3000

.start

.main
{
    sei                                 ; disable CPU IRQs
    lda #&C0                            ; A=%10100000 (enable Timer 1 interrupt)
    sta &FE6E                           ; set Interrupt enable register on User VIA

    lda IRQ1V   : sta old_irq
    lda IRQ1V+1 : sta old_irq+1         ; save contents of IRQ1V

    lda #LO(irq_handler) : sta IRQ1V
    lda #HI(irq_handler) : sta IRQ1V+1  ; set new IRQ handler

    \\ Set Timer 1 on User VIA to have continous interrupts.
    lda #&40                            ; A%=%01000000 (Timer 1 control)
    sta &FE6B                           ; set Auxilary control register on User VIA

    \\ Set Timer 1 _counter_ value on User VIA to 5000us.
    lda #LO(5000) : sta &FE64
    lda #HI(5000) : sta &FE65

    \\ Set Timer 1 _latch_ value on User VIA to 10000us.
    \\ Note that the latch takes 2us to load into the counter so we subtract 2 from the value to adjust.
    lda #LO(Timer1_Value_in_us - 2) : sta &FE66
    lda #HI(Timer1_Value_in_us - 2) : sta &FE67

    cli                                 ; enable CPU IRQs
    rts
}

\ ******************************************************************
\ * IRQ handler
\ ******************************************************************

.irq_handler
{
    lda &FC : pha                       ; store A on the stack

    lda &FE6D                           ; read Interrupt flag register on User VIA
    and #&80                            ; check for Timer 1 interrupt
    beq return_to_os                    ; if not then pass on to MOS IRQ handler

    \\ Clear Timer 1 interrupt flag by reading the Timer 1 low-order register.
    lda &FE64

    \\ Increment our counter.
    inc timer_count

    \\ Use bottom bit of the counter to set the ULA palette register.
    \\ Set colour 0 to either 7 (black) or 6 (red).
    lda timer_count
    and #&01
    eor #7                              ; ULA colours are inverted
    sta &fe21                           ; ULA palette register

    .return_to_os
    pla : sta &FC                       ; restore A register
    jmp (old_irq)                       ; jump to MOS IRQ handler
}

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "build/100hz.bin", start, end, main
