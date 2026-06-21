import os
import cocotb
import random
from cocotb.triggers import Timer
from cocotb.types import LogicArray

@cocotb.test()
async def test_odl_mult_array(dut):
    """Parameterized N×N array multiplier test (N from environment or default 5)"""

    N = int(os.environ.get("N", 5))
    unsigned_max = (1 << N) - 1
    signed_min   = -(1 << (N - 1))
    signed_max   = (1 << (N - 1)) - 1

    def int_to_logic(value, bits):
        return LogicArray(value & ((1 << bits) - 1), bits)

    def p_to_int(value, mode):
        unsigned = int(value)
        if mode == 1 and unsigned >= (1 << (2*N - 1)):
            unsigned -= (1 << (2*N))
        return unsigned

    n_random = 100 if N <= 16 else 200

    # ==============================
    # 1. Basic boundary test cases
    # ==============================
    basic_cases = [
        # Unsigned
        (0, 0, 0, 0), (1, 1, 0, 1), (1, unsigned_max, 0, unsigned_max),
        (unsigned_max, 1, 0, unsigned_max),
        (unsigned_max, unsigned_max, 0, unsigned_max * unsigned_max),
        (signed_max, signed_max, 0, signed_max * signed_max),
        # Signed
        (1, 1, 1, 1), (-1, 1, 1, -1), (-1, -1, 1, 1),
        (signed_min, 1, 1, signed_min),
        (signed_min, signed_min, 1, signed_min * signed_min),
        (7, -8, 1, -56),
        (signed_max, signed_max, 1, signed_max * signed_max),
        (signed_min, signed_max, 1, signed_min * signed_max),
    ]

    print(f"===== N={N} Parameterized Array Multiplier =====")
    print(f"===== Running {len(basic_cases)} Basic Boundary Test Cases =====")
    for idx, (x_val, y_val, mode_val, expected) in enumerate(basic_cases):
        dut.multiplier_i.value = int_to_logic(x_val, N)
        dut.multiplicand_i.value = int_to_logic(y_val, N)
        dut.mode_i.value = mode_val
        await Timer(1, unit="ns")

        result = p_to_int(dut.product_o.value, mode_val)
        assert result == expected, \
            f"Basic case {idx+1} failed: X={x_val}, Y={y_val}, mode={mode_val} | Expected {expected}, Got {result}"
        print(f"Basic case {idx+1:2d} passed: {x_val:>6d} * {y_val:>6d} (mode={mode_val}) = {result}")

    # ==============================
    # 2. Random test cases
    # ==============================
    random.seed(42)
    fail = 0

    print(f"\n===== Running {n_random} Unsigned Random Test Cases =====")
    for idx in range(n_random):
        x = random.randint(0, unsigned_max)
        y = random.randint(0, unsigned_max)
        dut.multiplier_i.value = int_to_logic(x, N)
        dut.multiplicand_i.value = int_to_logic(y, N)
        dut.mode_i.value = 0
        await Timer(1, unit="ns")
        result = p_to_int(dut.product_o.value, 0)
        if result != x * y:
            print(f"Unsigned case {idx+1} FAIL: {x}*{y}={x*y}, got {result}")
            fail += 1
    u_pass = n_random - fail

    print(f"\n===== Running {n_random} Signed Random Test Cases =====")
    for idx in range(n_random):
        x = random.randint(signed_min, signed_max)
        y = random.randint(signed_min, signed_max)
        dut.multiplier_i.value = int_to_logic(x, N)
        dut.multiplicand_i.value = int_to_logic(y, N)
        dut.mode_i.value = 1
        await Timer(1, unit="ns")
        result = p_to_int(dut.product_o.value, 1)
        if result != x * y:
            print(f"Signed case {idx+1} FAIL: {x}*{y}={x*y}, got {result}")
            fail += 1
    s_pass = n_random - (fail - (n_random - u_pass))

    total = len(basic_cases) + 2 * n_random
    passed = total - fail
    print(f"\n===== Total: {total} | Passed: {passed} | Failed: {fail} =====")
    assert fail == 0, f"{fail} cases failed"
    print("All cases passed!")
