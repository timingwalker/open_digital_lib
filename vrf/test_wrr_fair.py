
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

        gnt_cnt = [0,0,0,0,0,0,0,0,]
        while dut.round_end.value != 1:
            await FallingEdge(dut.clk_i)
            gnt_o = int(dut.gnt_o.value);
            for i in range(0,8):
                if gnt_o & (1<<i) != 0:
                    gnt_cnt[i] = gnt_cnt[i] + 1
        for i in range(0,8):
            cocotb.log.info("gnt_cnt[%d] is %d",i, gnt_cnt[i])
            assert gnt_cnt[i] == dut.wt_i[i].value

        await FallingEdge(dut.clk_i)
        gnt_cnt = [0,0,0,0,0,0,0,0,]
        while dut.round_end.value != 1:
            await FallingEdge(dut.clk_i)
            gnt_o = int(dut.gnt_o.value);
            for i in range(0,8):
                if gnt_o & (1<<i) != 0:
                    gnt_cnt[i] = gnt_cnt[i] + 1
        for i in range(0,8):
            cocotb.log.info("gnt_cnt[%d] is %d",i, gnt_cnt[i])
            assert gnt_cnt[i] == dut.wt_i[i].value



    await Timer(60, unit="ns")

