# Improvements

This page contains list of planned improvements or ideas for improvement to the
various ports of Inferno.

## General issues

* Re-examine use of clocks and timers in the ARM Cortex-M ports.
* Implement proper UART drivers instead of relying on a hack to provide a keyboard.
* Share interrupt and preemption handling between ports.
* Add (micro)SD card support from other ports, like the Ben NanoNote port.

## Enhancements

Some enhancements would make using Inferno more comfortable on some platforms.

* A console text editor would be useful on platforms where the only user
  interface is a text console.
  Something like [Vixen](https://github.com/mjl-/vixen) might be appealing to
  some people.
* Interactive languages would supplement or augment the tiny shell.
  [Inferno Scheme](https://github.com/Plan9-Archive/inferno-scheme) could be
  interesting.
* A draw device for embedded displays. Perhaps a variant of the existing one.