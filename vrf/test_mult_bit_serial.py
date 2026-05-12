import os
import random

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge, Timer


async def generate_clock(dut):
    for _ in range(50000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")


async def reset_dut(dut):
    dut.rst_ni.value = 0
    dut.start_i.value = 0
    dut.x_i.value = 0
    dut.y_i.value = 0
    await Timer(30, unit="ns")
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")

    assert dut.p_o.value == 0
    assert dut.busy_o.value == 0
    assert dut.done_o.value == 0


async def run_mult_case(dut, n, x_value, y_value, check_busy_start=False):
    expected = x_value * y_value
    expected_bits = [(expected >> i) & 1 for i in range(2 * n)]
    max_value = (1 << n) - 1
    collision_idx = max(1, n // 2)

    await FallingEdge(dut.clk_i)
    dut.start_i.value = 1
    dut.x_i.value = x_value & 1
    dut.y_i.value = y_value

    for idx, expected_bit in enumerate(expected_bits):
        await RisingEdge(dut.clk_i)
        await Timer(1, unit="ps")

        assert int(dut.p_o.value) == expected_bit, (
            f"bit {idx} failed for {x_value} * {y_value}: "
            f"expected {expected_bit}, got {int(dut.p_o.value)}"
        )

        if idx == (2 * n) - 1:
            assert dut.busy_o.value == 0
            assert dut.done_o.value == 1
        else:
            assert dut.busy_o.value == 1
            assert dut.done_o.value == 0

        await FallingEdge(dut.clk_i)
        next_idx = idx + 1
        dut.x_i.value = (x_value >> next_idx) & 1 if next_idx < n else 0

        if check_busy_start and next_idx == collision_idx and next_idx < (2 * n) - 1:
            dut.start_i.value = 1
            dut.y_i.value = max_value
        else:
            dut.start_i.value = 0
            dut.y_i.value = 0

    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    assert dut.busy_o.value == 0
    assert dut.done_o.value == 0
    assert int(dut.p_o.value) == expected_bits[-1]


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
        basic_cases.append((0b11010, 0b01110))

    for x_value, y_value in basic_cases:
        await run_mult_case(dut, n, x_value, y_value)

    await run_mult_case(dut, n, max_value - 1, max_value, check_busy_start=True)

    random.seed(42)
    for _ in range(100):
        x_value = random.randint(0, max_value)
        y_value = random.randint(0, max_value)
        await run_mult_case(dut, n, x_value, y_value)
