# Preemption

Cortex-M ports use a different mechanism for context switching than the one
used by ports to ARM processors with 32-bit instructions. To explan this, we
will first give a bit of background information about the problem to solve,
propose a general solution, then provide more details about the solution.

## Background

On 32-bit ARMs, the processor mode can be easily changed from within the
exception handler, switching from IRQ mode to SVC mode, which is the default
mode used for the kernel. The `setlabel` and `gotolabel` mechanism to switch
tasks is therefore always operating in SVC mode, even when a task switch is
performed explicitly outside of any interrupt handling. This means that the
exception handler can directly call the context switching code.

On Cortex-M processors, an exception causes the processor to enter handler
mode and push a number of registers onto the main stack. This is described in
the *Exception entry and return* section of the
[Cortex-M4 Devices Generic User Guide](https://developer.arm.com/documentation/dui0553/latest/).
It is not possible to change processor mode to perform the same trick as the
32-bit ARM ports because the only way to enter thread mode is to return from
the exception using a special return address.

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

The solution is to return to thread mode in order to perform a context switch.

## Current approach

The mechanism to ensure that `setlabel` and `gotolabel` are always called in
thread mode is to handle an exception and return from it into thread mode
before calling the context switching code. However, returning from an exception
in the normal way will cause the interrupted code to continue without the
possibility of calling the context switcher. Therefore, the exception handler
needs to return in a way that allows the context switcher to run.

When an exception occurs, the values of some registers are automatically
pushed onto the stack. As a result, its contents will look something like the
following list, where later items are lower in memory and closer to the stack
pointer:

* xPSR (program status register)
* PC (interrupted program counter)
* LR (interrupted link register)
* R12 (we also use this as the static base register)
* R3
* R2
* R1
* R0

The program counter (PC) register will have been updated to the address of the
appropriate exception handler, and the link register (LR) will have been given
a special EXC_RETURN value.

Returning from the exception handler is done by moving the contents of the
LR into the PC. Unlike normal returns, the use of the special EXC_RETURN value
causes the values on the top of the stack to be popped back into the registers
they were originally read from.

To allow the context switcher to run, we modify the stack in the exception
handler to change the interrupted PC value, and we record the interrupted PC
value in the slot that would hold R12. This means that, when we return from
the exception, execution continues where we want it to occur and the R12
register contains the address where the exception occurred. This allows us
to eventually return to the interrupted code. Overwriting the stacked value
of R12 is not a problem because it normally holds the static base address
and this can be reset with the appropriate value when needed.

However, this in itself is not enough. We want to prevent the context switch
from being interrupted by another exception while the interrupted PC,
temporarily stored in R12, could be overwritten. We do this by disabling
interrupts until R12 is safely pushed onto the stack.

Another issue is that an exception could have occurred while the processor
has condition flags set. If we returned from the handler to the interrupted
code, this would not present a problem. However, returning to a completely
different routine with flags set could cause problems. We could clear the
flags to prevent any issues, but we must remember to set the flags before
eventually returning to the interrupted code. Otherwise, the program flow
will be altered as a result of handling the exception.

To avoid any further complications, we simply avoid performing a context
switch if certain processor flags are set.

## Details

We will refer to the
[Apollo3](https://github.com/dboddie/inferno-os/blob/cortexm/os/cortexm/systick.s)
implementation to describe the mechanism in more detail.

In the `_systick` exception handler, we check for existing exceptions and if
certain processor flags are set, exiting from the handler immediately if so:

<<< sources/inferno-os/os/cortexm/systick.s
from: TEXT _systick
until: /\*
from: MOVW
to: _systick_exit

The processor flags for the interrupted code are transferred to R2 for later
handling.

To avoid any other issues with reentry, interrupts are masked:

<<<
line: CPS\(1, CPS_I\)

The processor flags in R2 are saved by copying them to a temporary register,
R10, that isn't used in compiled code or any other assembly code. It is only
used in this routine, which is another reason to prevent exception reentry:

<<<
line: MOVW    R2, R10

Since the idea is to return from the exception to the context switcher, the
interrupted PC is copied to the slot on the stack where R12's value was
stored, overwriting it:

<<<
from: MOVW    24\(SP\), R0
to: R0, 16\(SP\)

Since we will return from the exception to the context switching routine, we
need to clear the condition flags in the value for the PSR stored on the stack:

<<<
from: MOVW    \$0x07ffffff, R0
to: R0, 28\(SP\)

Then the address of the switcher (actually, an intermediate routine) is copied
over the value of the interrupted PC on the stack before returning:

<<<
from: MOVW    \$_preswitch\(SB\), R0
to: RET

At this point, the exception handler either returns to the interrupted code if
the initial check failed, or it returns to the `_preswitch` routine. This begins
by saving the interrupted PC in R12, as well as all the registers that could be
in use:

<<<
from: TEXT _preswitch
to: PUSH\(0x0ffe, 1\)

At this point, interrupts can be unmasked, allowing the code afterwards to be
interrupted:

<<<
line: CPS\(0, CPS_I\)

Since floating point instructions may be in use, we save those as well:

<<<
from: VMRS\(0\)
to: VPUSH\(0, 8\)

In order to call the context switcher we need to ensure that R12 contains the
static base address, so we explicitly reset it:

<<<
from: MOVW    \$setR12\(SB\), R1
to: MOVW    R1, R12

It is now possible to pass the stack pointer to the `switcher` C function:

<<<
from: MOVW    SP, R0
to: BL      ,switcher\(SB\)

When the switcher returns, it is possible that another task has been switched
in, and the stack pointer will be different to the one we passed to it. In any
case, it is always the following code that is executed.

First, the floating point registers are restored:

<<<
from: VPOP\(0, 8\)
to: VMSR\(0\)

Then registers R1 to R11 and LR are restored. Since R10 contains the processor
flags from the interrupted code, those are written back to the status register:

<<<
from: POP_LR_PC\(0x0ffe, 1, 0\)
to: MSR\(10, 0\)

Finally, R0 and the interrupted PC are restored, returning control to the
interrupted code:

<<<
line: POP_LR_PC\(0x0001, 0, 1\)

Ideally, execution should continue in the same way as it would have done if the
exception had returned to the interrupted code directly.

## Implementation notes

The `PUSH`, `POP` and `POP_LR_PC` macros generate the T2 form of the `PUSH` and
`POP` Thumb-2 instructions; see sections A7.7.98 and A7.7.99 of the ARMv7-M
Architecture Reference Manual for information about these instructions.
Unfortunately, the T2 form of these instructions is apparently unpredictable
when fewer than 2 registers are handled. As a result, there are intentionally
few places in the above code where only 1 register is handled, and these have
been updated to use the `PUSH1` and `POP1` macros which generate single
register stacking instructions.

In the [Teensy 4.1/MicroMod port](https://github.com/dboddie/inferno-os/blob/cortexm/os/teensy41mm/README.md),
additional issues were encountered with the way that registers were handled
on the stack. This affected some of the other exception handlers, but not the
preemption routines. It is possible that a related issue may still cause
problems with preemption in certain cases.
