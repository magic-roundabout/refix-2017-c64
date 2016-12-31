;
; REFIX 2017
;

; Code and graphics by T.M.R/Cosine
; Music by aNdy/Cosine



; Select an output filename
		!to "refix_2017.prg",cbm


; Yank in binary data
		* = $0900
music		!binary "data/macrocosm.prg",,2

		* = $2000
		!binary "data/logo.chr"

		* = $2800
		!binary "data/scroll.chr"

		* = $2e00
		!binary "data/sprites.spr"


; Constants
rstr1p		= $00
rstr2p		= $61

; More constants in their own file for "neatness"!
		!src "includes/colours.asm"


; Label assignments
rn		= $50
rt_store_1	= $51
rt_store_2	= $52

scroll_spd_1	= $53
scroll_x_1	= $54
char_width_1	= $55
d016_mirror_1	= $56

scroll_spd_2	= $57
scroll_x_2	= $58
char_width_2	= $59
d016_mirror_2	= $5a


; Locations of various blocks of text
scroll_line_1	= $0543
scroll_col_1	= scroll_line_1+$d400

text_line_1	= $05e4
text_col_1	= text_line_1+$d400

text_line_2	= $065c
text_col_2	= text_line_2+$d400

text_line_3	= $06d4
text_col_3	= text_line_3+$d400

scroll_line_2	= $0773
scroll_col_2	= scroll_line_2+$d400


; Buffer space for the line decoder
text_buffer	= $2100


; Entry point at $0812
		* = $3200
entry		sei

		lda #<nmi
		sta $fffa
		lda #>nmi
		sta $fffb

		lda #<int
		sta $fffe
		lda #>int
		sta $ffff

		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #rstr1p
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

		lda #$35
		sta $01

; Initialise $d800 colour RAM
		ldx #$00
		lda #$0e
colour_clear	sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne colour_clear

; Screen setup :: drop shadow line below the logo
		ldx #$00
		lda #$06
drop_colour	sta $d8f0,x
		inx
		cpx #$06
		bne drop_colour

; Set the colour RAM for the text and scroller lines
		ldx #$00
		lda #$00
text_colour_1	sta scroll_col_1+$00,x
		sta scroll_col_1+$28,x

		sta text_col_1+$00,x
		sta text_col_1+$28,x

		sta text_col_2+$00,x
		sta text_col_2+$28,x

		sta text_col_3+$00,x
		sta text_col_3+$28,x

		sta scroll_col_2+$00,x
		sta scroll_col_2+$28,x
		inx
		cpx #$1f
		bne text_colour_1

; Build text lines
		lda #<text_data_1
		sta tb_loop+$01
		lda #>text_data_1
		sta tb_loop+$02
		jsr text_render

		ldx #$00
text_1_copy	lda text_buffer,x
		sta text_line_1+$02,x
		clc
		adc #$58
		sta text_line_1+$2a,x
		inx
		cpx #$1c
		bne text_1_copy

		lda #<text_data_2
		sta tb_loop+$01
		lda #>text_data_2
		sta tb_loop+$02
		jsr text_render

		ldx #$00
text_2_copy	lda text_buffer,x
		sta text_line_2+$02,x
		clc
		adc #$58
		sta text_line_2+$2a,x
		inx
		cpx #$1c
		bne text_2_copy

		lda #<text_data_3
		sta tb_loop+$01
		lda #>text_data_3
		sta tb_loop+$02
		jsr text_render

		ldx #$00
text_3_copy	lda text_buffer,x
		sta text_line_3+$02,x
		clc
		adc #$58
		sta text_line_3+$2a,x
		inx
		cpx #$1c
		bne text_3_copy


; Set up some labels
		ldx #$50
		lda #$00
zp_clear	sta $00,x
		inx
		bne zp_clear

		lda #$01
		sta rn

; Reset the scrolling messages
		jsr reset_1
		lda #$01
		sta char_width_1
		lda #$03
		sta scroll_spd_1

		jsr reset_2
		lda #$01
		sta char_width_2
		lda #$03
		sta scroll_spd_2


; Initialise the music
		lda #$00
		jsr music+$00

		cli

; Runtime loop
main_loop	lda $dc01
		cmp #$ef
		bne main_loop

; Shut down
		sei
		lda #$0b
		sta $d011
		lda #$00
		sta $d020
		sta $d021
		sta $d418

		jmp *


; IRQ interrupt
int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne ya
		jmp ea31

