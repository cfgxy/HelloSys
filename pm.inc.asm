; 描述符
; Usage: Descriptor Base, Limit, Attr
; https://www.cnblogs.com/thotf/p/16289706.html
; https://blog.csdn.net/abc123lzf/article/details/109289567
; https://www.cnblogs.com/TJTO/p/11414726.html
; https://www.cnblogs.com/yilang/p/11322645.html 80286-GDT字节不连续的历史原因
; 64bit(小端序):
; | 63-56(1B): 段基地址H | 55-52(4b): 属性2 | 51-48(4b): 段界限H | 47-40(1B): 属性1 | 39-16(3B): 段基地址L | 15-0(2B): 段界限L |
;
; 段基地址: 32bit
; 段界限: 20bit
; 属性: 12bit
;
; 属性1: | 47: P | 46-45(2b): DPL | 44: S | 43-40(4b): TYPE |
; 属性2: | 55: G | 54: D/B | 53: L | 52: AVL |
; P: P=0段不存在内存中 P=1段存在内存中
; DPL: 特权级别 0~3
; S: S=0系统段 S=1数据段/代码段
; TYPE:
;   b40: =0表示数据段 =1表示代码段
;   数据段:
;   b41: =0向上增长 =1向下增长(栈)
;   b42: =0只读 =1读写
;   b43: =0未被访问过 =1被访问过
;   代码段:
;   b41: =0特权级严格一致 =1当前特权级<=段DPL时可访问
;   b42: =0只能执行 =1可读可执行
;   b43: =0未被访问过 =1被访问过
; G: =0段界限粒度为字节 =1段界限粒度为4KB (20bit+12bit=32bit=4GB界限空间)
; D/B: 
;   代码段(S=1, TYPE.b40=1):
;   表示D属性, =1为32位代码段 =1位16位代码段
;   栈段(SS指向的数据段):
;   表示B属性, =1时用32位堆栈指针寄存器ESP, =0时用16位堆栈指针寄存器SP
;   向下扩展数据段:
;   表示B属性, =1时段界限上限为4G, =0时段界限上限为64K
; L: =1表示该段为64位代码段; D属性必须=0
; AVL: 操作系统自定义

%macro Descriptor 3
    dw %2 & 0xFFFF          ; 段界限L
    dw %1 & 0xFFFF          ; 段基地址L1
    db (%1 >> 16) & 0xFF    ; 段基地址L2
    dw ((%2 >> 8)) & 0xF00 | ((%3) & 0xF0FF) ; 属性2 + 段界限H + 属性1
    db (%1 >> 24) & 0xFF    ; 段基地址H
%endmacro

;----------------------------
;gdt描述符属性
DESC_G_4K   equ               1000_0000_00000000b
DESC_D_32   equ               0100_0000_00000000b
DESC_L      equ               0010_0000_00000000b
DESC_AVL    equ               0001_0000_00000000b
DESC_P      equ               0000_0000_10000000b
DESC_DPL_0  equ               0000_0000_00000000b
DESC_DPL_1  equ               0000_0000_00100000b
DESC_DPL_2  equ               0000_0000_01000000b
DESC_DPL_3  equ               0000_0000_01100000b
DESC_S_CODE equ               0000_0000_00010000b
DESC_S_DATA equ               DESC_S_CODE
DESC_S_SYS  equ               0000_0000_00000000b
DESC_TYPE_ACCESSED equ        0000_0000_00000001b
DESC_TYPE_CODE  equ           0000_0000_00001000b    ;x=1,c=0,r=0,a=0 代码段是可执行的,非依从>的,不可读的,已访问位a清0.
DESC_TYPE_CODE_RING_EQ equ    0000_0000_00000100b
DESC_TYPE_CODE_RE equ         0000_0000_00000010b
DESC_TYPE_DATA  equ           0000_0000_00000000b    ;x=0,e=0,w=1,a=0 数据段是不可执行的,向上>扩展的,可写的,已访问位a清0.
DESC_TYPE_DATA_DOWN equ       0000_0000_00000100b
DESC_TYPE_DATA_RW equ         0000_0000_00000010b


; 描述符类型
DA_32       EQU     DESC_D_32
DA_LIMIT_4K EQU     DESC_G_4K
; DPL
DA_DPL0     EQU     DESC_DPL_0
DA_DPL1     EQU     DESC_DPL_1
DA_DPL2     EQU     DESC_DPL_2
DA_DPL3     EQU     DESC_DPL_3

; 存储段描述类型
; D - data
; C - code
DA_DR       EQU     DESC_P|DESC_S_DATA|DESC_TYPE_DATA   ; 只读数据
DA_DRW      EQU     DA_DR|DESC_TYPE_DATA_RW             ; 可读写
DA_DRWA     EQU     DA_DRW|DESC_TYPE_ACCESSED           ; 已访问可读写
DA_C        EQU     DESC_P|DESC_S_CODE|DESC_TYPE_CODE   ; 只执行
DA_CR       EQU     DA_C|DESC_TYPE_CODE_RE              ; 可执行可读写
DA_CCO      EQU     DA_C|DESC_TYPE_CODE_RING_EQ         ; 只执行一致代码段
DA_CCOR     EQU     DA_CR|DESC_TYPE_CODE_RING_EQ        ; 可执行可读一致代码段

; 系统段描述类型
DA_SYS      EQU     DESC_P|DESC_S_DATA
DA_286TSS   EQU     DA_SYS|0x1         ; 可用286任务状态段
DA_LDT      EQU     DA_SYS|0x2         ; 局部描述符
DA_286TSS_Busy EQU  DA_SYS|0x3         ; 忙的286任务状态段
DA_286CGate EQU     DA_SYS|0x4         ; 286调用门
DA_TaskGate EQU     DA_SYS|0x5         ; 任务门
DA_286IGate EQU     DA_SYS|0x6         ; 286中断门
DA_286TGate EQU     DA_SYS|0x7         ; 286陷阱门
DA_386TSS   EQU     DA_SYS|0x9         ; 可用386任务状态段
DA_386TSS_Busy EQU  DA_SYS|0xB         ; 忙的386任务状态段
DA_386CGate EQU     DA_SYS|0xC         ; 386调用门
DA_386IGate EQU     DA_SYS|0xE         ; 386中断门
DA_386TGate EQU     DA_SYS|0xF         ; 386陷阱门

; 选择子
SA_RPL0     EQU     0
SA_RPL1     EQU     1
SA_RPL2     EQU     2
SA_RPL3     EQU     3

SA_TIG      EQU     0
SA_TIL      EQU     4

; 分页机制使用的常量
PG_P        EQU     1   ; 页存在
PG_RWR      EQU     0   ; R/W 读/执行
PG_RWW      EQU     2   ; R/W 读/写/执行
PG_USS      EQU     0   ; U/S 系统级
PG_USU      EQU     4   ; U/S 用户级
