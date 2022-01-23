

!addr	VIC_Base	= $d400



* = $8000

!source "kernal_funcs.asm"

!word $8009
!word $8009
!pet "CBM80", 5, 0


jsr IOINIT
;jsr SCINIT
;jsr RAMTAS

;lda #$8
;jsr LISTEN

lda #8
ldx #((.filename>>0) & $ff)
ldy #((.filename>>8) & $ff)
jsr SETNAM

lda #15
ldx #8
ldy #15
jsr SETLFS

jsr OPEN
bcs .fail

.loop
  jmp .loop
.fail
  jmp .fail


.filename
!text "TESTFILE"