%include "pm.inc"

org 07c00h
    jmp LABEL_BEGIN

[SECTION .gdt]
; GDT
LABEL_GDT:          Descriptor  0,      0, 0    ;
LABEL_DESC_CODE32:  Descriptor  0,  SegCode32Len - 1, DA_C + DA_32;
LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; 显存首地址
; GDT end

GdtLen  equ     $ - LABEL_GDT   ;
GdtPtr  dw      GdtLen - 1 ;
        dd      0       ;

; GDT 段选择子
SelectorCode32  equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo   equ     LABEL_DESC_VIDEO    - LABEL_GDT
; end of [SECTION .gdt]

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0100h

    ; 初始化 32 位代码段描述符
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4  ; 段基址长度为20位
    add     eax, LABEL_SEG_CODE32
    mov     word [LABEL_DESC_CODE32 + 2], ax;   动态写入段描述符
    shr     eax, 16
    mov     byte [LABEL_DESC_CODE32 + 4], al
    mov     byte [LABEL_DESC_CODE32 + 7], ah

    ; 准备加载gdtr
    xor     eax, eax
    mov     ax, ds
    shl     eax, 4
    add    eax, LABEL_GDT        ; eax <- gdt 基地址
    mov    dword [GdtPtr + 2], eax    ; [GdtPtr + 2] <- gdt 基地址

    ; 加载 GDTR
    lgdt    [GdtPtr]

    ; 关中断
    cli

    ; 打开地址线A20
    in    al, 92h
    or    al, 00000010b
    out    92h, al

    ; 准备切换到保护模式
    mov    eax, cr0
    or    eax, 1
    mov    cr0, eax

    ; 真正进入保护模式
    jmp    dword SelectorCode32:0    ; 执行这一句会把 SelectorCode32 装入 cs,
                    ; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS    32]

LABEL_SEG_CODE32:
    mov     ax, SelectorVideo
    mov     gs, ax
    mov    edi, (80 * 11 + 79) * 2    ; 屏幕第 11 行, 第 79 列。
    mov    ah, 0Ch            ; 0000: 黑底    1100: 红字
    mov    al, '@'
    mov     [gs:edi], ax

    jmp     $

SegCode32Len    equ    $ - LABEL_SEG_CODE32
; END of [SECTION .s32]
