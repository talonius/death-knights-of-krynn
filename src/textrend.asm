; RENDERCHARCGA, RENDERCHAREGA, RENDERCHARTANDY(col, row: Word; fg, bg, glyphIdx: Byte), near, Pascal
; order: each draws the 8x8 glyph TextRend.RenderChar has copied into CURRENTGLYPH at character cell (col,
; row) in fg on bg -- CGA at $B800 with the colors mapped through CGAATTRIBUTECOLORS, EGA at $A000 through the
; graphics controller, Tandy at $B800.
DGROUP  GROUP   DATA
DATA    SEGMENT WORD PUBLIC
        EXTRN   CURRENTGLYPH:BYTE
        EXTRN   CGAATTRIBUTECOLORS:BYTE
DATA    ENDS
CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE, DS:DGROUP
        PUBLIC  RENDERCHARCGA
        PUBLIC  RENDERCHAREGA
        PUBLIC  RENDERCHARTANDY
RENDERCHARCGA   PROC NEAR
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
        mov     bl,[bp+8]
        mov     dl,[bx+CGAATTRIBUTECOLORS]
        mov     bl,[bp+6]
        mov     dh,[bx+CGAATTRIBUTECOLORS]
        xor     bx,bx
        mov     ah,1
        mov     cx,4
cga_outer:
        push    cx
        mov     cx,0B800h
        mov     es,cx
        mov     cx,2
        inc     di
cga_midA:
        push    cx
        mov     cx,4
        mov     al,0
cga_innerA:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      cga_skipA
        or      al,dl
        jmp     short cga_afterA
        nop
cga_skipA:
        or      al,dh
cga_afterA:
        rol     dl,1
        rol     dl,1
        rol     dh,1
        rol     dh,1
        rol     ah,1
        loop    cga_innerA
        mov     es:[di],al
        dec     di
        pop     cx
        loop    cga_midA
        inc     bx
        inc     di
        mov     ah,1
        mov     al,0
        mov     cx,0BA00h
        mov     es,cx
        mov     cx,2
        inc     di
cga_midB:
        push    cx
        mov     cx,4
        mov     al,0
cga_innerB:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      cga_skipB
        or      al,dl
        jmp     short cga_afterB
        nop
cga_skipB:
        or      al,dh
cga_afterB:
        rol     dl,1
        rol     dl,1
        rol     dh,1
        rol     dh,1
        rol     ah,1
        loop    cga_innerB
        mov     es:[di],al
        dec     di
        pop     cx
        loop    cga_midB
        inc     bx
        add     di,51h
        pop     cx
        loop    cga_outer
        pop     ds
        pop     ss
        pop     bp
        ret     0Ah
RENDERCHARCGA   ENDP
RENDERCHAREGA   PROC NEAR
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
        mov     ah,[bx+CURRENTGLYPH]
        mov     al,8
        out     dx,ax
        mov     al,[bp+8]
        and     es:[di],al
        not     ah
        mov     al,8
        out     dx,ax
        mov     al,[bp+6]
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
RENDERCHAREGA   ENDP
RENDERCHARTANDY PROC NEAR
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
        mov     dl,[bp+6]
        mov     dh,[bp+8]
        xor     bx,bx
        mov     ah,1
        mov     cx,2
tdy_bank:
        push    cx
        mov     cx,0B800h
        mov     es,cx
        mov     cx,4
        add     di,3
tdy_colB0:
        push    cx
        mov     cx,2
        mov     al,0
tdy_rowB0:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      tdy_sB0
        or      al,dh
        jmp     short tdy_aB0
        nop
tdy_sB0:
        or      al,dl
tdy_aB0:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_rowB0
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_colB0
        add     di,4
        inc     bx
        mov     cx,0BA00h
        mov     es,cx
        mov     cx,4
tdy_colB1:
        push    cx
        mov     cx,2
        mov     al,0
tdy_rowB1:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      tdy_sB1
        or      al,dh
        jmp     short tdy_aB1
        nop
tdy_sB1:
        or      al,dl
tdy_aB1:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_rowB1
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_colB1
        add     di,4
        inc     bx
        mov     cx,0BC00h
        mov     es,cx
        mov     cx,4
tdy_colB2:
        push    cx
        mov     cx,2
        mov     al,0
tdy_rowB2:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      tdy_sB2
        or      al,dh
        jmp     short tdy_aB2
        nop
tdy_sB2:
        or      al,dl
tdy_aB2:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_rowB2
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_colB2
        add     di,4
        inc     bx
        mov     cx,0BE00h
        mov     es,cx
        mov     cx,4
tdy_colB3:
        push    cx
        mov     cx,2
        mov     al,0
tdy_rowB3:
        test    byte ptr [bx+CURRENTGLYPH],ah
        je      tdy_sB3
        or      al,dh
        jmp     short tdy_aB3
        nop
tdy_sB3:
        or      al,dl
tdy_aB3:
        push    cx
        mov     cx,4
        rol     dl,cl
        mov     cx,4
        rol     dh,cl
        rol     ah,1
        pop     cx
        loop    tdy_rowB3
        mov     es:[di],al
        dec     di
        pop     cx
        loop    tdy_colB3
        inc     bx
        add     di,0A1h
        pop     cx
        dec     cx
        je      tdy_done
        jmp     tdy_bank
tdy_done:
        pop     ds
        pop     ss
        pop     bp
        ret     0Ah
RENDERCHARTANDY ENDP
CODE    ENDS
        END
