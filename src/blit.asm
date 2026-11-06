; BLITCELLCGA, BLITCELLCGAMASKED, BLITCLIPPEDCGA, BLITCELLEGA, BLITCELLEGAMASKED, BLITCLIPPEDEGA, BLITCELLTANDY,
; BLITCELLTANDYMASKED, BLITCLIPPEDTANDY: the tile blitters Blit.BlitTileCell and BlitTileClipped choose by display mode.
; Copy draws tile tileIdx of gfx at (screenX, screenY) in dest, Mask draws it through gfx's transparency mask, and Clip,
; which also takes the save-under buffer and a flag, clips it to dest and records the rows it touched in SPANACTIVE,
; SPANY, SPANX0 and SPANX1 for Blit.FlushView.
DATA	SEGMENT WORD PUBLIC
	EXTRN	SPANACTIVE : BYTE
	EXTRN	SPANY : WORD
	EXTRN	SPANX0 : WORD
	EXTRN	SPANX1 : WORD
DATA	ENDS
DGROUP	GROUP	DATA
CODE	SEGMENT BYTE PUBLIC
	ASSUME	CS:CODE, DS:DGROUP
	PUBLIC	BLITCELLCGA
	PUBLIC	BLITCELLCGAMASKED
	PUBLIC	BLITCLIPPEDCGA
	PUBLIC	BLITCELLEGA
	PUBLIC	BLITCELLEGAMASKED
	PUBLIC	BLITCLIPPEDEGA
	PUBLIC	BLITCELLTANDY
	PUBLIC	BLITCELLTANDYMASKED
	PUBLIC	BLITCLIPPEDTANDY
BLITCELLCGA:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	shl	word ptr [bp-6],1
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCELLCGAMASKED:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	shl	word ptr [bp-6],1
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	mov	ax,word ptr es:[di+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr es:[di+15h]
	mov	word ptr [bp-2],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCLIPPEDCGA:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	push	ds
	lds	si,[bp+8]
	les	di,[bp+4]
	mov	ax,word ptr [si+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr [si+15h]
	mov	word ptr [bp-2],ax
	mov	ax,word ptr [bp+12h]
	cmp	ax,8000h
	jbe	L0150
	mov	word ptr [bp-18h],ax
	neg	word ptr [bp-18h]
	mov	word ptr [bp-14h],0
	jmp	short L0158
	nop
L0150:
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-14h],ax
L0158:
	add	ax,word ptr [si+2]
	cmp	word ptr es:[di+2],ax
	jae	L0170
	sub	ax,word ptr es:[di+2]
	mov	word ptr [bp-16h],ax
	mov	word ptr [bp-12h],0
	jmp	short L0182
	nop
L0170:
	mov	word ptr [bp-16h],0
	mov	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+12h]
	sub	ax,word ptr [si+2]
	mov	word ptr [bp-12h],ax
L0182:
	mov	ax,word ptr [bp+10h]
	cmp	ax,8000h
	jbe	L01AE
	neg	ax
	mov	cx,3
	shl	ax,cl
	mov	bx,word ptr [si]
	mov	word ptr [bp-0Ah],bx
	sub	word ptr [bp-0Ah],ax
	mov	bx,word ptr [si+2]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	mov	word ptr [bp-0Ch],0
	mov	word ptr [bp-8],0
	jmp	short L01DF
	nop
L01AE:
	mov	word ptr [bp-0Eh],0
	mov	cx,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-8]
	add	ax,word ptr [si]
	cmp	ax,word ptr es:[di]
	jbe	L01DA
	mov	ax,word ptr es:[di]
	sub	ax,word ptr [bp-8]
	mov	word ptr [bp-0Ah],ax
	jmp	short L01DF
	nop
L01DA:
	mov	ax,word ptr [si]
	mov	word ptr [bp-0Ah],ax
L01DF:
	mov	ax,word ptr [si+2]
	cmp	ax,word ptr [bp-18h]
	jb	L0207
	cmp	ax,word ptr [bp-16h]
	jb	L0207
	mov	ax,word ptr [bp-0Eh]
	cmp	ax,word ptr [si+11h]
	ja	L0207
	mov	ax,word ptr [bp-0Ch]
	cmp	ax,word ptr es:[di+11h]
	ja	L0207
	mov	ax,word ptr [bp-0Ah]
	cmp	ax,word ptr [si]
	ja	L0207
	jmp	short L0210
	nop
