ORG 0x7c00; The BIOS loads the bootloader to 0x7c00
BITS 16 ; our register size in REAL-mode 

CODE_SEG equ gdt_code - gdt_start; set the address of the code segment
DATA_SEG equ gdt_data - gdt_start; set the address of the code segment

;BIOS paramter block sometimes overwites 36 bytes beginning at 0x00, 
_start:
    jmp short start
    nop

    times 33 db 0 ; this  is a step to ensure no crucial code is being overwritten other than zeros.

start:
    jmp 0:step2; sets the code segment to the start of our code; in relation to the origin

step2:
    cli; clear interrupts
    mov ax, 0x00; set the segment registers  
    mov ds, ax ; points to the start of data segment
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00 ; set the stack to start before our code - because it grows down
    sti; enable interrupts

.load_protected:
    cli
    lgdt[gdt_descriptor]; load the gdt byte (size of gdt + start address)
    mov eax, cr0
    or eax, 0x1 ; enable the protected mode bit
    mov cr0, eax
    jmp CODE_SEG:load32 ; jumps to the 32-bit protected mode code segment


;GDT - global descriptor table describes segment access properties and permissions.
; setting the gdt bytes which refrences the GDT is crucial before switching to protected mode.
; we fill the GDT with default values as the kernel is to use the paging memory addressing model
gdt_start:

gdt_null:
    dd 0X0; 32 bits of zero (double word)
    dd 0x0;

;offset 0x8 (address of byte number 8, after 64 bits of null)
gdt_code: ;CS should point to this
    dw 0xffff; segment limit of birst 0-15 bits
    dw 0 ; base 0-15 bits
    db 0 ; base 16-23 bits
    db 0x9a ; access byte
    db 11001111b; high 4bit flags and low 4bit flags
    db 0; base 45-31 bits

;offset 0x10 (address of byes number 10. 32 bits after 0x08)
gdt_data: ;DS,SS,ES,FS,GS should point to here
    dw 0xffff; segment limit of first 0-15 bits
    dw 0 ; base 0-15 bits
    db 0 ; base 16-23 bits
    db 0x92 ; access byte differs
    db 11001111b; high 4bit flags and low 4bit flags
    db 0; base 45-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end-gdt_start -1 ; size of the descriptor
    dd gdt_start;

[BITS 32]
load32:
    mov eax, 1 ; starting sector to load from
    mov ecx, 100 ; how many sectors to load in
    mov edi, 0x0100000 ;one megabyte - the address to load the sectors into
    call ata_lba_read
    jmp CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax ; Backup lba
    ; send the highest 8 bits of LBA
    shr eax, 24 
    or eax, 0xE0; select the master drive
    mov dx, 0x1F6
    out dx, al; AL contains the 8 bits 
    ; finished sending highest 8 bits of LBA

    ;Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ;Finished sending total sectors

    ;Send more bits of the LBA
    mov eax, ebx; restoring the LBA
    mov dx, 0x1F3
    out dx, al
    ; Finished sending more bits of LBA

    ;send more bits of the LBA
    mov dx, 0x1F4
    mov eax, ebx; restore LBA
    shr eax, 8
    out dx, al
    ;Finished send more bits of LBA

    ;Sending upper 16 bits of LBA
    mov dx, 0x1F5
    mov eax, ebx
    shr eax, 16
    out dx, al
    ;Finished sending upper 16 bits of LBA

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    ;Read all sectors into memory
.next_sector:
    push ecx; save ecx for later (contains sectors to read)

;Checking if need to read
.try_again:
    mov dx, 0x1F7
    in al, dx
    test al, 8
    jz .try_again

; need to read 256 words everytime
    mov ecx, 256; number of words to be read
    mov dx, 0x1F0
    rep insw; insw reads a word from I/O port specified in dx, into the memory location specified by ES:EDI (repeated ecx times)
    pop ecx;
    loop .next_sector ; loops ecx times
    ; End of reading sectors into memory
    ret







times 510-($-$$) db 0 ; fill out all unoccupied 510 bytes with 0
dw 0xAA55 ; magic for the BIOS to know this sector is bootable