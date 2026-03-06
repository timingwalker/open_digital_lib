
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


    for j in range(0,50):
        cocotb.log.info("== test %d", j)
        # set random seed
        random.seed(time.time())
        # set new weight
        await RisingEdge(dut.clk_i)
        dut.req_i.value = 0
        for i in range(0,8):
            dut.wt_i[i].value = random.randint(1,7)
        # check gnt_o
        await RisingEdge(dut.clk_i)
        await RisingEdge(dut.clk_i)
        for i in range(0,8):
            cocotb.log.info("weight[%d]is %d", i, dut.wt_i[i].value)
        dut.req_i.value = 0b11111111
        for i in range(0,8):
            for _ in range(dut.wt_i[i].value ):
                await FallingEdge(dut.clk_i)
                cocotb.log.info("gnt_o is %s", dut.gnt_o.value)
                assert dut.gnt_o.value == 0b1 << i

    await Timer(60, unit="ns")

