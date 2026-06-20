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
// Create Date   : 2026-05-07 23:30:45
// Last Modified : 2026-06-21 02:29:40
// Description   : Parameterized unsigned shift-add multiplier
// ----------------------------------------------------------------------

module ODL_mult_shift_add #(
    parameter int N = 5 // valid range: N >= 1
)(
     input  logic             clk_i
    ,input  logic             rst_ni
    ,input  logic             start_i
    ,input  logic [N-1:0]     multiplicand_i
    ,input  logic [N-1:0]     multiplier_i
    ,output logic [2*N-1:0]   product_o
    ,output logic             done_o
);

    // ----------------------------------------------------------------------
    //  PARAMETER DEFINE
    // ----------------------------------------------------------------------
    localparam int PRODUCT_WIDTH = 2 * N;
    localparam int CNT_WIDTH     = (N <= 1) ? 1 : $clog2(N+1);


    // ----------------------------------------------------------------------
    //  SIGNAL DEFINE
    // ----------------------------------------------------------------------
    logic [N-1:0]                   multiplicand; // latched multiplicand
    logic [CNT_WIDTH-1:0]           cnt;
    logic                           busy;
    logic [N:0]                     add_result;
    logic [PRODUCT_WIDTH:0]         shift_value;
    logic                           start_accept;
    logic                           last_cycle;


    // ----------------------------------------------------------------------
    //  control logic
    // ----------------------------------------------------------------------

    //  accept start_i only when not busy
    assign start_accept = start_i && ~busy;

    //hold multiplicand stable.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            multiplicand <= '0;
        end
        else if ( start_accept ) begin
            multiplicand <= multiplicand_i;
        end
    end

    assign last_cycle = busy && (cnt == CNT_WIDTH'(N-1));
    // Count N shift-add iterations for one accepted start.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            cnt <= '0;
        end
        else if ( start_accept ) begin
            cnt <= '0;
        end
        else if ( last_cycle ) begin
            cnt <= '0;
        end
        else if ( busy ) begin
            cnt <= cnt + CNT_WIDTH'(1);
        end
    end

    // Ignore new starts until the current multiplication finishes.
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

    // product_o is final in the same cycle.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            done_o <= 1'b0;
        end
        else if ( last_cycle ) begin
            done_o <= 1'b1;
        end
        else if ( done_o ) begin
            done_o <= 1'b0;
        end
    end


    // ----------------------------------------------------------------------
    //  data path 
    // ----------------------------------------------------------------------

    // add multiplicand into the upper partial product.
    assign add_result   =    {1'b0, product_o[PRODUCT_WIDTH-1:N]}
                           + ( product_o[0] ? {1'b0, multiplicand} : '0 );

    assign shift_value  = {add_result, product_o[N-1:0]};
    // Reuse one 2N-bit register for partial product and multiplier.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            product_o <= '0;
        end
        else if ( start_accept ) begin
            product_o <= {{N{1'b0}}, multiplier_i};
        end
        else if ( busy ) begin
            product_o <= shift_value[PRODUCT_WIDTH:1];
        end
    end

endmodule
