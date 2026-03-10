
import random
import time
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

async def generate_clock_0(dut):
    for _ in range(5000):
        dut.clk_in0.value = 0
        await Timer(5, unit="ns")
        dut.clk_in0.value = 1
        await Timer(5, unit="ns")

async def generate_clock_1(dut):
    for _ in range(5000):
        dut.clk_in1.value = 0
        await Timer(8, unit="ns")
        dut.clk_in1.value = 1
        await Timer(8, unit="ns")

@cocotb.test()
async def ODL_test(dut):

    # run the clock "in the background"
    cocotb.start_soon(generate_clock_0(dut))
    cocotb.start_soon(generate_clock_1(dut))

    dut.scan_mode.value = 0
    dut.select_in.value = 0

    dut.rst_n.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk_in0)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk_in0)

    for j in range(0,5):
        cocotb.log.info("== test %d", j)
        # set random seed
        random.seed(time.time())
        # set new weight
        await RisingEdge(dut.clk_in0)

        delay_cycle = random.randint(100,600)
        for i in range(0,delay_cycle):
            await RisingEdge(dut.clk_in0)

        dut.select_in.value = ~dut.select_in.value;

    await Timer(60, unit="ns")

