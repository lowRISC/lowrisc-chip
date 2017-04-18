lowRISC chip
==============================================

The root git repo for lowRISC development and FPGA
demos.

[master] status: [![master build status](https://travis-ci.org/lowRISC/lowrisc-chip.svg?branch=master)](https://travis-ci.org/lowRISC/lowrisc-chip)

[update] status: [![update build status](https://travis-ci.org/lowRISC/lowrisc-chip.svg?branch=update)](https://travis-ci.org/lowRISC/lowrisc-chip)

[dev] status: [![dev build status](https://travis-ci.org/lowRISC/lowrisc-chip.svg?branch=dev)](https://travis-ci.org/lowRISC/lowrisc-chip)

Current version: Release version 0.3 (07-2016) --- lowRISC with a trace debugger

To download the repo:

~~~shell
git clone -b debug-v0.3 https://github.com/lowrisc/lowrisc-chip.git
cd lowrisc-chip
git submodule update --init --recursive
~~~


For the previous release:

~~~shell
################
# Version 0.2: untethered lowRISC (12-2015)
################
git clone -b untether-v0.2 https://github.com/lowrisc/lowrisc-chip.git
cd lowrisc-chip
git submodule update --init --recursive

################
# Version 0.1: tagged memory (04-2015)
################
git clone -b tagged-memory-v0.1 https://github.com/lowrisc/lowrisc-chip.git
cd lowrisc-chip
git submodule update --init --recursive
~~~

[traffic statistics](http://www.cl.cam.ac.uk/~ws327/lowrisc_stat/index.html)

[master]: https://github.com/lowrisc/lowrisc-chip/tree/master
[update]: https://github.com/lowrisc/lowrisc-chip/tree/update
[dev]: https://github.com/lowrisc/lowrisc-chip/tree/dev
