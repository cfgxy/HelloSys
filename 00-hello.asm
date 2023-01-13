; ELF可执行文件汇编, 用内核中断打印Hello World
; nasm 编译后 用ld连接 在Linux系统执行
; 参考文档:
; https://www.nasm.us/xdoc/2.16.01/html/nasmdoc0.html
; docs/nasm.pdf

[section .text]
    global _start
_start:
mov eax, [mytype1+mytype.word2]
mov eax, 4
mov ebx, 1
mov ecx, helloMsg
mov edx, helloLen
int 0x80

mov eax, 1
mov ebx, 0
int 0x80


[section .data]
struc mytype
    .word resw 2
    .word2 resw 1
    alignb 8
    .word3 resw 2
    alignb 8
endstruc

mytype1:
istruc mytype
    at mytype.word, dw 1,2
    at mytype.word3, dw 22
    align 4, db 2
iend

helloMsg db "Hello World!", 0x0d, 0x0a, '$'
helloLen equ $-helloMsg