# ARM Cortex-M ports

Ports of Inferno to various ARM Cortex-M4 and M7 boards share some common
features due to their common instruction set and similarities in processor
design.

Ports include:

* [Apollo3](https://github.com/dboddie/inferno-os/blob/cortexm/os/apollo3/README.md)
* [SAMD51](https://github.com/dboddie/inferno-os/blob/samd51/os/samd51/README.md)
* [STM32F405](https://github.com/dboddie/inferno-os/blob/cortexm/os/stm32f405/README.md)
* [Teensy 4.1/MicroMod](https://github.com/dboddie/inferno-os/blob/cortexm/os/teensy41mm/README.md)

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
(R12) to make run-time calculations more efficient.

## Booting

As far as Inferno is concerned, booting begins in the assembly language
file, `l.s`

See [Booting]( booting.md ) for details.

Interrupts are disabled and the main function is called.

## Preemption

As with 32-bit ARM systems, preemption occurs as the result of a timer
interrupt. However, since the Cortex-M ports use a different system of
processor modes, the technique used to respond to the interrupt and
perform a context switch is different.

See [Preemption]( preemption.md ) for details.

## Floating point instructions

All the tested Cortex-M4 processors have single precision floating point
support. This is not completely useful for Inferno because the system requires
double precision support. However, there are single precision instructions
that provide some of the operations that Inferno needs.

The 32-bit ARM ports use an approach where floating point instructions are
emulated, maintaining a set of virtual registers. This approach is also used
except that the hardware registers