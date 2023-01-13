; 内存分页
; PDE: | 63: XD | 62-M: Reserved | M-12: Addr | 11-8: Reserved | 7: PS | 6: Reserved | 5: A | 4: PCD | 3: PWT | 2: Super | 1: RW | 0: P |
; PTE: | 63: XD | 62-M: Reserved | M-12: Addr | 11-9: Reserved | 8: G | 7: PAT | 6: D | 5: A | 4: PCD | 3: PWT | 2: Super | 1: RW | 0: P |

%define PDE(addr, attr) (addr | attr)
%define PTE(addr, attr) (addr | attr)

PG_P        equ 0x0000000000000001
PG_RW       equ 0x0000000000000002
PG_S        equ 0x0000000000000004
PG_PWT      equ 0x0000000000000008
PG_PCD      equ 0x0000000000000010
PG_A        equ 0x0000000000000020
PG_D        equ 0x0000000000000040
PG_PAT      equ 0x0000000000000080
PG_G        equ 0x0000000000000100
PG_PS       equ 0x0000000000000100
PG_XD       equ 0x8000000000000000