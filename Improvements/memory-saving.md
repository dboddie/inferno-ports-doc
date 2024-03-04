# Memory saving techniques

It can be useful to apply techniques to save the amount of memory that Inferno
uses, or to make usage more efficient in certain situations.
This is particularly relevant in the case of the [Cortex-M]( cortex-m/index.md )
ports, where the amount of available flash memory is usually much greater than
the amount of RAM.

## Overview

There are three main ways to reduce RAM usage:

1. Ensure that data is not placed in RAM. This is the approach taken when
   [freezing Limbo modules]( ../Initiatives/freezing-limbo-modules.md ).
2. Reduce the amount of memory requested for workspace, perhaps by limiting
   buffer sizes to reflect the limited amount of RAM available.
3. Use memory more efficiently by eliminating or reducing overheads and wastage.

These are topics that fall within the scope of this document.

## Merging allocation pools

This approach falls into the category of eliminating overheads.

When building Inferno for small memory devices, it is usually necessary to
fine-tune the relative proportions of RAM that are made available to the main
and heap memory pools in the allocator. Assigning too much to the main pool can
cause Limbo modules to fail to load. Assigning too much to the heap pool can
cause the kernel to fail to allocate memory.

Instead of arbitrarily partitioning the memory in this way, perhaps it is
better to use only one pool for all allocation.

This can be done in the `main.c` file for each port, in the `poolsizeinit`
function:

```
static void poolsizeinit(void)
{
    ulong nb = conf.npage*BY2PG;

    poolsize(mainmem, nb, 0);
    heapmem = mainmem;
    poolsize(imagmem, 0, 1);
}
```

Since the `imagmem` pool is unused, it can be kept separate.
