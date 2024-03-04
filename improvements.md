# Improvements

This page contains list of planned improvements or ideas for improvement to the
various ports of Inferno.

## General issues

ARM Cortex-M ports:

* Re-examine use of clocks and timers.
* Implement proper UART drivers instead of relying on a hack to provide a
  keyboard.
* Share interrupt and preemption handling between ports.
* Add (micro)SD card support from other ports, like the Ben NanoNote port.
* Enable the Just In Time (JIT) compiler. This requires a certain amount of free
  RAM.
* Use only one memory pool instead of two or three. See [Memory saving techniques]( Improvements/memory-saving.md)
  for a description of this technique.

## Enhancements

Some enhancements would make using Inferno more comfortable on some platforms.

* A console text editor would be useful on platforms where the only user
  interface is a text console.
  Something like [Vixen](https://github.com/mjl-/vixen) might be appealing to
  some people.
* Interactive languages would supplement or augment the tiny shell.
  [Inferno Scheme](https://github.com/Plan9-Archive/inferno-scheme) could be
  interesting.
* A draw device specifically for embedded displays. Perhaps a variant of the
  existing draw device.