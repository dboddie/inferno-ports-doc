# Preemption

Cortex-M ports use a different mechanism for context switching than the one
used by ports to ARM processors with 32-bit instructions.

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

The workaround to allow `setlabel` and `gotolabel` to already run in thread
mode is to handle an exception and return from it into thread mode. Then it is
possible to call the context switching code. However, returning from an
exception in the normal way will cause the interrupted code to continue without
the possibility of calling the context switcher. Therefore, the exception
handler needs to return in a way that allows the context switcher to run.
