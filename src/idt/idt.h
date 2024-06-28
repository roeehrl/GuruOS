#ifndef IDT_H
#define IDT_H

#include <stdint.h>

struct idt_desc
{
    uint16_t offset_1; //offset bits 0-15
    uint16_t selector; //selector in GDT
    uint16_t zero; // unused bits, set to zero
    uint16_t type_attr; //Descriptor type and attributes
    uint16_t offset_2; //offset bits 16-31

} __attribute__((packed));

struct idtr_desc
{
    uint16_t limit; //size of descriptor table -1
    uint32_t base; //base address of the start ot the interrupt descriptor table


} __attribute__((packed));

#endif
