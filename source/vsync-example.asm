\ ******************************************************************
\ *	Vsync Interrupt example.
\ * 
\ ******************************************************************

IRQ1V = &204
IRQ2V = &206

\ ******************************************************************
\ *	Zero page vars 
\ ******************************************************************

ORG &70
GUARD &9F

.vsync_count    skip 1
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
    lda #&82                            ; A=%100000010 (enable vsync interrupt)
    sta &FE4E                           ; set Interrupt enable register on System VIA

    lda IRQ1V   : sta old_irq
    lda IRQ1V+1 : sta old_irq+1         ; save contents of IRQ1V

    lda #LO(irq_handler) : sta IRQ1V
    lda #HI(irq_handler) : sta IRQ1V+1  ; set new IRQ handler

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
    beq return_to_os                    ; if not then pass on to MOS IRQ handler

    \\ Q. What happens if we clear the vsync interrupt flag?
    \\ sta &FE4D                           ; A=%00000010 (clear vsync interrupt flag)

    \\ Increment our vsync counter.
    inc vsync_count

    \\ Write the counter to screen memory.
    lda vsync_count
    sta &7FE0 : sta &7FE1
    sta &7FE2 : sta &7FE3
    sta &7FE4 : sta &7FE5
    sta &7FE6 : sta &7FE7

    \\ Jump to music player routine..?

    .return_to_os
    pla : sta &FC                       ; restore A register
    jmp (old_irq)                       ; jump to MOS IRQ handler
}

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "build/vsync.bin", start, end, main
