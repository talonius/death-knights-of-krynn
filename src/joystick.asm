; ReadJoystick(joy; var xRaw, yRaw: Word; var buttons: Byte): Boolean, far, Pascal order. joy must be 1 or 2,
; else False. Fires the port $201 one-shots and counts until the stick's x bit drops, then pads the count out
; to $1FFF with a delay loop so a read takes the same time wherever the stick is; waits for y to settle, fires
; again and counts y the same way. Buttons are the port's top nibble, inverted (1 = down) and shifted down by
; 4. False when a count runs out. Note: a y count above $1FFF jumps to xStore, which stores it in xRaw and
; measures the next bit.
CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE
        PUBLIC  READJOYSTICK
READJOYSTICK    PROC FAR
        push    bp
        mov     bp,sp
        cmp     byte ptr [bp+12h],1
        jz      valid
        cmp     byte ptr [bp+12h],2
        jz      valid
        mov     al,0
        pop     bp
        ret     0Eh
valid:
        mov     ah,1
        xor     bx,bx
        cmp     byte ptr [bp+12h],2
        jnz     m_set
        shl     ah,1
        shl     ah,1
m_set:
        mov     bx,1
        xor     cx,cx
        mov     al,0FFh
        mov     dx,201h
        out     dx,al
xLoop:
        in      al,dx
        not     al
        test    al,ah
        jnz     xDone
        inc     bx
        loop    xLoop
        mov     al,0
        pop     bp
        ret     0Eh
xDone:
        mov     cx,1FFFh
        sub     cx,bx
        jc      xStore
        loop    $
xStore:
        les     di,[bp+0Eh]
        mov     es:[di],bx
        shl     ah,1
        xor     cx,cx
yLoop:
        in      al,dx
        not     al
        test    al,ah
        jnz     yPre
        loop    yLoop
        mov     al,0
        pop     bp
        ret     0Eh
yPre:
        mov     bx,1
        xor     cx,cx
        mov     al,0FFh
        out     dx,al
yLoop2:
        in      al,dx
        not     al
        test    al,ah
        jnz     yDone
        inc     bx
        loop    yLoop2
        mov     al,0
        pop     bp
        ret     0Eh
yDone:
        mov     cx,1FFFh
        sub     cx,bx
        jc      xStore
        loop    $
        les     di,[bp+0Ah]
        mov     es:[di],bx
        shr     ah,1
        xor     cx,cx
bLoop:
        in      al,dx
        not     al
        test    al,ah
        jnz     bDone
        loop    bLoop
        mov     al,0
        pop     bp
        ret     0Eh
bDone:
        mov     cx,4
        shr     al,cl
        les     di,[bp+06h]
        mov     es:[di],al
        mov     al,1
        pop     bp
        ret     0Eh
READJOYSTICK    ENDP
CODE    ENDS
        END
