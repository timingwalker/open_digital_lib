// ----------------------------------------------------------------------
// Copyright 2026 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
// Create Date   : 2026-03-25 22:08:05
// Last Modified : 2026-04-06 02:20:00
// Description   : Parameterized N×N Array Multiplier (Baugh-Wooley Architecture)
//                 Optimized from ODL_mult_array_55 with generate loops
// ----------------------------------------------------------------------

// Parameterized N×N Array Multiplier (Baugh-Wooley Architecture)
// Features:
// - Supports unsigned (mode=0) and signed (mode=1, two's complement) multiplication
// - Parameterized bit-width N (default 5, same as original)
// - Input: N-bit X, N-bit Y; Output: 2*N-bit product P
// - Mode control: 0 = unsigned, 1 = signed (Baugh-Wooley correction)
// - Generate loops replace manual instantiation for CSA and CPA stages
module ODL_mult_array #(
    parameter int N = 5
)(
    input  logic [N-1:0] X,         // N-bit multiplier
    input  logic [N-1:0] Y,         // N-bit multiplicand
    input  logic       mode,        // 0=unsigned, 1=signed
    output logic [2*N-1:0] P        // 2*N-bit product
);

    // ------------------------------------------------------------------
    // Partial Products: pp[i][j] = X[i] & Y[j]
    // No Baugh-Wooley correction here; applied at point of use.
    // ------------------------------------------------------------------
    logic [N-1:0][N-1:0] pp;

    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : gen_pp_row
            for (j = 0; j < N; j++) begin : gen_pp_col
                assign pp[i][j] = X[i] & Y[j];
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // CSA (Carry-Save Adder) Array
    //   Row 1 (k=1): Half Adders
    //   Rows 2..N-1 (k=2..N-1): Full Adders
    //
    // Row 1, column j:
    //   j=0:     HA(pp[1][N-1]^mode, mode,       c_prev[0])
    //   j=N-1:   HA(pp[1][0],      pp[0][N-1]^mode, ...)
    //   else:    HA(pp[1][N-1-j],  pp[0][j],       ...)
    //
    // Row k (2<=k<=N-1), column j:
    //   j=0, k<N-1:     FA(pp[k][N-1]^mode, 1'b0,          c[k-1][0])
    //   j=0, k=N-1:     FA(pp[N-1][N-1],   1'b0,          c[N-2][0])
    //   j>=1, k<N-1:    FA(pp[k][N-1-j],   s[k-1][j-1],   c[k-1][j])
    //   j>=1, k=N-1:    FA(pp[N-1][N-1-j]^mode, s[N-2][j-1], c[N-2][j])
    // ------------------------------------------------------------------
    logic [N-1:1][N-1:0] csa_s;
    logic [N-1:1][N-1:0] csa_c;

    // --- Row 1: Half Adders ---
    generate
        for (j = 0; j < N; j++) begin : gen_csa1
            if (j == 0) begin : col0
                HA u_ha (
                    .a (pp[1][N-1] ^ mode),
                    .b (mode),
                    .s (csa_s[1][0]),
                    .co(csa_c[1][0])
                );
            end else if (j == 1) begin : col_sign
                HA u_ha (
                    .a (pp[1][N-2]),
                    .b (pp[0][N-1] ^ mode),
                    .s (csa_s[1][j]),
                    .co(csa_c[1][j])
                );
            end else begin : col_mid
                HA u_ha (
                    .a (pp[1][N-1-j]),
                    .b (pp[0][N-j]),
                    .s (csa_s[1][j]),
                    .co(csa_c[1][j])
                );
            end
        end
    endgenerate

    // --- Rows 2..N-1: Full Adders ---
    generate
        for (i = 2; i < N; i++) begin : gen_csa_row
            for (j = 0; j < N; j++) begin : gen_csa_col
                if (j == 0 && i < N-1) begin : fa_sign
                    FA u_fa (
                        .a (pp[i][N-1] ^ mode),
                        .b (1'b0),
                        .ci(csa_c[i-1][0]),
                        .s (csa_s[i][0]),
                        .co(csa_c[i][0])
                    );
                end else if (j == 0 && i == N-1) begin : fa_last_first
                    FA u_fa (
                        .a (pp[N-1][N-1]),
                        .b (1'b0),
                        .ci(csa_c[N-2][0]),
                        .s (csa_s[N-1][0]),
                        .co(csa_c[N-1][0])
                    );
                end else if (i < N-1) begin : fa_mid
                    FA u_fa (
                        .a (pp[i][N-1-j]),
                        .b (csa_s[i-1][j-1]),
                        .ci(csa_c[i-1][j]),
                        .s (csa_s[i][j]),
                        .co(csa_c[i][j])
                    );
                end else begin : fa_last_rest
                    FA u_fa (
                        .a (pp[N-1][N-1-j] ^ mode),
                        .b (csa_s[N-2][j-1]),
                        .ci(csa_c[N-2][j]),
                        .s (csa_s[N-1][j]),
                        .co(csa_c[N-1][j])
                    );
                end
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // CPA (Carry-Propagate Adder) — ripple
    //   j=0:     FA(s[N-1][N-2], c[N-1][N-1],       1'b0)
    //   1<=j<N-1: FA(s[N-1][N-2-j], c[N-1][N-1-j], cp[j-1])
    //   j=N-1:   FA(c[N-1][0],    mode,             cp[N-2])
    //   Output: P[N+j] for j = 0..N-1
    // ------------------------------------------------------------------
    logic [N-2:0] cpa_carry;

    generate
        for (j = 0; j < N; j++) begin : gen_cpa
            if (j == 0) begin : cpa_first
                FA u_fa (
                    .a (csa_s[N-1][N-2]),
                    .b (csa_c[N-1][N-1]),
                    .ci(1'b0),
                    .s (P[N]),
                    .co(cpa_carry[0])
                );
            end else if (j == N-1) begin : cpa_last
                FA u_fa (
                    .a (csa_c[N-1][0]),
                    .b (mode),
                    .ci(cpa_carry[j-1]),
                    .s (P[N+j]),
                    .co()   // MSB carry unused — product fits in 2*N bits
                );
            end else begin : cpa_mid
                FA u_fa (
                    .a (csa_s[N-1][N-2-j]),
                    .b (csa_c[N-1][N-1-j]),
                    .ci(cpa_carry[j-1]),
                    .s (P[N+j]),
                    .co(cpa_carry[j])
                );
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // Lower product bits: P[0] from pp[0][0], P[k] from csa_s[k][N-1]
    // ------------------------------------------------------------------
    assign P[0] = pp[0][0];

    generate
        for (j = 1; j < N; j++) begin : gen_lower
            assign P[j] = csa_s[j][N-1];
        end
    endgenerate

endmodule
