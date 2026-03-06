# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def ODL_test(dut):

    dut.req_i.value = 0b00001111
    await Timer(1, unit="ns")
    cocotb.log.info("fpa.req is %s", dut.req_i.value)
    cocotb.log.info("fpa.gnt is %s", dut.gnt_o.value)
    assert dut.gnt_o.value == 0b00000001

    dut.req_i.value = 0b01001110
    await Timer(1, unit="ns")
    cocotb.log.info("fpa.req is %s", dut.req_i.value)
    cocotb.log.info("fpa.gnt is %s", dut.gnt_o.value)
    assert dut.gnt_o.value == 0b00000010

    dut.req_i.value = 0b01001001
    await Timer(1, unit="ns")
    cocotb.log.info("fpa.req is %s", dut.req_i.value)
    cocotb.log.info("fpa.gnt is %s", dut.gnt_o.value)
    assert dut.gnt_o.value == 0b00000001

    dut.req_i.value = 0b01101000
    await Timer(1, unit="ns")
    cocotb.log.info("fpa.req is %s", dut.req_i.value)
    cocotb.log.info("fpa.gnt is %s", dut.gnt_o.value)
    assert dut.gnt_o.value == 0b00001000

    dut.req_i.value = 0b11100000
    await Timer(1, unit="ns")
    cocotb.log.info("fpa.req is %s", dut.req_i.value)
    cocotb.log.info("fpa.gnt is %s", dut.gnt_o.value)
    assert dut.gnt_o.value == 0b00100000

