SPRITE_WIDTH = 64
SPRITE_STRIDE = SPRITE_WIDTH/4
SPRITE_HEIGHT = 64

.calc_writeptr
{
    tya
    lsr a:lsr a:lsr a
    tax

    tya:and #7
    clc
    adc screen_row_addr_LO, X
    sta writeptr
    lda screen_row_addr_HI, X
    adc #0
    sta writeptr+1
    rts
}

.plot_sprite_at_Y
{
    jsr calc_writeptr

    lda #LO(sprite_data)
    sta readptr
    lda #HI(sprite_data)
    sta readptr+1

    ldx #SPRITE_HEIGHT
    .line_loop
    FOR col,0,SPRITE_STRIDE-1,1
    ldy #col : lda (readptr), Y
    ldy #col * 8 : sta (writeptr), Y
    NEXT

    inc writeptr
    lda writeptr
    and #7
    bne same_row

    clc
    lda writeptr
    adc #LO(640-8)
    sta writeptr
    lda writeptr+1
    adc #HI(640-8)
    sta writeptr+1
    .same_row

    clc
    lda readptr
    adc #SPRITE_STRIDE
    sta readptr
    bcc no_carry
    inc readptr+1
    .no_carry

    dex
    beq done
    jmp line_loop
    .done
    rts
}

.delete_sprite_at_Y
{
    jsr calc_writeptr

    ldx #SPRITE_HEIGHT
    .line_loop
    lda #0
    FOR col,0,SPRITE_STRIDE-1,1
    ldy #col * 8 : sta (writeptr), Y
    NEXT

    inc writeptr
    lda writeptr
    and #7
    bne same_row

    clc
    lda writeptr
    adc #LO(640-8)
    sta writeptr
    lda writeptr+1
    adc #HI(640-8)
    sta writeptr+1
    .same_row

    dex
    bne line_loop
    .done
    rts
}

.screen_row_addr_LO
FOR r,0,31,1
EQUB LO(&3000 + r*640 + 32*8)
NEXT

.screen_row_addr_HI
FOR r,0,31,1
EQUB HI(&3000 + r*640 + 32*8)
NEXT

ALIGN &100
.sprite_data
incbin "data/sprite.bin"
