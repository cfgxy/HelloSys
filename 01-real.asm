; 实模式用BIOS中断打印Hello world
; nasm 编译后用 bochs 启动
; 参考文档:
; docs/自己动手写操作系统完全版.pdf

ORG 07c00H

mov ax, cs
mov ds, ax
mov es, ax
call DispStr
jmp $

DispStr:
mov ax, BootMessage
mov bp, ax
mov cx, 23
mov ax, 01301h
mov bx, 000ch
mov dl, 0
int 10h
ret

BootMessage:        db "Hello, OS world!!!!!!!"
times 510-($-$$)    db 0

dw 0xaa55