L0207:
	pop	ds
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L0210:
	mov	ax,word ptr [bp-14h]
	shl	ax,1
	mov	word ptr [bp-14h],ax
	mov	word ptr [bp-6],ax
	mov	ax,word ptr [si+2]
	sub	ax,word ptr [bp-18h]
	sub	ax,word ptr [bp-16h]
	shl	ax,1
	mov	word ptr [bp-10h],ax
	shl	word ptr [bp-18h],1
	shl	word ptr [bp-16h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-0Eh],1
	shl	word ptr [bp-0Ch],1
	mov	ax,word ptr [bp-0Eh]
	mov	word ptr [bp-1Ch],ax
	mov	ax,word ptr [si+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Eh]
	mul	bx
	add	word ptr [bp-0Eh],ax
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	pop	ds
	test	byte ptr [bp+0Ch],1
	jne	L0267
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L0267:
	mov	byte ptr [bp-1Ah],0
	test	byte ptr [bp+0Ch],4
	je	L0275
	mov	byte ptr [bp-1Ah],1
L0275:
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
BLITCELLEGA:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCELLEGAMASKED:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	mov	ax,word ptr es:[di+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr es:[di+15h]
	mov	word ptr [bp-2],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCLIPPEDEGA:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	push	ds
	lds	si,[bp+8]
	les	di,[bp+4]
	mov	ax,word ptr [si+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr [si+15h]
	mov	word ptr [bp-2],ax
	mov	ax,word ptr [bp+12h]
	cmp	ax,8000h
	jbe	L03E1
	mov	word ptr [bp-18h],ax
	neg	word ptr [bp-18h]
	mov	word ptr [bp-14h],0
	jmp	short L03E9
	nop
L03E1:
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-14h],ax
L03E9:
	add	ax,word ptr [si+2]
	cmp	word ptr es:[di+2],ax
	jae	L0401
	sub	ax,word ptr es:[di+2]
	mov	word ptr [bp-16h],ax
	mov	word ptr [bp-12h],0
	jmp	short L0413
	nop
L0401:
	mov	word ptr [bp-16h],0
	mov	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+12h]
	sub	ax,word ptr [si+2]
	mov	word ptr [bp-12h],ax
L0413:
	mov	ax,word ptr [bp+10h]
	cmp	ax,8000h
	jbe	L043F
	neg	ax
	mov	cx,3
	shl	ax,cl
	mov	bx,word ptr [si]
	mov	word ptr [bp-0Ah],bx
	sub	word ptr [bp-0Ah],ax
	mov	bx,word ptr [si+2]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	mov	word ptr [bp-0Ch],0
	mov	word ptr [bp-8],0
	jmp	short L0470
	nop
L043F:
	mov	word ptr [bp-0Eh],0
	mov	cx,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-8]
	add	ax,word ptr [si]
	cmp	ax,word ptr es:[di]
	jbe	L046B
	mov	ax,word ptr es:[di]
	sub	ax,word ptr [bp-8]
	mov	word ptr [bp-0Ah],ax
	jmp	short L0470
	nop
L046B:
	mov	ax,word ptr [si]
	mov	word ptr [bp-0Ah],ax
L0470:
	mov	ax,word ptr [si+2]
	cmp	ax,word ptr [bp-18h]
	jb	L0498
	cmp	ax,word ptr [bp-16h]
	jb	L0498
	mov	ax,word ptr [bp-0Eh]
	cmp	ax,word ptr [si+11h]
	ja	L0498
	mov	ax,word ptr [bp-0Ch]
	cmp	ax,word ptr es:[di+11h]
	ja	L0498
	mov	ax,word ptr [bp-0Ah]
	cmp	ax,word ptr [si]
	ja	L0498
	jmp	short L04A1
	nop
L0498:
	pop	ds
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L04A1:
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	mov	ax,word ptr [bp-14h]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr [si+2]
	sub	ax,word ptr [bp-18h]
	sub	ax,word ptr [bp-16h]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	shl	word ptr [bp-18h],1
	shl	word ptr [bp-18h],1
	shl	word ptr [bp-16h],1
	shl	word ptr [bp-16h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-0Eh],1
	shl	word ptr [bp-0Eh],1
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	ax,word ptr [bp-0Eh]
	mov	word ptr [bp-1Ch],ax
	mov	ax,word ptr [si+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Eh]
	mul	bx
	add	word ptr [bp-0Eh],ax
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	pop	ds
	test	byte ptr [bp+0Ch],1
	jne	L050E
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L050E:
	mov	byte ptr [bp-1Ah],0
	test	byte ptr [bp+0Ch],4
	je	L051C
	mov	byte ptr [bp-1Ah],1
