org $9000

test2:
    ld  c, $70
    ld  a, $01
    out (c),a

    ld b, a

    ld de, $0003

loop0:
    ld hl, $8FFF

loop1:
    dec hl
    ld a, h
    or l
    jr nz, loop1

    dec de
    ld  a, d
    or  e
    jr  nz, loop0

    jr test2


; test1:
;     ld  c, $70
;     inc a
;     out (c),a
;     jr test1



