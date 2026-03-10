# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

#TC := clock_switch
#TC := wrr_fair
#TC := wrr
TC := fpa

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
EXTRA_ARGS += --trace --trace-structs -Wno-fatal

COCOTB_TOPLEVEL = ODL_$(TC)
COCOTB_TEST_MODULES = test_$(TC)

# ======================================================================
#  arbiter
# ======================================================================
ifeq ($(TC), fpa)
    VERILOG_SOURCES += ../design/arbiter/ODL_fpa.sv
endif
ifeq ($(TC), wrr)
    VERILOG_SOURCES += ../design/arbiter/ODL_wrr.sv
endif
ifeq ($(TC), wrr_fair)
    VERILOG_SOURCES += ../design/arbiter/ODL_fpa.sv
    VERILOG_SOURCES += ../design/arbiter/ODL_wrr_fair.sv
endif
# ======================================================================
#  clock and reset
# ======================================================================
ifeq ($(TC), clock_switch)
    VERILOG_SOURCES += ../design/clk_rst/ODL_clock_switch.sv
    VERILOG_SOURCES += ../design/clk_rst/std_wrap_ckand.sv
    VERILOG_SOURCES += ../design/clk_rst/std_wrap_ckinv.sv
    VERILOG_SOURCES += ../design/clk_rst/std_wrap_ckmux.sv
    VERILOG_SOURCES += ../design/clk_rst/std_wrap_ckor.sv
endif


# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	gtkwave --save=./gtkw/$(TC).gtkw dump.vcd &

