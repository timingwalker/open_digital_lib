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
// Last Modified : 2026-05-08 00:03:03
// Description   : Parameterized unsigned shift-add multiplier
// ----------------------------------------------------------------------

module ODL_mult_shift_add #(
    parameter int N = 5
)(
     input  logic             clk_i
    ,input  logic             rst_ni
    ,input  logic             start_i
    ,input  logic [N-1:0]     multiplicand_i
    ,input  logic [N-1:0]     multiplier_i
    ,output logic [2*N-1:0]   product_o
    ,output logic             busy_o
    ,output logic             done_o
);

    localparam int CNT_WIDTH = (N <= 1) ? 1 : $clog2(N+1);

    logic [N-1:0]             multiplicand; // latched multiplicand
    logic [2*N-1:0]           product;      // {partial product, multiplier}
    logic [CNT_WIDTH-1:0]     cnt;
    logic                     busy;
    logic                     done;

    logic [N:0]               addend;
    logic [N:0]               add_result;
    logic [2*N:0]             shift_src;
    logic [2*N-1:0]           product_next;
    logic                     last_cycle;

    // Add multiplicand to the partial product when multiplier bit0 is 1.
    assign addend       = product[0] ? {1'b0, multiplicand} : '0;
    assign add_result   = {1'b0, product[2*N-1:N]} + addend;

    // Shift {carry, partial product, multiplier} right by one bit.
    assign shift_src    = {add_result, product[N-1:0]};
    assign product_next = shift_src[2*N:1];
    assign last_cycle   = (cnt == CNT_WIDTH'(N-1));

    // Hold multiplicand stable while the multiplier is busy.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            multiplicand <= '0;
        end
        else if ( start_i && ~busy ) begin
            multiplicand <= multiplicand_i;
        end
    end

    // Reuse one 2N-bit register for partial product and multiplier.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            product <= '0;
        end
        else if ( start_i && ~busy ) begin
            product <= {{N{1'b0}}, multiplier_i};
        end
        else if ( busy ) begin
            product <= product_next;
        end
    end

    // Count N shift-add iterations.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            cnt <= '0;
        end
        else if ( start_i && ~busy ) begin
            cnt <= '0;
        end
        else if ( busy ) begin
            if ( last_cycle ) begin
                cnt <= '0;
            end
            else begin
                cnt <= cnt + CNT_WIDTH'(1);
            end
        end
    end

    // Ignore new starts until the current multiplication finishes.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            busy <= 1'b0;
        end
        else if ( start_i && ~busy ) begin
            busy <= 1'b1;
        end
        else if ( busy && last_cycle ) begin
            busy <= 1'b0;
        end
    end

    // Pulse done for one cycle with the final product.
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            done <= 1'b0;
        end
        else begin
            done <= busy && last_cycle;
        end
    end

    assign product_o = product;
    assign busy_o    = busy;
    assign done_o    = done;

endmodule
