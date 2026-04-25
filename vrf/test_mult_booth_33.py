import cocotb
from cocotb.triggers import Timer
import random

def to_signed(val, bits):
    """Interpret an unsigned value as signed with given bit width."""
    v = int(val)
    if v >= (1 << (bits - 1)):
        v -= (1 << bits)
    return v

def rand_33():
    return random.randint(-(1<<32), (1<<32)-1)

@cocotb.test()
async def test_basic(dut):
    """Basic known-value tests"""
    cases = [
        (5, 7, 35),
        (-3, 8, -24),
        (0, 42, 0),
        (1, -1, -1),
        (-1, -1, 1),
    ]
    for x, y, exp in cases:
        dut.X.value = x & 0x1FFFFFFFF
        dut.Y.value = y & 0x1FFFFFFFF
        await Timer(10, units='ns')
        got = to_signed(int(dut.P.value), 66)
        assert got == exp, f"Basic {x}×{y}: got {got}, expected {exp}"
    dut._log.info("All basic tests pass!")

@cocotb.test()
async def test_powers_of_2(dut):
    """Powers of 2 multiplication (within 33-bit signed range)"""
    for i in range(32):      # 2^0 .. 2^31
        for k in range(32):  # 2^0 .. 2^31
            x, y, exp = 1 << i, 1 << k, (1 << i) * (1 << k)
            dut.X.value = x & 0x1FFFFFFFF
            dut.Y.value = y & 0x1FFFFFFFF
            await Timer(10, units='ns')
            got = to_signed(int(dut.P.value), 66)
            assert got == exp, f"2^{i} × 2^{k}: got {got}, expected {exp}"
    dut._log.info("All powers-of-2 tests pass!")

@cocotb.test()
async def test_random_1k(dut):
    """1k random test vectors"""
    for _ in range(1000):
        x, y = rand_33(), rand_33()
        dut.X.value = x & 0x1FFFFFFFF
        dut.Y.value = y & 0x1FFFFFFFF
        await Timer(1, units='ns')
        got = to_signed(int(dut.P.value), 66)
        assert got == x * y, f"Random {x}×{y}: got {got}, expected {x*y}"
    dut._log.info("1k random tests pass!")

@cocotb.test()
async def test_random_10k(dut):
    """10k random test vectors"""
    for _ in range(10000):
        x, y = rand_33(), rand_33()
        dut.X.value = x & 0x1FFFFFFFF
        dut.Y.value = y & 0x1FFFFFFFF
        await Timer(1, units='ns')
        got = to_signed(int(dut.P.value), 66)
        assert got == x * y, f"Random {x}×{y}: got {got}, expected {x*y}"
    dut._log.info("10k random tests pass!")

@cocotb.test()
async def test_all_ones_patterns(dut):
    """All-ones and mixed patterns"""
    patterns = [
        (0x7FFFFFFF, 0x7FFFFFFF),     # max positive × max positive
        (0x80000000, 0x7FFFFFFF),     # min negative × max positive (33-bit)
        (0x80000000, 0x80000000),     # min × min
        (0x55555555, 0xAAAAAAAA),
        (0xAAAAAAAA, 0x55555555),
        (0x33333333, 0xCCCCCCCC),
    ]
    for x, y in patterns:
        xs = to_signed(x, 33)
        ys = to_signed(y, 33)
        exp = xs * ys
        dut.X.value = x
        dut.Y.value = y
        await Timer(10, units='ns')
        got = to_signed(int(dut.P.value), 66)
        assert got == exp, f"Pattern 0x{x:08x}×0x{y:08x}: got {got}, expected {exp}"
    dut._log.info("All pattern tests pass!")

@cocotb.test()
async def test_symmetric_pairs(dut):
    """X*Y == Y*X"""
    for _ in range(500):
        x, y = rand_33(), rand_33()
        dut.X.value = x & 0x1FFFFFFFF
        dut.Y.value = y & 0x1FFFFFFFF
        await Timer(1, units='ns')
        xy = to_signed(int(dut.P.value), 66)

        dut.X.value = y & 0x1FFFFFFFF
        dut.Y.value = x & 0x1FFFFFFFF
        await Timer(1, units='ns')
        yx = to_signed(int(dut.P.value), 66)

        assert xy == yx, f"Asymmetry: {x}×{y}={xy}, {y}×{x}={yx}"
    dut._log.info("Symmetric pair tests pass!")

@cocotb.test()
async def test_boundary_exhaustive(dut):
    """Boundary values: ±1, ±2, MAX, MIN, 0"""
    bounds = [0, 1, -1, 2, -2, (1<<32)-1, -(1<<32)]
    for x in bounds:
        for y in bounds:
            dut.X.value = x & 0x1FFFFFFFF
            dut.Y.value = y & 0x1FFFFFFFF
            await Timer(10, units='ns')
            got = to_signed(int(dut.P.value), 66)
            assert got == x * y, f"Boundary {x}×{y}: got {got}, expected {x*y}"
    dut._log.info("Boundary exhaustive tests pass!")

@cocotb.test()
async def test_carry_propagation(dut):
    """Exhaustive small-value test to verify carry propagation"""
    for x in range(-128, 128):
        for y in range(-128, 128):
            dut.X.value = x & 0x1FFFFFFFF
            dut.Y.value = y & 0x1FFFFFFFF
            await Timer(1, units='ns')
            got = to_signed(int(dut.P.value), 66)
            assert got == x * y, f"{x} x {y} = got {got}, expected {x*y}"
    dut._log.info("All small values pass!")
