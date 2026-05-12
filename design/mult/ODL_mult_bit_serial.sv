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
// Last Modified : 2026-05-12 23:55:54
// Description   : Parameterized unsigned bit-serial multiplier
// ----------------------------------------------------------------------

module ODL_mult_bit_serial #(
    parameter int N = 5
)(
     input  logic             clk_i
    ,input  logic             rst_ni
    ,input  logic             start_i
    ,input  logic             x_i
    ,input  logic [N-1:0]     y_i
    ,output logic             p_o
    ,output logic             busy_o
    ,output logic             done_o
);

    localparam int PRODUCT_WIDTH = 2 * N;
    localparam int CNT_WIDTH     = (PRODUCT_WIDTH <= 1) ? 1 : $clog2(PRODUCT_WIDTH);

    logic [N-1:0]             y;   // latched parallel multiplicand
    logic [N-1:0]             acc; // shifted partial product
    logic [CNT_WIDTH-1:0]     cnt;
    logic                     busy;
    logic                     done;
    logic                     p;

    logic                     start_accept;
    logic                     iter_valid;
    logic [CNT_WIDTH-1:0]     iter_idx;
    logic                     input_phase;
    logic                     x_bit;
    logic [N-1:0]             y_for_add;
    logic [N-1:0]             acc_for_add;
    logic [N:0]               add_result;
    logic [N-1:0]             acc_next;
    logic                     p_next;
    logic                     last_cycle;

    assign start_accept = start_i && ~busy;
    assign iter_valid   = start_accept || busy;
    assign iter_idx     = start_accept ? '0 : cnt;

    // Consume x_i for N cycles, then shift out the remaining upper product bits.
    assign input_phase = ( iter_idx < CNT_WIDTH'(N) );
    assign x_bit       = input_phase ? x_i : 1'b0;

    // First cycle uses y_i and a cleared accumulator before registers update.
    assign y_for_add   = start_accept ? y_i : y;
    assign acc_for_add = start_accept ? '0  : acc;
    assign add_result  = {1'b0, acc_for_add} + ( x_bit ? {1'b0, y_for_add} : '0 );
    assign acc_next    = add_result[N:1];
    assign p_next      = add_result[0];
    assign last_cycle  = iter_valid && ( iter_idx == CNT_WIDTH'(PRODUCT_WIDTH-1) );

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            y <= '0;
        end
        else if ( start_accept ) begin
            y <= y_i;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            acc <= '0;
        end
        else if ( iter_valid ) begin
            acc <= acc_next;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            cnt <= '0;
        end
        else if ( iter_valid ) begin
            if ( last_cycle ) begin
                cnt <= '0;
            end
            else begin
                cnt <= iter_idx + CNT_WIDTH'(1);
            end
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            busy <= 1'b0;
        end
        else if ( start_accept ) begin
            busy <= ~last_cycle;
        end
        else if ( busy && last_cycle ) begin
            busy <= 1'b0;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            done <= 1'b0;
        end
        else begin
            done <= last_cycle;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            p <= 1'b0;
        end
        else if ( iter_valid ) begin
            p <= p_next;
        end
    end

    assign p_o    = p;
    assign busy_o = busy;
    assign done_o = done;

endmodule