L051C:
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
BLITCELLTANDY:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	shl	word ptr [bp-6],1
	shl	word ptr [bp-6],1
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCELLTANDYMASKED:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	les	di,[bp+4]
	mov	ax,word ptr [bp+0Eh]
	mov	cl,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp+10h]
	mov	word ptr [bp-14h],ax
	mov	ax,word ptr es:[di+2]
	les	di,[bp+8]
	sub	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+10h]
	mov	word ptr [bp-12h],ax
	mov	ax,word ptr [bp-14h]
	mov	word ptr [bp-6],ax
	shl	word ptr [bp-6],1
	shl	word ptr [bp-6],1
	mov	ax,word ptr es:[di+2]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	mov	ax,word ptr es:[di]
	mov	word ptr [bp-0Ah],ax
	mov	ax,word ptr es:[di+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr es:[di+15h]
	mov	word ptr [bp-2],ax
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-14h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	mov	ax,word ptr es:[di+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Ch]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-16h],0
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	0Eh
BLITCLIPPEDTANDY:
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	sub	sp,1Ch
	push	ss
	push	ds
	cld
	push	ds
	lds	si,[bp+8]
	les	di,[bp+4]
	mov	ax,word ptr [si+13h]
	mov	word ptr [bp-4],ax
	mov	ax,word ptr [si+15h]
	mov	word ptr [bp-2],ax
	mov	ax,word ptr [bp+12h]
	cmp	ax,8000h
	jbe	L0693
	mov	word ptr [bp-18h],ax
	neg	word ptr [bp-18h]
	mov	word ptr [bp-14h],0
	jmp	short L069B
	nop
L0693:
	mov	word ptr [bp-18h],0
	mov	word ptr [bp-14h],ax
L069B:
	add	ax,word ptr [si+2]
	cmp	word ptr es:[di+2],ax
	jae	L06B3
	sub	ax,word ptr es:[di+2]
	mov	word ptr [bp-16h],ax
	mov	word ptr [bp-12h],0
	jmp	short L06C5
	nop
L06B3:
	mov	word ptr [bp-16h],0
	mov	ax,word ptr es:[di+2]
	sub	ax,word ptr [bp+12h]
	sub	ax,word ptr [si+2]
	mov	word ptr [bp-12h],ax
L06C5:
	mov	ax,word ptr [bp+10h]
	cmp	ax,8000h
	jbe	L06F1
	neg	ax
	mov	cx,3
	shl	ax,cl
	mov	bx,word ptr [si]
	mov	word ptr [bp-0Ah],bx
	sub	word ptr [bp-0Ah],ax
	mov	bx,word ptr [si+2]
	mul	bx
	mov	word ptr [bp-0Eh],ax
	mov	word ptr [bp-0Ch],0
	mov	word ptr [bp-8],0
	jmp	short L0722
	nop
L06F1:
	mov	word ptr [bp-0Eh],0
	mov	cx,3
	shl	ax,cl
	mov	word ptr [bp-8],ax
	mov	bx,word ptr es:[di+2]
	mul	bx
	mov	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-8]
	add	ax,word ptr [si]
	cmp	ax,word ptr es:[di]
	jbe	L071D
	mov	ax,word ptr es:[di]
	sub	ax,word ptr [bp-8]
	mov	word ptr [bp-0Ah],ax
	jmp	short L0722
	nop
L071D:
	mov	ax,word ptr [si]
	mov	word ptr [bp-0Ah],ax
L0722:
	mov	ax,word ptr [si+2]
	cmp	ax,word ptr [bp-18h]
	jb	L074A
	cmp	ax,word ptr [bp-16h]
	jb	L074A
	mov	ax,word ptr [bp-0Eh]
	cmp	ax,word ptr [si+11h]
	ja	L074A
	mov	ax,word ptr [bp-0Ch]
	cmp	ax,word ptr es:[di+11h]
	ja	L074A
	mov	ax,word ptr [bp-0Ah]
	cmp	ax,word ptr [si]
	ja	L074A
	jmp	short L0753
	nop
