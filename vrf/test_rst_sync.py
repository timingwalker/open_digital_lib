
import random
import time
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

async def generate_clock(dut):
    for _ in range(5000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")

@cocotb.test()
async def ODL_test(dut):

    # run the clock "in the background"
    cocotb.start_soon(generate_clock(dut))

    dut.rst_ni.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)

    await RisingEdge(dut.clk_i)
    assert dut.rstn_sync_o.value == 0
    await RisingEdge(dut.clk_i)
    assert dut.rstn_sync_o.value == 0
    await RisingEdge(dut.clk_i)
    assert dut.rstn_sync_o.value == 0
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    assert dut.rstn_sync_o.value == 1



