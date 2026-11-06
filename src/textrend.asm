; CGAGLYPH, EGAGLYPH, TANDYGLYPH(col, row: Word; fg, bg, charIdx: Byte), near, Pascal order: each draws the 8x8
; glyph TextRend.RenderChar has copied into CURRENTGLYPH at character cell (col, row) in fg on bg -- CGA
; at $B800 with the colors mapped through CGAATTRIBUTECOLORS, EGA at $A000 through the graphics
; controller, Tandy at $B800.
DATA    SEGMENT WORD PUBLIC
        EXTRN   CURRENTGLYPH : BYTE
        EXTRN   CGAATTRIBUTECOLORS : BYTE
DATA    ENDS
DGROUP  GROUP   DATA
CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE, DS:DGROUP
        PUBLIC  CGAGLYPH, EGAGLYPH, TANDYGLYPH
CGAGLYPH PROC NEAR
        push    bp
        mov     bp,sp
        push    ss
        push    ds
        mov     ax,[bp+0Ah]
        mov     bx,140h
        mul     bx
        mov     bx,[bp+0Ch]
        shl     bx,1
        add     ax,bx
        mov     di,ax
        xor     bx,bx
        mov     bl,[bp+08h]
        mov     dl,CGAATTRIBUTECOLORS[bx]
        mov     bl,[bp+06h]
        mov     dh,CGAATTRIBUTECOLORS[bx]
        xor     bx,bx
        mov     ah,1
        mov     cx,4
cga_outer:
        push    cx
        mov     cx,0B800h
        mov     es,cx
        mov     cx,2
        inc     di
cga_evn_mid:
        push    cx
        mov     cx,4
        mov     al,0
cga_evn:
        test    CURRENTGLYPH[bx],ah
        jz      cga_evn0
        or      al,dl
        jmp     cga_evn1
cga_evn0:
        or      al,dh
cga_evn1:
        rol     dl,1
        rol     dl,1
        rol     dh,1
        rol     dh,1
        rol     ah,1
        loop    cga_evn
        mov     es:[di],al
        dec     di
        pop     cx
        loop    cga_evn_mid
        inc     bx
        inc     di
        mov     ah,1
        mov     al,0
        mov     cx,0BA00h
        mov     es,cx
        mov     cx,2
        inc     di
cga_odd_mid:
        push    cx
        mov     cx,4
        mov     al,0
cga_odd:
        test    CURRENTGLYPH[bx],ah
        jz      cga_odd0
        or      al,dl
        jmp     cga_odd1
cga_odd0:
        or      al,dh
cga_odd1:
        rol     dl,1
        rol     dl,1
        rol     dh,1
        rol     dh,1
        rol     ah,1
        loop    cga_odd
        mov     es:[di],al
        dec     di
        pop     cx
        loop    cga_odd_mid
        inc     bx
        add     di,51h
        pop     cx
        loop    cga_outer
        pop     ds
        pop     ss
        pop     bp
        ret     0Ah
CGAGLYPH ENDP
EGAGLYPH PROC NEAR
        push    bp
        mov     bp,sp
        push    ss
        push    ds
        mov     ax,0A000h
        mov     es,ax
        mov     ax,[bp+0Ah]
        mov     bx,140h
        mul     bx
        add     ax,[bp+0Ch]
        mov     di,ax
        mov     dx,3CEh
        mov     ax,0A05h
        out     dx,ax
        mov     ah,0
        mov     al,3
        out     dx,ax
        mov     ax,7
        out     dx,ax
        xor     bx,bx
        mov     cx,8
ega_row:
        mov     ah,CURRENTGLYPH[bx]
        mov     al,8
        out     dx,ax
        mov     al,[bp+08h]
        and     es:[di],al
        not     ah
        mov     al,8
        out     dx,ax
        mov     al,[bp+06h]
        and     es:[di],al
        add     di,28h
        inc     bx
        loop    ega_row
        mov     ax,5
        out     dx,ax
        mov     ax,0FF08h
        out     dx,ax
        mov     ax,3
        out     dx,ax
        mov     ax,0F07h
        out     dx,ax
        pop     ds
        pop     ss
        pop     bp
        ret     0Ah
EGAGLYPH ENDP
TANDYGLYPH PROC NEAR
        push    bp
        mov     bp,sp
        push    ss
        push    ds
        mov     ax,[bp+0Ah]
        mov     bx,140h
        mul     bx
        mov     bx,[bp+0Ch]
        shl     bx,1
        shl     bx,1
        add     ax,bx
        mov     di,ax
        mov     dl,[bp+06h]
        mov     dh,[bp+08h]
        xor     bx,bx
        mov     ah,1
        mov     cx,2
tdy_outer:
        push    cx
        mov     cx,0B800h
        mov     es,cx
        mov     cx,4
        add     di,3
tdy_b0_mid:
        push    cx
        mov     cx,2
        mov     al,0
tdy_b0:
        test    CURRENTGLYPH[bx],ah
        jz      tdy_b0z
        or      al,dh
        jmp     tdy_b0c
tdy_b0z:
        or      al,dl
tdy_b0c:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_b0
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_b0_mid
        add     di,4
        inc     bx
        mov     cx,0BA00h
        mov     es,cx
        mov     cx,4
tdy_b1_mid:
        push    cx
        mov     cx,2
        mov     al,0
tdy_b1:
        test    CURRENTGLYPH[bx],ah
        jz      tdy_b1z
        or      al,dh
        jmp     tdy_b1c
tdy_b1z:
        or      al,dl
tdy_b1c:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_b1
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_b1_mid
        add     di,4
        inc     bx
        mov     cx,0BC00h
        mov     es,cx
        mov     cx,4
tdy_b2_mid:
        push    cx
        mov     cx,2
        mov     al,0
tdy_b2:
        test    CURRENTGLYPH[bx],ah
        jz      tdy_b2z
        or      al,dh
        jmp     tdy_b2c
tdy_b2z:
        or      al,dl
tdy_b2c:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_b2
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_b2_mid
        add     di,4
        inc     bx
        mov     cx,0BE00h
        mov     es,cx
        mov     cx,4
tdy_b3_mid:
        push    cx
        mov     cx,2
        mov     al,0
tdy_b3:
        test    CURRENTGLYPH[bx],ah
        jz      tdy_b3z
        or      al,dh
        jmp     tdy_b3c
tdy_b3z:
        or      al,dl
tdy_b3c:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_b3
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_b3_mid
        inc     bx
        add     di,0A1h
        pop     cx
        dec     cx
        jz      tdy_done
        jmp     tdy_outer
tdy_done:
        pop     ds
        pop     ss
        pop     bp
        ret     0Ah
TANDYGLYPH ENDP
CODE    ENDS
        END
