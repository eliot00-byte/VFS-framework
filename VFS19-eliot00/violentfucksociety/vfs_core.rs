#![no_std]

use core::panic::PanicInfo;

#[no_mangle]
pub unsafe extern "C" fn vfs_raw_gate(n: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64) -> i64 {
    let mut ret: i64;
    // XOR logic to obscure syscall namber
    let sys_no = n ^ 0xAA; 

    #[cfg(target_arch = "x86_64")]
    core::arch::asm!(
        "syscall",
        in("rax") sys_no,
        in("rdi") a1,
        in("rsi") a2,
        in("rdx") a3,
        in("r10") a4,
        in("r8") a5,
        lateout("rax") ret
    );

    #[cfg(target_arch = "aarch64")]
    core::arch::asm!(
        "svc 0",
        in("x8") sys_no,
        in("x0") a1,
        in("x1") a2,
        in("x2") a3,
        in("x4") a4,
        in("x5") a5,
        lateout("x0") ret
    );

    #[cfg(any(target_arch = "powerpc", target_arch = "ppc"))]
    core::arch::asm!(
        "sc",
        in("r0") sys_no,
        in("r3") a1,
        in("r4") a2,
        in("r5") a3,
        in("r6") a4,
        in("r7") a5,
        lateout("r3") ret
    );

    ret
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}