ya		lda rn
		cmp #$02
		bne *+$05
		jmp rout2


; Raster split 1
rout1		lda #$02
		sta rn
		lda #rstr2p
		sta $d012

; Screen and border colours
		lda #$06
		sta $d020
		sta $d021
		lda #$00
		sta $3fff
		lda #$0f
		sta $d023

		ldx #$00
set_spr_pos_1	lda sprite_pos_1,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_1

		ldx #$00
set_spr_dp_1	lda sprite_dp_1,x
		sta $07f8,x
		lda #$00
		sta $d027,x
		inx
		cpx #$08
		bne set_spr_dp_1

; set video mode for the start of the screen
		lda #$1b
		sta $d011
		lda #$08
		sta $d016
		lda #$18
		sta $d018

; Turn on the hardware sprites for the upper border
		lda #$ff
		sta $d015
		lda #$ff
		sta $d017
		sta $d01c
		lda #$00
		sta $d01b
		sta $d01d

		lda #$06
		sta $d025
		lda #$0f
		sta $d026

; Wait to draw the upper edge of the "box"
		lda #$18+8
		cmp $d012
		bne *-$03
		ldx #$07
		dex
		bne *-$01
		nop
		nop
		nop
		lda #$0f
		sta $d021

		ldx #$0f
		dex
		bne *-$01
		nop
		nop
		lda #$00
		sta $d021

		lda #$3b
		sta $d011

; Update the upper scroller
		ldy scroll_spd_1
scroll_1_upd	ldx scroll_x_1
		inx
		cpx #$08
		bne scroll_1_xb

; Shift the character lines
		ldx #$00
mover_1		lda scroll_line_1+$01,x
		sta scroll_line_1+$00,x
		clc
		adc #$58
		sta scroll_line_1+$28,x
		inx
		cpx #$1f
		bne mover_1

		dec char_width_1
		beq mread_1

; Bump the current character value by one
		lda scroll_line_1+$1f
		clc
		adc #$01
		sta scroll_line_1+$1f
		clc
		adc #$58
		sta scroll_line_1+$47
		jmp no_fetch_1

; Fetch a new character
mread_1		lda scroll_text_1
		bne okay_1
		jsr reset_1
		jmp mread_1

okay_1		cmp #$81
		bcc okay_1b
		and #$0f
		sta scroll_spd_1
		lda #$20

okay_1b		tax
		lda char_pos_dcd,x
		sta scroll_line_1+$1f
		clc
		adc #$58
		sta scroll_line_1+$47
		lda char_width_dcd,x
		sta char_width_1

		inc mread_1+$01
		bne *+$05
		inc mread_1+$02

no_fetch_1	ldx #$00
scroll_1_xb	stx scroll_x_1

		dey
		bne scroll_1_upd

; Update the lower scroller
		ldy scroll_spd_2
scroll_2_upd	ldx scroll_x_2
		inx
		cpx #$08
		bne scroll_2_xb

; Shift the character lines
		ldx #$00
mover_2		lda scroll_line_2+$01,x
		sta scroll_line_2+$00,x
		clc
		adc #$58
		sta scroll_line_2+$28,x
		inx
		cpx #$1f
		bne mover_2

		dec char_width_2
		beq mread_2

; Bump the current character value by one
		lda scroll_line_2+$1f
		clc
		adc #$01
		sta scroll_line_2+$1f
		clc
		adc #$58
		sta scroll_line_2+$47
		jmp no_fetch_2

; Fetch a new character
mread_2		lda scroll_text_2
		bne okay_2
		jsr reset_2
		jmp mread_2

okay_2		cmp #$81
		bcc okay_2b
		and #$0f
		sta scroll_spd_2
		lda #$20

okay_2b		tax
		lda char_pos_dcd,x
		sta scroll_line_2+$1f
		clc
		adc #$58
		sta scroll_line_2+$47
		lda char_width_dcd,x
		sta char_width_2

		inc mread_2+$01
		bne *+$05
		inc mread_2+$02

no_fetch_2	ldx #$00
scroll_2_xb	stx scroll_x_2

		dey
		bne scroll_2_upd

; Relocate the hardware sprites down and disable Y expansion after line $3a
		lda #$3a
		cmp $d012
		bcs *-$03

		lda #$00
		sta $d017
		lda #$fc
		sta $d01b
		sta $d01d
		lda #$ff
		sta $d01c

		ldx #$00
set_spr_pos_2	lda sprite_pos_2,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_2

		ldx #$00
