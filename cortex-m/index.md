# ARM Cortex-M ports

Ports of Inferno to various ARM Cortex-M4 and M7 boards share some common
features due to their common instruction set and similarities in processor
design.

Ports include:

* [Apollo3](https://github.com/dboddie/inferno-os/blob/apollo3/os/apollo3/README.md)
* [SAMD51](https://github.com/dboddie/inferno-os/blob/samd51/os/samd51/README.md)
* [STM32F405](https://github.com/dboddie/inferno-os/blob/stm32f405/os/stm32f405/README.md)
* [Teensy 4.1/MicroMod](https://github.com/dboddie/inferno-os/blob/teensy41mm/os/teensy41mm/README.md)

## Toolchain

The ports all use the Thumb-2 compiler toolchain: `tc` for the C compiler,
`tl` for the linker/loader, and `5a` for the assembler. The assembler uses
the `-t` option to specify Thumb instructions instead of 32-bit ARM
instructions.

## Concepts

It is useful to know about a few concepts when working with Cortex-M
processors, and when porting Inferno in general.

### Instruction set

Unlike the other ARM ports, these ports are compiled to Thumb-2 instructions
instead of 32-bit ARM instructions, and this influences the way that some of
the core mechanisms in Inferno are implemented.

### Processor modes

Cortex-M4 and M7 processors have two processor modes: handler and thread.
Handler mode is used for exception handling; thread mode is used to run
applications, similar to a user mode. Handler mode is privileged, whereas
thread mode is typically unprivileged.

### Stacks

Two stacks can be defined for the processor: main and process. These can be
used to maintain different state for exception handlers and user processes.
Inferno only uses the main stack, so code comment will typically refer to the
Main Stack Pointer (MSP).

### Vectors

ARM Cortex-M processors are like other ARM processors in that they use a block
of memory, traditionally at the start of RAM, for a vector table. This is a
lookup table that tells the processor where to jump to when an exception or
interrupt occurs.

The microcontrollers used by these ports are preinstalled with bootloaders that
have already defined a vector table. The Inferno kernel needs its own vector
table, and this is supplied with the kernel in the `vectors.s` file
([Apollo3](https://github.com/dboddie/inferno-os/blob/apollo3/os/apollo3/vectors.s),
[SAMD51](https://github.com/dboddie/inferno-os/blob/samd51/os/samd51/vectors.s),
[STM32F405](https://github.com/dboddie/inferno-os/blob/stm32f405/os/stm32f405/vectors.s),
[Teensy](https://github.com/dboddie/inferno-os/blob/teensy41mm/os/teensy41mm/vectors.s)).
Some microcontrollers and bootloaders expect the kernel to tell the
microcontroller about the location of the vector table. This is done by
writing to the `SCB_VTOR` register in the system control block.

### Static base

The static base address is the address used to refer to program and data
structures, such as the static and mutable data needed by the kernel.
The [Inferno assembler manual](https://www.vitanuova.com/inferno/papers/asm.html)
refers to this address as the beginning of the address space of the program.
As with other Inferno ports, this address is loaded into a processor register
to make run-time calculations more efficient.

## Booting

As far as Inferno is concerned, booting begins in the assembly language
file, `l.s`, in each of the ports
([Apollo3](https://github.com/dboddie/inferno-os/blob/apollo3/os/apollo3/l.s),
[SAMD51](https://github.com/dboddie/inferno-os/blob/samd51/os/samd51/l.s),
[STM32F405](https://github.com/dboddie/inferno-os/blob/stm32f405/os/stm32f405/l.s),
[Teensy](https://github.com/dboddie/inferno-os/blob/teensy41mm/os/teensy41mm/l.s)).
Unless a bootloader has set up the run-time environment, the processor will
be running in thread mode, using the main stack, with potentially only
unprivileged access to resources.

The first task is to set the static base address in the appropriate register,
which is R12 for these ports.

Then the stack pointer needs to be set.

The vector table address may need to be set, depending on the microcontroller
and bootloader.

After this, data used by the kernel needs to be copied from the addresses
immediately following the kernel text into the appropriate region of RAM.

At this point, there is enough infrastructure in place to allow C functions to
be called.

Interrupts are disabled and the main function is called.

## Preemption

As with 32-bit ARM systems, preemption occurs as the result of a timer
interrupt. However, since the Cortex-M ports use a different system of
processor modes, the technique used to respond to the interrupt and
perform a context switch is different.

On 32-bit ARMs, the processor mode can be easily changed from within the
exception handler, switching from IRQ mode to SVC mode, which is the default
mode used for the kernel. The `setlabel` and `gotolabel` mechanism to switch
tasks is therefore always operating in SVC mode, even when a task switch is
performed explicitly outside of any interrupt handling. This means that the
exception handler can directly call the context switching code.

On Cortex-M processors, an exception causes the processor to enter handler
mode and push a number of registers onto the main stack. This is described in
the *Exception entry and return* section of the
[Cortex-M4 Devices Generic User Guide](https://developer.arm.com/documentation/dui0553/latest/). It is not possible to change processor mode to perform the same trick
as the 32-bit ARM ports because the only way to enter thread mode is to return
from the exception using a special return address.

This presents a problem for two reasons:

1. The exception needs to be handled before running any more kernel or user
   code, and switching to a different task will prevent this from happening if
   the other task was not interrupted by an exception. (It will return to a
   normal instead of a special return address.)
2. Even if the other task was interrupted, the processor would be returning to
   the point where it was interrupted. That would also mean that there was an
   exception already being handled when the current exception occurred. This
   does not always lead to good outcomes on this architecture.

Additionally, the possibility of leaving the processor in handler mode when
executing non-handler code will cause problems when handling undefined
floating point instructions.

The workaround to allow `setlabel` and `gotolabel` to already run in thread
mode is to handle an exception and return from it into thread mode. Then it is
possible to call the context switching code. However, returning from an
exception in the normal way will cause the interrupted code to continue without
the possibility of calling the context switcher.

## Floating point instructions

All the tested Cortex-M4 processors have single precision floating point
support. This is not completely useful for Inferno because the system requires
double precision support. However, there are single precision instructions
that provide some of the operations that Inferno needs.
