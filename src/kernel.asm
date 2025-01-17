[BITS 32]
global _start
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x00200000
    mov esp, ebp

; enabling the A20 with the Fast A20 gate:
    in al, 0x92
    or al, 2
    out 0x92, al

    call kernel_main
    jmp $

times 512-($-$$) db 0 ; fill out all unoccupied 510 bytes with 0
