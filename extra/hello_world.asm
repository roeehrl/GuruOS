ORG 0x7c00 ; the BIOS loads the bootloader to 0x7c00
BITS 16 ; our register size in REAL-mode 

start:
    mov si, message; make si point to first bye of message
    call print
    jmp $ 


print:
    mov bx, 0
.loop:
    lodsb ; loads the character pointed by si into al and increments si one byte
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh ;
    int 0x10; BIOS interrupt for print
    ret
message: db 'Hello World!' , 0

times 510-($-$$) db 0 ; fill out all unoccupied 510 bytes with 0
dw 0xAA55 ; magic for the BIOS to know this sector is bootable