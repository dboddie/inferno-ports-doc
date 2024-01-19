# Initiatives

This page provides information about various initiatives related to this
project, and to Inferno in general.

## Inferno on microcontrollers

This project aims to build on existing work to make Inferno run on
microcontrollers by improving documentation, testing ports to various systems,
and fixing any issues found.

### Background and motivation

The Inferno operating system has been around for a fairly long time and is
still relevant today. It still runs on modern, commodity PC hardware, thanks to
maintenance and porting over the years. It has features that make it relevant
to embedded software development.

Inferno was designed to work without an Memory Management Unit (MMU) on systems
with reasonably low amounts of memory. These days, the systems that fit this
profile are embedded microcontrollers, particularly in Internet of Things (IoT)
devices. It is therefore interesting to consider whether Inferno would be a
useful system to run on this kind of hardware.

Inferno has been demonstrated to run on low resource hardware, including
microcontrollers and single board computers, as well as more conventional
workstation hardware. The same operating system can run on large and small
machines, potentially making it a general purpose computing platform that also
runs on IoT devices. This is a key difference to other embedded operating
systems where software development takes place on a completely different
system.

Where running native Inferno on a workstation is impractical, the ability to
run an Inferno environment as a user task on other operating systems makes
programming and testing applications for Inferno accessible and consistent
across development platforms. Integration between the host and Inferno
environments on a workstation enables developers to keep using the tools and
processes they are productive with, importing them into the development
environment. Many of the tools and compilers are available inside and outside
of the development environment, which also provides flexibility for developers.

Inferno is also able to provide an interactive environment on microcontrollers
similar to that seen on more powerful devices, bridging the gap between these
different classes of system. Simple applications or workflows can be written
using shell scripts, and peripherals can be tested interactively with standard
Unix-like tools and features, such as streams, pipes and device files.
