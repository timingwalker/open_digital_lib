# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

#TC := wrr_fair
#TC := wrr
#TC := fpa
#TC := clock_switch
TC := rst_sync
#TC := bin_to_gray
#TC := bin_to_onehot
#TC := gray_to_bin
#TC := onehot_to_bin
#TC := aes_128

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
#  encode
# ======================================================================
ifeq ($(TC), bin_to_gray)
    VERILOG_SOURCES += ../design/encode/ODL_$(TC).sv
endif
ifeq ($(TC), bin_to_onehot)
    VERILOG_SOURCES += ../design/encode/ODL_$(TC).sv
endif
ifeq ($(TC), gray_to_bin)
    VERILOG_SOURCES += ../design/encode/ODL_$(TC).sv
endif
ifeq ($(TC), onehot_to_bin)
    VERILOG_SOURCES += ../design/encode/ODL_$(TC).sv
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
ifeq ($(TC), rst_sync)
    VERILOG_SOURCES += ../design/clk_rst/ODL_rst_sync.sv
endif
# ======================================================================
#  aes-128
# ======================================================================
ifeq ($(TC), aes_128)
    VERILOG_SOURCES += ../design/aes_128/ODL_aes_128.v
    VERILOG_SOURCES += ../design/aes_128/ctrl.v
    VERILOG_SOURCES += ../design/aes_128/keyexpand.v
    VERILOG_SOURCES += ../design/aes_128/mixcolum.v
    VERILOG_SOURCES += ../design/aes_128/sbox.v
endif


# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	gtkwave --save=./gtkw/$(TC).gtkw dump.vcd &

