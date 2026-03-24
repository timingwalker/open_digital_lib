# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def ODL_test(dut):

    for i in range (0,256):
        dut.bin_i.value = i
        await Timer(1, unit="ns")

    await Timer(1, unit="ns")


