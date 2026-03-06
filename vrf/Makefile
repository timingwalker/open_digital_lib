# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TC := wrr_fair

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
EXTRA_ARGS += --trace --trace-structs -Wno-fatal

ifeq ($(TC), fpa)
    VERILOG_SOURCES += ../design/arbiter/ODL_fpa.sv
    COCOTB_TOPLEVEL = ODL_fpa
    COCOTB_TEST_MODULES = test_fpa
endif
ifeq ($(TC), wrr)
    VERILOG_SOURCES += ../design/arbiter/ODL_wrr.sv
    COCOTB_TOPLEVEL = ODL_wrr
    COCOTB_TEST_MODULES = test_wrr
endif
ifeq ($(TC), wrr_fair)
    VERILOG_SOURCES += ../design/arbiter/ODL_fpa.sv
    VERILOG_SOURCES += ../design/arbiter/ODL_wrr_fair.sv
    COCOTB_TOPLEVEL = ODL_wrr_fair
    COCOTB_TEST_MODULES = test_wrr_fair
endif

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	gtkwave --save=./gtkw/$(TC).gtkw dump.vcd &