set_spr_dp_2	lda sprite_dp_2,x
		sta $07f8,x
		inx
		cpx #$08
		bne set_spr_dp_2

		jmp ea31


		* = ((*/$100)+1)*$100

; Raster split 2
rout2		bit $ea
		nop
		nop
		nop
		nop
		nop

		lda $d012
		cmp #rstr2p+$01
		bne *+$02
;		sta $d020

		ldx #$09
		dex
		bne *-$01
		lda #$1b
		sta $d011
		nop
		lda $d012
		cmp #rstr2p+$02
		bne *+$02
;		sta $d020

		ldx #$01
		dex
		bne *-$01
		nop
		nop
		lda $d012
		cmp #rstr2p+$03
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		nop
		nop
		lda $d012
		cmp #rstr2p+$04
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		nop
		nop
		lda $d012
		cmp #rstr2p+$05
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea
		lda $d012
		cmp #rstr2p+$06
		bne *+$02
;		sta $d020

; Wait for the start of the multicolour char area
		ldx #$30
		dex
		bne *-$01
		lda #$10
		sta $d016

; Wait for just before the first scroller
		ldx #$50
		dex
		bne *-$01
		nop
		nop
		nop
		nop

		lda scroll_x_1
		and #$07
		eor #$17
		ldy #$1a
		jsr text_splitter
		lda #$10
		sta $d016

		ldx #$07
		dex
		bne *-$01
		nop
		nop
		nop

; Move the sprites for the first static text line
		ldx #$00
set_spr_pos_3	lda sprite_pos_3,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_3

		ldx #$00
set_spr_dp_3	lda sprite_dp_3,x
		sta $07f8,x
		inx
		cpx #$08
		bne set_spr_dp_3

; Split colours for the first static text line
		ldx #$51
		dex
		bne *-$01
		bit $ea
		nop

		lda #text_d016_1
		ldy #$1a
		jsr text_splitter

		lda #$10
		sta $d016

; Move the sprites for the second static text line
		ldx #$00
set_spr_pos_4	lda sprite_pos_4,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_4

; Only one data pointer needs changing on this line
		lda #$c2
		sta $07f9

; Split colours for the second static text line
		ldx #$16
		dex
		bne *-$01
		nop
		nop

		lda #text_d016_2
		ldy #$1a
		jsr text_splitter

		lda #$10
		sta $d016

; Move the sprites for the third static text line
		ldx #$00
set_spr_pos_5	lda sprite_pos_5,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_5

		ldx #$00
set_spr_dp_5	lda sprite_dp_5,x
		sta $07f8,x
		inx
		cpx #$03
		bne set_spr_dp_5

; Split colours for the third static text line
		ldx #$0d
		dex
		bne *-$01
		nop
		nop
		nop

		lda #text_d016_3
		ldy #$1a
		jsr text_splitter

		lda #$10
		sta $d016

; Move the sprites for the second scroller
		ldx #$00
set_spr_pos_6	lda sprite_pos_6,x
		sta $d000,x
		inx
		cpx #$11
		bne set_spr_pos_6

; Only one data pointer needs changing on this line
		lda #$c3
		sta $07f9

; Split colours for the second scroller
		ldx #$71
		dex
		bne *-$01
		bit $ea
		nop

		lda scroll_x_2
		and #$07
		eor #$17
		ldy #$1a
		jsr text_splitter

		lda #$10
		sta $d016

; Start opening the upper and lower borders
		lda #$f8
		cmp $d012
		bne *-$03
		lda #$14
		sta $d011

; Move the sprites for the lower border (unrolled for speed)
		lda #$10
		sta $d000
		lda #$28
		sta $d002
		lda #$40
		sta $d004
		lda #$f8
		sta $d006
		lda #$10
		sta $d008
		lda #$28
		sta $d00a
		lda #$40
		sta $d00c
		lda #$70
		sta $d010

		lda #$fa
		sta $d001
		sta $d003
		sta $d005
		sta $d007
		sta $d009
		sta $d00b
		sta $d00d

		lda #$bc
		sta $07f8
		sta $07f9
		lda #$c4
		sta $07fa
		lda #$c5
		sta $07fb
		lda #$c6
		sta $07fc
		lda #$c7
		sta $07fd
		lda #$bc
		sta $07fe

		lda #$00
		sta $d029
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d01b
		sta $d01d
		lda #$ff
		sta $d017

