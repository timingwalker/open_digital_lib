
import random
import time
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

async def generate_clock(dut):
    for _ in range(5000):
        dut.clk.value = 0
        await Timer(5, unit="ns")
        dut.clk.value = 1
        await Timer(5, unit="ns")

@cocotb.test()
async def ODL_test(dut):

    # run the clock "in the background"
    cocotb.start_soon(generate_clock(dut))

    dut.rst_n.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut.key_in.value = 0x2b7e151628aed2a6abf7158809cf4f3c
    dut.data_in.value = 0x3243f6a8885a308d313198a2e0370734

    dut.start.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk)
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    await Timer(600, unit="ns")

    assert dut.out.value == 0x3925841d02dc09fbdc118597196a0b32

