# Booting

From Inferno's perspective, booting begins in the assembly language file,
`l.s`, in each of the ports
([Apollo3](https://github.com/dboddie/inferno-os/blob/apollo3/os/apollo3/l.s),
[SAMD51](https://github.com/dboddie/inferno-os/blob/samd51/os/samd51/l.s),
[STM32F405](https://github.com/dboddie/inferno-os/blob/stm32f405/os/stm32f405/l.s),
[Teensy](https://github.com/dboddie/inferno-os/blob/teensy41mm/os/teensy41mm/l.s)).
Unless a bootloader has set up the run-time environment, the processor will
be running in thread mode, using the main stack, with potentially only
unprivileged access to resources.

The first task is to set the static base address in the appropriate register,
which is R12 for these ports. This enables convenient access to data and is
needed by the C run-time environment.

The kernel's stack pointer needs to be set to an appropriate address. Although
the vector table for this kind of microcontroller includes an entry for the
stack pointer, it is useful to explicitly set this.

The vector table address itself may need to be set, depending on the
microcontroller and bootloader. Some microcontrollers will boot and run the
user-installed software without changing the vector table address from the one
used by the bootloader.

After these initial steps to set up a basic run-time environment, data used by
the kernel needs to be copied from the addresses immediately following the kernel
text (code) into the appropriate region of RAM.

At this point, there is enough infrastructure in place to allow C functions to
be called.

## An example

Taking the [Apollo3](https://github.com/dboddie/inferno-os/blob/apollo3/os/apollo3/l.s)
port as an example, we can see how the above steps are performed.

The `l.s` file starts with some includes and a directive that ensures Thumb-2
machine code will be generated instead of 32-bit ARM code:

```
#include "mem.h"
#include "thumb2.h"
#include "vectors.s"

THUMB=4
```

The `_start` routine is the entry point for the kernel, and it starts by
setting the static base address. Note the left-to-right form of the
assembler notation:

```
TEXT _start(SB), THUMB, $-4

    MOVW    $setR12(SB), R1
    MOVW    R1, R12	/* static base (SB) */
```

The special constant, `setR12(SB)`, is defined by the compiler.

The stack pointer is transferred from a constant value defined in the `mem.h`
file to the register (R13) used to hold the stack pointer, which is referred to
by the name `SP`. This transfer uses an intermediate register due to the
limitations of the instruction set:

```
    MOVW    $STACK_TOP, R1
    MOVW    R1, SP
```

In this port, the stack pointer in use is the Main Stack Pointer (MSP), and it
is also useful to know that the processor is running in Thread Mode.

As noted above, the vector table needs to be set for some processors, and this
is the case for the Apollo3 microcontroller. The new address, defined by the
`ROM_START` constant in the `mem.h` file, is written to the system register at
the address, `SCB_VTOR`, defined in the `thumb2.h` file:

```
    MOVW    $SCB_VTOR, R1
    MOVW    $ROM_START, R2
    MOVW    R2, (R1)
```

At this point, any exceptions should be routed via the table we have provided
instead of the one provided by the bootloader.

The data used by the kernel is copied into RAM using a simple loop that reads
from the memory address immediately following the kernel's text section, as
defined by the `etext` constant, and writes to the memory starting at the
address defined by the `bdata` constant. Copying continues until the pointer
used for writes reaches the address defined by the `edata` constant:

```
    MOVW    $etext(SB), R1
    MOVW    $bdata(SB), R2
    MOVW    $edata(SB), R3

_start_loop:
    CMP     R3, R2              /* Note the reversal of the operands */
    BGE     _end_start_loop

    MOVW    (R1), R4
    MOVW    R4, (R2)
    ADD     $4, R1
    ADD     $4, R2
    B       _start_loop

_end_start_loop:
```

The `etext`, `bdata` and `edata` constants are all defined by the compiler,
based on its configuration and command line options.

Before calling the kernel's `main` function, interrupts are disabled via the
use of a helper routine defined in the `thumb2.s` file:

```
    BL  ,introff(SB)

    B   ,main(SB)
```

The `main` function performs a series of higher-level tasks to bring up the
kernel and user environment.