; Finish opening the upper and lower borders
		lda #$fc
		cmp $d012
		bne *-$03
		lda #$1b
		sta $d011

; Play the music
;		dec $d020
		jsr music+$03
;		inc $d020

; Wait to draw the lower edge of the "box"
		lda #$14
		cmp $d012
		bne *-$03
		ldx #$06
		dex
		bne *-$01
		bit $ea
		lda #$0f
		sta $d021

		ldx #$12
		dex
		bne *-$01
		lda #$06
		sta $d021


		lda #$01
		sta rn
		lda #rstr1p
		sta $d012

ea31		pla
		tay
		pla
		tax
		pla
nmi		rti


; Colour splitting code for the scroller and text lines
text_splitter	sty $d018
		sta $d016

		lda #spl_col0_01
		sta $d021

		lda #spl_col1_08
		sta $d029

		lda #spl_col1_01
		sta $d021
		lda #spl_col2_01
		sta $d021
		lda #spl_col3_01
		sta $d021
		lda #spl_col4_01
		sta $d021
		lda #spl_col5_01
		sta $d021

		bit $ea
		lda #spl_col2_08
		sta $d02a


		lda #spl_col0_02
		sta $d021
		lda #spl_col1_02
		sta $d021
		lda #spl_col2_02
		sta $d021
		lda #spl_col3_02
		sta $d021
		lda #spl_col4_02
		sta $d021
		lda #spl_col5_02
		sta $d021

		bit $ea
		lda #spl_col3_08
		sta $d02b

		lda #spl_col0_03
		sta $d021
		lda #spl_col1_03
		sta $d021
		lda #spl_col2_03
		sta $d021
		lda #spl_col3_03
		sta $d021
		lda #spl_col4_03
		sta $d021
		lda #spl_col5_03
		sta $d021

		bit $ea
		lda #spl_col4_08
		sta $d02c

		lda #spl_col0_04
		sta $d021
		lda #spl_col1_04
		sta $d021
		lda #spl_col2_04
		sta $d021
		lda #spl_col3_04
		sta $d021
		lda #spl_col4_04
		sta $d021
		lda #spl_col5_04
		sta $d021

		bit $ea
		lda #spl_col5_08
		sta $d02d

		lda #spl_col0_05
		sta $d021
		lda #spl_col1_05
		sta $d021
		lda #spl_col2_05
		sta $d021
		lda #spl_col3_05
		sta $d021
		lda #spl_col4_05
		sta $d021
		lda #spl_col5_05
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col0_06
		sta $d021
		lda #spl_col1_06
		sta $d021
		lda #spl_col2_06
		sta $d021
		lda #spl_col3_06
		sta $d021
		lda #spl_col4_06
		sta $d021
		lda #spl_col5_06
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col0_07
		sta $d021
		lda #spl_col1_07
		sta $d021
		lda #spl_col2_07
		sta $d021
		lda #spl_col3_07
		sta $d021
		lda #spl_col4_07
		sta $d021
		lda #spl_col5_07
		sta $d021

		lda #$00
		sta $d021
		bit $ea
		nop
		nop
		nop
		nop

		lda #spl_col1_09
		sta $d021
		lda #spl_col2_09
		sta $d021
		lda #spl_col3_09
		sta $d021
		lda #spl_col4_09
		sta $d021
		lda #spl_col5_09
		sta $d021
		lda #spl_col6_09
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col1_0a
		sta $d021
		lda #spl_col2_0a
		sta $d021
		lda #spl_col3_0a
		sta $d021
		lda #spl_col4_0a
		sta $d021
		lda #spl_col5_0a
		sta $d021
		lda #spl_col6_0a
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col1_0b
		sta $d021
		lda #spl_col2_0b
		sta $d021
		lda #spl_col3_0b
		sta $d021
		lda #spl_col4_0b
		sta $d021
		lda #spl_col5_0b
		sta $d021
		lda #spl_col6_0b
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col1_0c
		sta $d021
		lda #spl_col2_0c
		sta $d021
		lda #spl_col3_0c
		sta $d021
		lda #spl_col4_0c
		sta $d021
		lda #spl_col5_0c
		sta $d021
		lda #spl_col6_0c
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col1_0d
		sta $d021
		lda #spl_col2_0d
		sta $d021
		lda #spl_col3_0d
		sta $d021
		lda #spl_col4_0d
		sta $d021
		lda #spl_col5_0d
		sta $d021
		lda #spl_col6_0d
		sta $d021

		bit $ea
		nop
		nop
		nop

		lda #spl_col1_0e
		sta $d021
		lda #spl_col2_0e
		sta $d021
		lda #spl_col3_0e
		sta $d021
		lda #spl_col4_0e
		sta $d021
		lda #spl_col5_0e
		sta $d021
		lda #spl_col6_0e
		sta $d021

		lda #$00
		sta $d021

		rts


