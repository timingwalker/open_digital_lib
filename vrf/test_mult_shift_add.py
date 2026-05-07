import os
import random

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge, Timer


async def generate_clock(dut):
    for _ in range(20000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")


async def reset_dut(dut):
    dut.rst_ni.value = 0
    dut.start_i.value = 0
    dut.multiplicand_i.value = 0
    dut.multiplier_i.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")

    assert dut.busy_o.value == 0
    assert dut.done_o.value == 0
    assert dut.product_o.value == 0


async def run_mult_case(dut, n, multiplicand, multiplier, check_busy_start=False):
    expected = multiplicand * multiplier
    mask = (1 << n) - 1

    await FallingEdge(dut.clk_i)
    dut.multiplicand_i.value = multiplicand & mask
    dut.multiplier_i.value = multiplier & mask
    dut.start_i.value = 1

    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    assert dut.busy_o.value == 1
    assert dut.done_o.value == 0

    for cycle in range(n):
        await FallingEdge(dut.clk_i)

        if check_busy_start and cycle == n // 2:
            dut.multiplicand_i.value = mask
            dut.multiplier_i.value = mask
            dut.start_i.value = 1
        else:
            dut.start_i.value = 0

        await RisingEdge(dut.clk_i)
        await Timer(1, unit="ps")

        if cycle == n - 1:
            assert dut.busy_o.value == 0
            assert dut.done_o.value == 1
            assert int(dut.product_o.value) == expected, (
                f"{multiplicand} * {multiplier}: expected {expected}, "
                f"got {int(dut.product_o.value)}"
            )
        else:
            assert dut.busy_o.value == 1
            assert dut.done_o.value == 0

    await FallingEdge(dut.clk_i)
    dut.start_i.value = 0
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    assert dut.done_o.value == 0
    assert int(dut.product_o.value) == expected


@cocotb.test()
async def ODL_test(dut):
    n = int(os.environ.get("N", 5))
    max_value = (1 << n) - 1

    cocotb.start_soon(generate_clock(dut))
    await reset_dut(dut)

    basic_cases = [
        (0, 0),
        (0, max_value),
        (max_value, 0),
        (1, max_value),
        (max_value, 1),
        (max_value, max_value),
    ]

    if n >= 5:
        basic_cases.append((0b01110, 0b11010))

    for multiplicand, multiplier in basic_cases:
        await run_mult_case(dut, n, multiplicand, multiplier)

    await run_mult_case(dut, n, max_value - 1, max_value, check_busy_start=True)

    random.seed(42)
    for _ in range(100):
        multiplicand = random.randint(0, max_value)
        multiplier = random.randint(0, max_value)
        await run_mult_case(dut, n, multiplicand, multiplier)
