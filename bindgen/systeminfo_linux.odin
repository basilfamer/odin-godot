//+build linux
package bindgen

import "core:c"
import "core:sys/linux"

CPU_SETSIZE :: 1024
CPU_BITTYPE :: c.ulong
CPU_BITS :: size_of(CPU_BITTYPE)

Cpu_Set :: struct {
    bits: [CPU_SETSIZE / CPU_BITS]CPU_BITTYPE
}

errno_unwrap2 :: #force_inline proc "contextless" (ret: $P, $T: typeid) -> (T, linux.Errno) {
	if ret < 0 {
		default_value: T
		return default_value, linux.Errno(-ret)
	} else {
		return cast(T) ret, linux.Errno(.NONE)
	}
}

sched_getaffinity :: proc(pid: linux.Pid, cpusetsize: c.size_t, mask: ^Cpu_Set) -> (int, linux.Errno) {
    ret := linux.syscall(linux.SYS_sched_getaffinity, pid, cpusetsize, mask)
    return errno_unwrap2(ret, int)
}

@private
countbits :: proc(v: CPU_BITTYPE) -> int {
    s := 0
    v := v
    for v != 0 {
        v &= v - 1
        s += 1
    }
    return s
}

@private
sched_cpucount :: proc(setsize: c.size_t, set: ^Cpu_Set) -> int {
    s := 0
    for i in 0..=(setsize / CPU_BITS)-1 {
        s += countbits(set.bits[i])
    }
    return s
}

num_processors :: proc() -> int {
    cpu_set: Cpu_Set
    sched_getaffinity(0, size_of(Cpu_Set), &cpu_set)
    return sched_cpucount(CPU_SETSIZE, &cpu_set)
}