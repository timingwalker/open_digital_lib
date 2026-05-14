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
- Preserve key micro-architecture details from design diagrams, such as pipeline registers, carry/sum propagation, and critical-path breaks. Do not replace them with only functionally equivalent abstractions unless the user explicitly approves the architectural change.
- For sequential RTL, use one `always_ff` block per registered signal by default. Registers that belong to the same pipeline or state group may share one `always_ff` block when their update conditions are exactly the same.
- Internal register names do not need a `_q` suffix.
- Keep comments concise. Explain algorithm intent or non-obvious logic only.
- Keep file headers accurate. Update `Last Modified` whenever editing a file with that header.

## Verification

- Add cocotb tests under `vrf/test_<tc>.py`.
- Add new testcases to `vrf/Makefile` with `TC=<name>`.
- For parameterized modules, pass parameters through `EXTRA_ARGS += -G<param>=$(<param>)`.
- Drive cocotb input stimulus after `RisingEdge(clk_i)` plus a small delay to model upstream registers, unless a test explicitly needs a different timing relationship.
- Run relevant tests before finishing.
- For parameterized arithmetic modules, test multiple widths when practical, such as `N=5`, `8`, `16`, and `32`.

## Repository Hygiene

- Do not commit generated simulation outputs such as `sim_build/`, `results.xml`, or `dump.vcd`.
- Curated GTKWave signal view files may be committed under `vrf/gtkw/` using the testcase name, for example `vrf/gtkw/<tc>.gtkw` for `TC=<tc>`.
- Update `README.md` when adding a public module.
- Prefer feature branches and pull requests for new modules or behavioral changes.
- Before running `git add`, list the files that will be staged and wait for user confirmation.
- Before creating a git commit, show the proposed commit message to the user and wait for confirmation.
