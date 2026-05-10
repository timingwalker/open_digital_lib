# AGENTS.md

## Project Overview

open_digital_lib is a digital design library. RTL lives under `design/`, and cocotb verification lives under `vrf/`.

## RTL Style

- Use the `ODL_` prefix for public RTL modules.
- Keep the file name the same as the module name, for example `ODL_mult_shift_add.sv`.
- Put RTL in the matching category directory under `design/`.
- Use `_i` suffix for inputs and `_o` suffix for outputs.
- Use `clk_i` and active-low `rst_ni` for clocked modules when applicable.
- Prefer `parameter int` for parameterized RTL.
- For sequential RTL, use one `always_ff` block per registered signal.
- Internal register names do not need a `_q` suffix.
- Keep comments concise. Explain algorithm intent or non-obvious logic only.
- Keep file headers accurate. Update `Last Modified` whenever editing a file with that header.

## Verification

- Add cocotb tests under `vrf/test_<tc>.py`.
- Add new testcases to `vrf/Makefile` with `TC=<name>`.
- For parameterized modules, pass parameters through `EXTRA_ARGS += -G<param>=$(<param>)`.
- Run relevant tests before finishing.
- For parameterized arithmetic modules, test multiple widths when practical, such as `N=5`, `8`, `16`, and `32`.

## Repository Hygiene

- Do not commit generated simulation outputs such as `sim_build/`, `results.xml`, or `dump.vcd`.
- Update `README.md` when adding a public module.
- Prefer feature branches and pull requests for new modules or behavioral changes.
- Before creating a git commit, show the proposed commit message to the user and wait for confirmation.