; Self mod code to reset the scrolling messages
reset_1		lda #<scroll_text_1
		sta mread_1+$01
		lda #>scroll_text_1
		sta mread_1+$02
		rts

reset_2		lda #<scroll_text_2
		sta mread_2+$01
		lda #>scroll_text_2
		sta mread_2+$02
		rts

; Wipe the text buffer
text_render	ldx #$00
		txa
tbc_loop	sta text_buffer,x
		inx
		cpx #$28
		bne tbc_loop

; Fetch data and convert
		ldx #$00
		ldy #$00
tb_loop		lda text_data_1,x
		beq tb_exit
		sta rt_store_1
		stx rt_store_2
		tax
		lda char_pos_dcd,x
		sta text_buffer,y
		ldx rt_store_2

		sty rt_store_2
		lsr
		tay
		ldy rt_store_1
		lda char_width_dcd,y
		ldy rt_store_2
		cmp #$02
		bcc tb_count

		lda text_buffer,y
		clc
		adc #$01
		iny
		sta text_buffer,y

tb_count	iny
		inx
		cpx #$1e
		bcc tb_loop

tb_exit		rts


; Start position for each character
char_pos_dcd	!byte $00,$01,$03,$05,$07,$09,$0b,$0d		; @ to G
		!byte $0f,$11,$12,$14,$16,$18,$1a,$1c		; H to O
		!byte $1e,$20,$22,$24,$26,$28,$2a,$2c		; P to W
		!byte $2e,$30,$32,$00,$00,$00,$00,$00		; X to Z, 5 * punct.
		!byte $00,$34,$00,$00,$00,$00,$00,$35		; space to '
		!byte $36,$38,$00,$00,$39,$3a,$3c,$3d		; ( to /
		!byte $3f,$41,$42,$44,$46,$48,$4a,$4c		; 0 to 7
		!byte $4e,$50,$52,$53,$00,$54,$00,$56		; 8 to ?

; Width for each character
char_width_dcd	!byte $01,$02,$02,$02,$02,$02,$02,$02		; @ to G
		!byte $02,$01,$02,$02,$02,$02,$02,$02		; H to O
		!byte $02,$02,$02,$02,$02,$02,$02,$02		; P to W
		!byte $02,$02,$02,$01,$01,$01,$01,$01		; X to Z, 5 * punct.
		!byte $01,$01,$02,$01,$01,$01,$01,$01		; space to '
		!byte $01,$01,$01,$02,$01,$02,$01,$02		; ( to /
		!byte $02,$01,$02,$02,$02,$02,$02,$02		; 0 to 7
		!byte $02,$02,$01,$01,$01,$01,$01,$02		; 8 to ?


; Upper scrolling message
scroll_text_1	!scr $82,"greetings to the fluffy bunnies in...    "
		!scr $85,"absence - "
		!scr "abyss connection - "
		!scr "arkanix labs - "
		!scr "artstate - "
		!scr "ate bit - "
		!scr "atlantis - "
		!scr "booze - "
		!scr "camelot - "
		!scr "censor - "
		!scr "chorus - "
		!scr "chrome - "
		!scr "cncd - "
		!scr "cpu - "
		!scr "crescent - "
		!scr "crest - "
		!scr "covert bitops - "
		!scr "defence force - "
		!scr "dekadence - "
		!scr "desire - "
		!scr "dac - "
		!scr "dmagic - "
		!scr "dualcrew - "
		!scr "exclusive on - "
		!scr "fairlight - "
		!scr "f4cg - "
		!scr "fire - "
		!scr "flat 3 - "
		!scr "focus - "
		!scr "french touch - "
		!scr "fsp - "
		!scr "genesis project - "
		!scr "gheymaid inc. - "
		!scr "hitmen - "
		!scr "hokuto force - "
		!scr "lod - "
		!scr "level64 - "
		!scr "mon - "
		!scr "mayday - "
		!scr "meanteam - "
		!scr "metalvotze - "
		!scr "noname - "
		!scr "nostalgia - "
		!scr "nuance - "
		!scr "offence - "
		!scr "onslaught - "
		!scr "orb - "
		!scr "oxyron - "
		!scr "padua - "
		!scr "performers - "
		!scr "plush - "
		!scr "ppcs - "
		!scr "psytronik - "
		!scr "reptilia - "
		!scr "resource - "
		!scr "rgcd - "
		!scr "secure - "
		!scr "shape - "
		!scr "side b - "
		!scr "singular - "
		!scr "slash - "
		!scr "slipstream - "
		!scr "success and trc - "
		!scr "style - "
		!scr "suicyco industries - "
		!scr "taquart - "
		!scr "tempest - "
		!scr "tek - "
		!scr "triad - "
		!scr "trsi - "
		!scr "viruz - "
		!scr "vision - "
		!scr "wow - "
		!scr "wrath "
		!scr "and xenon."
		!scr "      "
		!byte $00

; Lower scrolling message
scroll_text_2	!scr $82,"welcome to"
		!scr "    "
		!scr $81,"-- refix 2017 --"
		!scr "      "

		!scr $83,"an overhaul of the cosine intro i wrote during the "
		!scr "1990s which upgrades the logo resolution and expands "
		!scr "into the upper and lower borders whilst going completely "
		!scr "mental with the text colours!"
		!scr "      "

		!scr $84,"programming and graphics this time from t.m.r, "
		!scr "with dulcet tones provided by andy."
		!scr "      "

		!scr $83,"as always i don't have a lot to say - apart "
		!scr "from",$82,"happy new year",$83,"perhaps - but that's "
		!scr "not an issue because this intro is very tight on memory "
		!scr "(it finishes before 3fff) and there's not much space left "
		!scr "for text!"
		!scr "      "

		!scr $83,"there is still room for a quick plug of my personal "
		!scr "website",$81,"http://jasonkelk.me.uk/",$83,"and cosine's "
		!scr "at",$81,"http://cosine.org.uk/",$83,"and, since the "
		!scr "greetings are already taken care of in the other scroller..."
		!scr "      "

		!scr $85,"t.m.r of cosine, signing off on 20170101... .. .  ."
		!scr "            "
		!byte $00


; Pull in the $0400 screen (loads to that address in the uncompressed file)
		* = $0400
		!src "includes/screen.asm"

; All of the sprite position data moved to a spare page at $0800
		* = $0800
; Sprite position and pointer data :: upper border
sprite_pos_1	!byte $18,$10,$30,$10,$48,$10,$18,$10
		!byte $30,$10,$48,$10,$00,$00,$00,$00
		!byte $38

sprite_dp_1	!byte $b8,$b9,$ba,$bb,$bc,$bc,$00,$00

; Sprite position and pointer data :: first scroller
sprite_pos_2	!byte $30,$72,$26,$72,$40,$70,$70,$70
		!byte $a0,$70,$d0,$70,$00,$70,$00,$00
		!byte $42

sprite_dp_2	!byte $be,$bf,$bd,$bd,$bd,$bd,$bd,$bd

; Sprite position and pointer data :: first text line
sprite_pos_3	!byte $30,$92,$26,$92,$40,$90,$70,$90
		!byte $a0,$90,$d0,$90,$00,$90,$00,$00
		!byte $42

sprite_dp_3	!byte $c0,$c1,$bd,$bd,$bd,$bd,$bd,$bd

; Sprite position data :: second text line
sprite_pos_4	!byte $30,$aa,$26,$aa,$40,$a8,$70,$a8
		!byte $a0,$a8,$d0,$a8,$00,$a8,$00,$00
		!byte $42

; Sprite position and pointer data :: third text line
sprite_pos_5	!byte $30,$c2,$26,$c2,$40,$c0,$70,$c0
		!byte $a0,$c0,$d0,$c0,$00,$c0,$00,$00
		!byte $42

sprite_dp_5	!byte $c0,$c3,$bd,$bd,$bd,$bd,$bd,$bd

; Sprite position and pointer data :: second scroller
sprite_pos_6	!byte $30,$e2,$26,$e2,$40,$e0,$70,$e0
		!byte $a0,$e0,$d0,$e0,$00,$e0,$00,$00
		!byte $42


; Text for the three static lines
text_data_1	!scr " cosine present",$00
text_d016_1	= $10		; constant

text_data_2	!scr "-- refix 2017 --",$00
text_d016_2	= $14		; constant

text_data_3	!scr "   on 2017-01-01",$00
text_d016_3	= $10		; constant