L074A:
	pop	ds
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L0753:
	mov	ax,word ptr [bp-14h]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-14h],ax
	mov	word ptr [bp-6],ax
	mov	ax,word ptr [si+2]
	sub	ax,word ptr [bp-18h]
	sub	ax,word ptr [bp-16h]
	shl	ax,1
	shl	ax,1
	mov	word ptr [bp-10h],ax
	shl	word ptr [bp-18h],1
	shl	word ptr [bp-18h],1
	shl	word ptr [bp-16h],1
	shl	word ptr [bp-16h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-12h],1
	shl	word ptr [bp-0Eh],1
	shl	word ptr [bp-0Eh],1
	shl	word ptr [bp-0Ch],1
	shl	word ptr [bp-0Ch],1
	mov	ax,word ptr [bp-0Eh]
	mov	word ptr [bp-1Ch],ax
	mov	ax,word ptr [si+11h]
	xor	bx,bx
	mov	bl,byte ptr [bp+0Eh]
	mul	bx
	add	word ptr [bp-0Eh],ax
	mov	bx,word ptr [bp-8]
	mov	cx,word ptr [bp-0Ah]
	mov	byte ptr [bp-1Ah],0
	pop	ds
	test	byte ptr [bp+0Ch],1
	jne	L07BD
	call	L07D6
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L07BD:
	mov	byte ptr [bp-1Ah],0
	test	byte ptr [bp+0Ch],4
	je	L07CB
	mov	byte ptr [bp-1Ah],1
L07CB:
	call	L0835
	pop	ds
	pop	ss
	mov	sp,bp
	pop	bp
	ret	14h
L07D6:
	mov	SPANACTIVE[bx],1
	shl	bx,1
	mov	ax,word ptr [bp-14h]
	add	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-0Ch]
	cmp	ax,SPANX0[bx]
	ja	L07F7
	mov	SPANX0[bx],ax
	mov	ax,word ptr [bp-6]
	mov	SPANY[bx],ax
L07F7:
	push	ds
	lds	si,[bp+8]
	les	di,[bp+4]
	add	si,17h
	add	si,word ptr [bp-0Eh]
	add	di,17h
	add	di,word ptr [bp-0Ch]
	push	cx
	mov	cx,word ptr [bp-10h]
	rep movsb
	pop	cx
	pop	ds
	mov	ax,word ptr [bp-10h]
	add	word ptr [bp-0Eh],ax
	add	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-0Ch]
	dec	ax
	cmp	ax,SPANX1[bx]
	jb	L0829
	mov	SPANX1[bx],ax
L0829:
	mov	ax,word ptr [bp-12h]
	add	word ptr [bp-0Ch],ax
	shr	bx,1
	inc	bx
	loop	L07D6
	ret
L0835:
	mov	SPANACTIVE[bx],1
	shl	bx,1
	mov	ax,word ptr [bp-18h]
	add	word ptr [bp-0Eh],ax
	mov	ax,word ptr [bp-14h]
	add	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-0Ch]
	cmp	ax,SPANX0[bx]
	jae	L085C
	mov	SPANX0[bx],ax
	mov	ax,word ptr [bp-6]
	mov	SPANY[bx],ax
L085C:
	push	ds
	les	di,[bp+4]
	add	di,word ptr [bp-0Ch]
	push	cx
	mov	cx,word ptr [bp-10h]
L0867:
	cmp	byte ptr [bp-1Ah],0
	je	L087A
	lds	si,[bp+14h]
	add	si,word ptr [bp-1Ch]
	mov	al,byte ptr es:[di+17h]
	mov	byte ptr [si+17h],al
L087A:
	lds	si,[bp-4]
	add	si,word ptr [bp-0Eh]
	mov	ah,byte ptr [si]
	lds	si,[bp+8]
	add	si,word ptr [bp-0Eh]
	mov	al,byte ptr [si+17h]
	and	byte ptr es:[di+17h],ah
	or	byte ptr es:[di+17h],al
	inc	word ptr [bp-0Eh]
	inc	word ptr [bp-1Ch]
	inc	word ptr [bp-0Ch]
	inc	di
	loop	L0867
	pop	cx
	pop	ds
	mov	ax,word ptr [bp-0Ch]
	dec	ax
	cmp	ax,SPANX1[bx]
	jbe	L08AF
	mov	SPANX1[bx],ax
L08AF:
	mov	ax,word ptr [bp-12h]
	add	word ptr [bp-0Ch],ax
	mov	ax,word ptr [bp-16h]
	add	word ptr [bp-0Eh],ax
	add	word ptr [bp-1Ch],ax
	shr	bx,1
	inc	bx
	dec	cx
	je	L08C7
	jmp	L0835
L08C7:
	ret
CODE	ENDS
	END
