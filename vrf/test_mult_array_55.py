
import cocotb
import random
from cocotb.triggers import Timer
from cocotb.types import LogicArray

@cocotb.test()
async def test_odl_mult_array(dut):
    """Test 5x5 array multiplier (includes 100 unsigned + 100 signed random test cases)"""

    # Convert integer to 5-bit unsigned LogicArray (range: 0~31)
    def int_to_u5(value):
        return LogicArray(f"{value & 0b11111:05b}")

    # Convert integer to 5-bit signed LogicArray (range: -16~15, two's complement)
    def int_to_s5(value):
        unsigned_val = value & 0b11111
        return LogicArray(f"{unsigned_val:05b}")

    # Parse 10-bit output to integer (distinguish unsigned/signed mode)
    def p_to_int(value, mode):
        bin_str = str(value).zfill(10)
        if mode == 1:  # Signed mode: parse as two's complement
            if bin_str[0] == '1':
                inverted = ''.join('1' if c == '0' else '0' for c in bin_str)
                return - (int(inverted, 2) + 1)
            else:
                return int(bin_str, 2)
        else:  # Unsigned mode: direct decimal conversion
            return int(bin_str, 2)

    # ==============================
    # 1. Basic boundary test cases (core scenarios)
    # ==============================
    basic_cases = [
        # Unsigned boundary cases
        (0, 0, 0, 0),
        (1, 1, 0, 1),
        (1, 5, 0, 5),
        (31, 1, 0, 31),
        (31, 31, 0, 961),
        (15, 15, 0, 225),
        # Signed boundary cases (two's complement)
        (1, 1, 1, 1),
        (-1, 1, 1, -1),
        (-1, -1, 1, 1),
        (-16, 1, 1, -16),
        (-16, -16, 1, 256),
        (7, -8, 1, -56),
        (15, 15, 1, 225),
        (-16, 15, 1, -240),
    ]

    # Run basic boundary cases
    print("===== Running Basic Boundary Test Cases =====")
    for idx, (x_val, y_val, mode_val, expected) in enumerate(basic_cases):
        if mode_val == 0:
            dut.X.value = int_to_u5(x_val)
            dut.Y.value = int_to_u5(y_val)
        else:
            dut.X.value = int_to_s5(x_val)
            dut.Y.value = int_to_s5(y_val)

        dut.mode.value = mode_val
        await Timer(1, unit="ns")

        result = p_to_int(dut.P.value, mode_val)
        assert result == expected, \
            f"Basic case failed (idx={idx}): X={x_val}, Y={y_val}, mode={mode_val} | Expected {expected}, Actual {result}"
        print(f"Basic case {idx+1} passed: {x_val} * {y_val} (mode={mode_val}) = {result}")

    # ==============================
    # 2. Random test cases (100 unsigned + 100 signed)
    # ==============================
    random.seed(42)  # Fixed seed for reproducible test results
    fail_count = 0

    # 2.1 Unsigned random tests (range: 0~31)
    print("\n===== Running 100 Unsigned Random Test Cases =====")
    for idx in range(100):
        x = random.randint(0, 31)
        y = random.randint(0, 31)
        mode = 0
        expected = x * y  # Direct multiplication for unsigned

        dut.X.value = int_to_u5(x)
        dut.Y.value = int_to_u5(y)
        dut.mode.value = mode
        await Timer(1, unit="ns")

        result = p_to_int(dut.P.value, mode)
        try:
            assert result == expected, \
                f"Unsigned random case {idx+1} failed: X={x}, Y={y} | Expected {expected}, Actual {result}"
            print(f"Unsigned random case {idx+1} passed: {x} * {y} = {result}")
        except AssertionError as e:
            print(e)
            fail_count += 1

    # 2.2 Signed random tests (range: -16~15)
    print("\n===== Running 100 Signed Random Test Cases =====")
    for idx in range(100):
        x = random.randint(-16, 15)
        y = random.randint(-16, 15)
        mode = 1
        expected = x * y  # Direct multiplication for signed

        dut.X.value = int_to_s5(x)
        dut.Y.value = int_to_s5(y)
        dut.mode.value = mode
        await Timer(1, unit="ns")

        result = p_to_int(dut.P.value, mode)
        try:
            assert result == expected, \
                f"Signed random case {idx+1} failed: X={x}, Y={y} | Expected {expected}, Actual {result}"
            print(f"Signed random case {idx+1} passed: {x} * {y} = {result}")
        except AssertionError as e:
            print(e)
            fail_count += 1

    # ==============================
    # 3. Test summary
    # ==============================
    print("\n===== Test Summary =====")
    total_cases = len(basic_cases) + 200
    pass_count = total_cases - fail_count
    print(f"Total cases: {total_cases} | Passed: {pass_count} | Failed: {fail_count}")

    if fail_count == 0:
        print("All test cases (basic + random) passed successfully.")
    else:
        assert fail_count == 0, f"{fail_count} test cases failed, please check the implementation."
