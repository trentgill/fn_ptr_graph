# fn_ptr_graph
Forth-y CLI for DSP graphs. C (DSP) &amp; Haskell (interpreter &amp; graph compiler) backend. Wrapped in libsoundio

Checkout the 'goth_wrath' branch for current status.

libsoundio is used as a host for an audio application. it starts out doing nothing.

interact with the CLI to add modules (taken from github.com/whimsicalraps/wrDsp) & change parameters.

the CLI is a very basic forth (written in Haskell), which currently doesn't even have conditionals.
push values to the stack, then call the words that use them (eg. 43.0 01.LPG.level).

the DSP graph details are stored & compiled into a computable list inside of Haskell.
C does as little as possible:
- all _process() fns are called with pointers to their in&out buffers (supplied by haskell)
- on init, each module reports it's parameters & fnptrs for access & process -> stored in haskell
this approach attempts to reduce the IO access, and encourage more functional use of the libs

all DSP optimization is done in Haskell, mostly for ease.
this means, any non-obvious optimizations that a C lib can do, must be exposed as a set of rules in the *_cli.h
eg: volume controls set to 0, will always result in no output, but may need internal state updated.
this system has not been completed.

in fact, much of this has not been completed!

# why
originally intended as a desktop-hosted testbed for dsp written for embedded systems.
simplifies the debugging process & makes testing on the go much easier.
it should run on raspberry pi 3 hardware, which is a key platform for further development of this project.
all the existing code was written for cortex-m series microcontrollers, so is generally fast & efficient

there will be a ui at some point, probably using brick

maybe one day it will live in a plugin too.
