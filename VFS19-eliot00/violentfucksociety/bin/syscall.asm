; VFS FRAMEWORK - STEALTH GATE (X64)
; Purpose: Direct Syscall with XOR decoding to bypass static analysis.
; Compile: nasm -f elf64 vfs_gate.asm -o vfs_gate.o


section .text
global vfs_call

vfs_call:
    ; C calling convention (RDI, RSI, RDX, RCX, R8, R9)
    ; Syscall convention (RAX, RDI, RSI, RDX, R10, R8, R9)
    
    mov rax, rdi        ; RDI contains coded building numbers.
    xor rax, 0xAA       ; XOR 0xAA (key)

    
    mov rdi, rsi        ; a1 -> rdi
    mov rsi, rdx        ; a2 -> rsi
    mov rdx, rcx        ; a3 -> rdx
    mov r10, r8         ; a4 -> r10 
    mov r8, r9          ; a5 -> r8
    
    syscall             
    ret
