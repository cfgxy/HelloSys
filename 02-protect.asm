; 描述符
; %macro Descriptor 3
%include "pm.inc.asm"
%define GDTSelector(addr, RPL) ((GDT.%+addr-GDT) + RPL)
%define BaseOfLoaderPhyAddr 07c00H

ORG BaseOfLoaderPhyAddr
entry:
    jmp start16             ; 跳实模式处理程序
    align 16

GDT:
    .DUMMY      Descriptor 0,           0,          0                            ; 空描述符
    .CODE32     Descriptor 0,           Code32Len,  DA_CR|DA_32                  ; 32位代码段
    .CODE64     Descriptor 0,           Code64Len,  DA_CR|DESC_L                 ; 64位代码段
    .VIDEO      Descriptor 0xB8000,     0xFFFF,     DA_DRW|DA_DPL0               ; 显存首地址
GdtLen  equ $ - GDT       ; GDT长度
GdtPtr  dw GdtLen         ; GDT界限
        dd 0              ; GDT基地址

start16:
    ; 清屏
    mov ah, 0x06            ; Scroll up
    mov al, 0               ; CLS
    mov bx, 0               ; Color          
    mov cx, 0               ; Start Position
    mov dx, 0x184f          ; End Position
    int 0x10

    ; 初始化16位栈寄存器
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov sp, 0x7c00

    ; 初始化32位段描述符
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, start32
    mov [GDT.CODE32+2], ax
    shr eax, 16
    mov [GDT.CODE32+4], al
    mov [GDT.CODE32+7], ah

    ; 加载gdtr
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, GDT
    mov [GdtPtr+2], eax
    lgdt [GdtPtr]

    ; 开A20地址线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    ; 关中断
    cli

    ; 切换到保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp dword GDTSelector(CODE32,SA_TIG|SA_RPL0):0
    jmp $

[bits 32]
start32:
    mov ax, GDTSelector(VIDEO,SA_TIG|SA_RPL0)
    mov gs, ax
    mov edi, (80 * 10 + 20) * 2     ; Position
    mov ah, 0xC                     ; Color

    mov ecx, 0

putChar:
    mov al, [HelloMsg + ecx]
    mov [gs:edi + ecx * 2], ax
    add ecx, 1
    cmp ecx, HelloLen
    jne putChar
    
    jmp $

HelloMsg db "Hello, OS32 World!!!"
HelloLen equ $-HelloMsg

Code32Len equ $-start32



[bits 64]
start64:
    jmp $

Hello64Msg db "Hello, OS64 World!!!"
Hello64Len equ $-HelloMsg

Code64Len equ $-start64

times 510-($-$$)    db 0
dw 0xaa55