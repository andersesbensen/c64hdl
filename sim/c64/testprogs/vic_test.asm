

!addr	VIC_Base	= $d400

* = $8000


!word $8009
!word $8009
!pet "CBM80", 5, 0

ldy #$18
sty VIC_Base + $11

.loop
  ldy #$55
  ldx #$aa
  sty VIC_Base + $02
  lda VIC_Base + $02
  stx VIC_Base + $03
  cmp #$55
  bne .fail
  lda VIC_Base + $03
  cmp #$aa
  bne .fail
  jmp .loop
.fail
  jmp .fail