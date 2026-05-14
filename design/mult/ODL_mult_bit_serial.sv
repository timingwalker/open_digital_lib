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
// Create Date   : 2026-05-12 23:49:00
// Last Modified : 2026-05-14 23:23:13
// Description   : Parameterized unsigned bit-serial multiplier
// ----------------------------------------------------------------------

module ODL_mult_bit_serial #(
    parameter int N = 5 // valid range: N >= 1
)(
     input  logic             clk_i
    ,input  logic             rst_ni
    ,input  logic             start_i
    ,input  logic             multiplier_i   // LSB-first; bit 0 is sampled with accepted start_i
    ,input  logic [N-1:0]     multiplicand_i // keep stable from accepted start_i until valid_o drops
    ,output logic             product_o
    ,output logic             valid_o
);

    // ----------------------------------------------------------------------
    //  PARAMETER DEFINE
    // ----------------------------------------------------------------------
    localparam int PRODUCT_WIDTH = 2 * N;
    localparam int CNT_WIDTH     = $clog2(PRODUCT_WIDTH + 1);

    // ----------------------------------------------------------------------
    //  SIGNAL DEFINE
    // ----------------------------------------------------------------------
    logic [N-1:0]             sum_1d;       // registered sum pipeline
    logic [N-1:0]             carry_1d;     // registered local carry feedback
    logic [CNT_WIDTH-1:0]     cnt;
    logic                     busy;
    logic                     start_accept;
    logic                     multiplier;
    logic [N-1:0]             partial_product;
    logic [N-1:0]             sum_1d_shift;
    logic [N-1:0]             sum;
    logic [N-1:0]             carry;
    logic                     last_cycle;


    // ----------------------------------------------------------------------
    //  control logic
    // ----------------------------------------------------------------------

    assign start_accept = start_i && ~busy;

    assign last_cycle      = ( cnt == CNT_WIDTH'(PRODUCT_WIDTH) );

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            busy <= 1'b0;
        end
        else if ( start_accept ) begin
            busy <= 1'b1;
        end
        else if ( last_cycle ) begin
            busy <= 1'b0;
        end
    end


    // ----------------------------------------------------------------------
    //  data path 
    // ----------------------------------------------------------------------
    
    // Consume multiplier_i for N cycles, then shift out the remaining upper product bits.
    assign multiplier      = ( cnt < CNT_WIDTH'(N) ) ? multiplier_i : 1'b0;
    assign partial_product = {N{multiplier}} & multiplicand_i;

    // One FA per bit-slice. Sum moves toward product_o; carry feeds back locally.
    assign sum_1d_shift = sum_1d >> 1;
    for ( genvar i=0; i<N; i++ ) begin : gen_bit_slice
        FA U_FA (
            .a   ( partial_product[i] )
            ,.b  ( sum_1d_shift[i]    )
            ,.ci ( carry_1d[i]        )
            ,.s  ( sum[i]             )
            ,.co ( carry[i]           )
        );
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            sum_1d   <= '0;
            carry_1d <= '0;
            cnt      <= '0;
        end
        else if ( last_cycle ) begin
            sum_1d   <= '0;
            carry_1d <= '0;
            cnt      <= '0;
        end
        else if ( start_accept || busy ) begin
            sum_1d   <= sum;
            carry_1d <= carry;
            cnt      <= cnt + CNT_WIDTH'(1);
        end
    end

    assign product_o = sum_1d[0];
    assign valid_o   = busy;

endmodule
