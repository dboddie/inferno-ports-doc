# Freezing Limbo modules

This initiative was started in January 2023 and resulted in the work being
presented remotely at the International Workshop on Plan 9 (IWP9) in April
2023.

## Summary

The Dis virtual machine normally loads Limbo modules from compiled `.dis`
files, which contain a bytecode representation of compiled Limbo code, along
with other resources. This bytecode is expanded into RAM when a module is
loaded, taking up working memory that could be used by other modules.
Additional RAM is also temporarily used during the loading process, meaning
that there needs to be more than enough free RAM to load a module.

Alternatively, if modules can be pre-loaded into non-volatile memory, like
flash memory or ROM, then RAM does not need to be spent on holding bytecode
and the temporary overhead of module loading can be reduced.

This approach was tried successfully. The results can be found in the links
below.

## Resources

* [Paper and presentation slides](https://github.com/dboddie/inferno-freeze-slides)
* [Video presentation](https://www.youtube.com/watch?v=IcibSmmT1Hc)
