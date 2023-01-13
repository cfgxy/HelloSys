; 内存分页
; PDE: | 63: XD | 62-M: Reserved | M-12: Addr | 11-8: Reserved | 7: PS | 6: Reserved | 5: A | 4: PCD | 3: PWT | 2: Super | 1: RW | 0: P |
; PTE: | 63: XD | 62-M: Reserved | M-12: Addr | 11-9: Reserved | 8: G | 7: PAT | 6: D | 5: A | 4: PCD | 3: PWT | 2: Super | 1: RW | 0: P |

%define PDE(addr, attr) (addr | attr)
%define PTE(addr, attr) (addr | attr)

PG_P        equ 0x0000000000000001  ; =1
PG_RW       equ 0x0000000000000002  ; Read/Write，如果为0，不允许向分页内存写数据
PG_S        equ 0x0000000000000004  ; User/supervisor，权限标志位，等于0则3环程序不能访问分页内存
PG_PWT      equ 0x0000000000000008  ; Page Level Write Through
PG_PCD      equ 0x0000000000000010  ; Page Level Cache Disable
PG_A        equ 0x0000000000000020  ; 已访问
PG_D        equ 0x0000000000000040  ; 脏页
PG_PAT      equ 0x0000000000000080  ; page-attribute table
PG_G        equ 0x0000000000000100  ; 全局共享页; CR4.PGE开启时生效
PG_PS       equ 0x0000000000000100  ; 大内存分页
PG_XD       equ 0x8000000000000000  ; 页表指向的内存空间禁止执行(纯数据)