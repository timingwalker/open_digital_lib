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
// Last Modified : 2026-06-21 15:03:13
// Description   : Parameterized NxN Array Multiplier 
//                 Baugh-Wooley Architecture
// ----------------------------------------------------------------------

module ODL_mult_array #(
    parameter int N = 5 // valid range: N >= 2
)(
    input  logic [N-1:0]   multiplier_i,   // N-bit multiplier
    input  logic [N-1:0]   multiplicand_i, // N-bit multiplicand
    input  logic           mode_i,         // 0=unsigned, 1=signed
    output logic [2*N-1:0] product_o       // 2*N-bit product
);

    // ----------------------------------------------------------------------
    //  SIGNAL DEFINE
    // ----------------------------------------------------------------------
    logic [N-1:0][N-1:0] pp;
    logic [N-1:1][N-1:0] csa_s;
    logic [N-1:1][N-1:0] csa_c;
    logic [N-2:0]        cpa_carry;

    // ----------------------------------------------------------------------
    //  partial product
    // ----------------------------------------------------------------------
    // Baugh-Wooley correction is applied at adder inputs.
    generate
        for (genvar i = 0; i < N; i++) begin : gen_pp_row
            for (genvar j = 0; j < N; j++) begin : gen_pp_col
                assign pp[i][j] = multiplier_i[i] & multiplicand_i[j];
            end
        end
    endgenerate

    // ----------------------------------------------------------------------
    //  carry-save array
    // ----------------------------------------------------------------------

    // Row 1 uses HA cells; later rows use FA cells.
    generate
        for (genvar j = 0; j < N; j++) begin : gen_csa1
            if (j == 0) begin : col0
                HA U_CSA_HA (
                    .a (pp[1][N-1] ^ mode_i),
                    .b (mode_i),
                    .s (csa_s[1][0]),
                    .co(csa_c[1][0])
                );
            end else if (j == 1) begin : col_sign
                HA U_CSA_HA (
                    .a (pp[1][N-2]),
                    .b (pp[0][N-1] ^ mode_i),
                    .s (csa_s[1][j]),
                    .co(csa_c[1][j])
                );
            end else begin : col_mid
                HA U_CSA_HA (
                    .a (pp[1][N-1-j]),
                    .b (pp[0][N-j]),
                    .s (csa_s[1][j]),
                    .co(csa_c[1][j])
                );
            end
        end
    endgenerate

    generate
        for (genvar i = 2; i < N; i++) begin : gen_csa_row
            for (genvar j = 0; j < N; j++) begin : gen_csa_col
                if (j == 0 && i < N-1) begin : fa_sign
                    FA U_CSA_FA (
                        .a (pp[i][N-1] ^ mode_i),
                        .b (1'b0),
                        .ci(csa_c[i-1][0]),
                        .s (csa_s[i][0]),
                        .co(csa_c[i][0])
                    );
                end else if (j == 0 && i == N-1) begin : fa_last_first
                    FA U_CSA_FA (
                        .a (pp[N-1][N-1]),
                        .b (1'b0),
                        .ci(csa_c[N-2][0]),
                        .s (csa_s[N-1][0]),
                        .co(csa_c[N-1][0])
                    );
                end else if (i < N-1) begin : fa_mid
                    FA U_CSA_FA (
                        .a (pp[i][N-1-j]),
                        .b (csa_s[i-1][j-1]),
                        .ci(csa_c[i-1][j]),
                        .s (csa_s[i][j]),
                        .co(csa_c[i][j])
                    );
                end else begin : fa_last_rest
                    FA U_CSA_FA (
                        .a (pp[N-1][N-1-j] ^ mode_i),
                        .b (csa_s[N-2][j-1]),
                        .ci(csa_c[N-2][j]),
                        .s (csa_s[N-1][j]),
                        .co(csa_c[N-1][j])
                    );
                end
            end
        end
    endgenerate

    // ----------------------------------------------------------------------
    //  carry-propagate adder
    // ----------------------------------------------------------------------

    // Ripple carry stage forms the upper product bits.
    generate
        for (genvar j = 0; j < N; j++) begin : gen_cpa
            if (j == 0) begin : cpa_first
                FA U_CPA_FA (
                    .a (csa_s[N-1][N-2]),
                    .b (csa_c[N-1][N-1]),
                    .ci(1'b0),
                    .s (product_o[N]),
                    .co(cpa_carry[0])
                );
            end else if (j == N-1) begin : cpa_last
                FA U_CPA_FA (
                    .a (csa_c[N-1][0]),
                    .b (mode_i),
                    .ci(cpa_carry[j-1]),
                    .s (product_o[N+j]),
                    .co()   // MSB carry unused - product fits in 2*N bits
                );
            end else begin : cpa_mid
                FA U_CPA_FA (
                    .a (csa_s[N-1][N-2-j]),
                    .b (csa_c[N-1][N-1-j]),
                    .ci(cpa_carry[j-1]),
                    .s (product_o[N+j]),
                    .co(cpa_carry[j])
                );
            end
        end
    endgenerate

    // ----------------------------------------------------------------------
    //  product output
    // ----------------------------------------------------------------------
    assign product_o[0] = pp[0][0];
    generate
        for (genvar j = 1; j < N; j++) begin : gen_lower
            assign product_o[j] = csa_s[j][N-1];
        end
    endgenerate

endmodule
