#=======================================================================
# Makefile for Verilog simulation w/ VCS
#-----------------------------------------------------------------------
# Wei Song (ws327@cam.ac.uk)
# Yunsup Lee (yunsup@cs.berkeley.edu)
#
# This makefile will build a rtl simulator and run various tests to
# verify proper functionality.
#

default: all

base_dir = $(abspath ..)
sim_dir = $(abspath .)

generated_dir = $(sim_dir)/generated-src
mem_gen = $(sim_dir)/vlsi_mem_gen
output_dir = $(sim_dir)/output

BACKEND ?= lowrisc_chip.LowRISCBackend
CONFIG ?= DefaultConfig

include $(base_dir)/Makefrag
include $(sim_dir)/Makefrag



clean:
	rm -rf $(generated_dir) $(CONFIG)-sim verilator

.PHONY: default all debug clean sim
