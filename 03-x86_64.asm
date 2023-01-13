; 描述符
; %macro Descriptor 3
%include "pm.inc.asm"
%include "pg.inc.asm"

%define GDTSelector(addr, RPL) ((GDT.%+addr-GDT) + RPL)
%define BaseOfLoaderPhyAddr 07c00H
%define GDTReal 0x8
%define GDTPtrReal 0x0
%define PGEntry 0x1000

ORG BaseOfLoaderPhyAddr
entry:
    jmp start16             ; 跳实模式处理程序
    align 16

GdtPtr  dw GdtLen         ; GDT界限
        dd 0x8            ; GDT基地址
        dw 0              ; 对齐
GDT:
    .DUMMY      Descriptor 0,           0,          0                            ; 空描述符
    .PAGE       Descriptor 0,           128*1024,   DA_DRW|DA_DPL0               ; 内存分页
    .CODE32     Descriptor 0,           Code32Len,  DA_CR|DA_32                  ; 32位代码段
    .CODE64     Descriptor 0,           0x0,        DA_CR|DESC_L           ; 64位代码段
    .VIDEO      Descriptor 0xB8000,     0xFFFF,     DA_DRW|DA_DPL0               ; 显存首地址
GdtLen  equ $ - GDT       ; GDT长度

start16:
    ; 清屏
    mov ah, 0x06            ; Scroll up
    mov al, 0               ; CLS
    mov bx, 0               ; Color          
    mov cx, 0               ; Start Position
    mov dx, 0x184f          ; End Position
    int 0x10

    ; 初始化16位栈寄存器
    mov ax, 0
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov sp, 0x7c00

    ; Gdt搬移
    mov ecx, GdtLen + 8
    lea si, [GdtPtr]
    lea di, [GDTPtrReal]
    rep movsb

    ; 初始化32位段描述符
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, start32
    mov [GDTReal + GDT.CODE32 - GDT + 2], ax
    shr eax, 16
    mov [GDTReal + GDT.CODE32 - GDT + 4], al
    mov [GDTReal + GDT.CODE32 - GDT + 7], ah

    ; 加载gdtr
    lgdt [GDTPtrReal]

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
    ; 初始化页表空间(0x1000:12K): 4-level; 高位地址和地位地址映射到同一片物理内存
    mov eax, GDTSelector(PAGE,SA_TIG|SA_RPL0)
    mov ds, eax
    mov ecx, 3*512*8
    mov eax, 0x0
    mov esi, 0x0
    rep stosb

    ; PML4: 低地址空间
    mov eax, PDE(PGEntry + 0x1000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x0000], eax
    mov eax, PDE(PGEntry + 0x1000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x0000 + 4], eax

    ; PML4: 高地址空间
    mov eax, PDE(PGEntry + 0x1000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x0FF8], eax
    mov eax, PDE(PGEntry + 0x1000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x0FF8 + 4], eax
    
    ; PDPE: 低地址空间
    mov eax, PDE(PGEntry + 0x2000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x1000], eax
    mov eax, PDE(PGEntry + 0x2000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x1000 + 4], eax
    
    ; PDPE: 高地址空间
    mov eax, PDE(PGEntry + 0x2000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x1FF8], eax
    mov eax, PDE(PGEntry + 0x2000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x1FF8 + 4], eax
    
    ; PDE: 低地址空间
    mov eax, PDE(PGEntry + 0x3000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x2000], eax
    mov eax, PDE(PGEntry + 0x3000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x2000 + 4], eax
    
    ; PDE: 高地址空间
    mov eax, PDE(PGEntry + 0x3000, (PG_RW|PG_S|PG_P))
    mov dword [PGEntry + 0x2FF8], eax
    mov eax, PDE(PGEntry + 0x3000, (PG_RW|PG_S|PG_P)) >> 32
    mov dword [PGEntry + 0x2FF8 + 4], eax

    ; PTE: 2M物理地址空间
    mov ecx, 0
memItem:
    mov eax, ecx
    shl eax, 12
    or eax, PG_RW|PG_S|PG_P
    mov dword [PGEntry + 0x3000 + ecx * 8], eax
    add ecx, 1
    cmp ecx, 512
    jne memItem

    mov eax, cr4
    or eax, 0b100000
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, PGEntry
    mov cr3, eax

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; 64位段中的 Base 和 Limit 不再有效，线地址扩展到64位
    jmp GDTSelector(CODE64,SA_TIG|SA_RPL0):start64
    jmp $

Code32Len equ $-start32

[bits 64]
start64:
    mov rax, GDTSelector(VIDEO,SA_TIG|SA_RPL0)
    mov gs, rax
    mov rdi, (80 * 10 + 20) * 2     ; Position
    mov ah, 0xC                     ; Color

    mov rcx, 0

    ; 模拟高位寻址
    LageMemPos equ 0xffffffffffe00000
    mov rsi, LageMemPos + HelloMsg
putChar:
    mov al, [rsi]
    mov [gs:rdi + rcx * 2], ax
    add rcx, 1
    add rsi, 1
    cmp rcx, HelloLen
    jne putChar
    
    jmp $

HelloMsg db "Hello, OS64 World!!!"
HelloLen equ $-HelloMsg
Code64Len equ $-start64

times 510-($-$$)    db 0
dw 0xaa55