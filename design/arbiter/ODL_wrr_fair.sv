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
// Create Date   : 2026-01-22 17:10:51
// Last Modified : 2026-01-27 15:31:34
// Description   : weighted round robin arbiter - fair distribution
// ----------------------------------------------------------------------

module ODL_wrr_fair #(
    parameter int NUM_PORT   = 8,
    parameter int WT_WIDTH   = 5
)(
    input  logic                    clk_i
   ,input  logic                    rst_ni
   ,input  logic [NUM_PORT-1:0]     req_i
   ,input  logic [WT_WIDTH-1:0]     wt_i[NUM_PORT-1:0] // weight should be greater than 0
   ,output logic [NUM_PORT-1:0]     gnt_o
);


    // ----------------------------------------------------------------------
    //  PARAMETER DEFINE
    // ----------------------------------------------------------------------
    localparam int PCNT_WIDTH = WT_WIDTH;


    // ----------------------------------------------------------------------
    //  SIGNAL DEFINE
    // ----------------------------------------------------------------------
    logic                       phase_end;
    logic                       round_end;
    logic [PCNT_WIDTH-1:0]      phase_counter;
    logic [PCNT_WIDTH:0]        pcnt_pre;
    logic [PCNT_WIDTH-1:0]      pcnt_right_most_one;
    logic [PCNT_WIDTH-1:0]      addend;

    logic [PCNT_WIDTH-1:0]      right_most_miss; 
    logic [PCNT_WIDTH-1:0]      right_most_miss_1; 
    logic [PCNT_WIDTH-1:0]      right_most_miss_2; 
    logic [PCNT_WIDTH-1:0]      miss_history;

    logic [PCNT_WIDTH-1:0]      collision_check_bit;
    logic                       in_collision;

    logic [NUM_PORT-1:0]        unvisit;
    logic [NUM_PORT-1:0]        match_phase;
    logic [WT_WIDTH-1:0]        rev_wt[NUM_PORT-1:0];
    logic [NUM_PORT-1:0]        vld_req;


    // ----------------------------------------------------------------------
    //  round: a complete WRR scheduling, which is spilt into several phases
    // ----------------------------------------------------------------------
    assign phase_end = vld_req==gnt_o;
    assign round_end = pcnt_pre[PCNT_WIDTH] & phase_end;


    // ----------------------------------------------------------------------
    //  check if there are any valid requests matching this phase
    // ----------------------------------------------------------------------

    // req valid but gnt invalid indicates that there are no valid requests match this phase
    assign phase_miss = |req_i ^ |gnt_o;

    // record mismatching bits in this round
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            miss_history <= {PCNT_WIDTH{1'b0}};
        end
        else if ( round_end ) begin
            miss_history <= {PCNT_WIDTH{1'b0}};
        end
        else if ( phase_miss ) begin
            miss_history <= miss_history | pcnt_right_most_one;
        end
    end

    // the continuous zero part from bit0
    assign right_most_miss[0]              = miss_history[0];
    assign right_most_miss[PCNT_WIDTH-1:1] = right_most_miss[PCNT_WIDTH-2:0] & miss_history[PCNT_WIDTH-1:1];
    
    assign right_most_miss_1 = {right_most_miss[PCNT_WIDTH-2:0]  , 1'b1};
    assign right_most_miss_2 = {right_most_miss_1[PCNT_WIDTH-2:0], 1'b1};
    

    // ----------------------------------------------------------------------
    //  phase counter
    // ----------------------------------------------------------------------

    // right most zero bit of p_cnt without the continuous zero part
    // this bit is used to check with the miss_history
    ODL_fpa #( .NUM_PORT( PCNT_WIDTH ) ) U_FPA (
         .req_i ( ~(phase_counter|right_most_miss)  ) 
        ,.gnt_o ( collision_check_bit               ) 
    );

    // check_bit of this phase hits a historical mismatching bit
    assign in_collision = | ( collision_check_bit & miss_history );

    assign addend = in_collision ? ( right_most_miss_2 ^ right_most_miss_1 )
                                 : ( right_most_miss_1 ^ right_most_miss   );

    assign pcnt_pre = {1'b0, phase_counter} + {1'b0, addend};
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            phase_counter <= {{(PCNT_WIDTH-1){1'b0}}, 1'b1};

        end
        else if ( round_end ) begin
            phase_counter <= {{(PCNT_WIDTH-1){1'b0}}, 1'b1};
        end
        else if ( phase_end ) begin
            phase_counter <= pcnt_pre[PCNT_WIDTH-1:0];
        end
    end


    // ----------------------------------------------------------------------
    //  valid requests of this phase are sent to the output FPA
    // ----------------------------------------------------------------------
    for ( genvar i=0; i<NUM_PORT; i++ ) begin: gen_unvisit
        always_ff @(posedge clk_i, negedge rst_ni) begin
            if ( ~rst_ni ) begin
                unvisit[i] <= 1'b1; 
            end
            else if ( phase_end ) begin
                unvisit[i] <= 1'b1; 
            end
            else if ( gnt_o[i] ) begin
                unvisit[i] <= 1'b0;
            end
        end
    end

    ODL_fpa #( .NUM_PORT( PCNT_WIDTH ) ) U_PCNT_RMO (
         .req_i ( phase_counter       ) 
        ,.gnt_o ( pcnt_right_most_one ) 
    );

    for ( genvar i=0; i<NUM_PORT; i++ ) begin: gen_match_phase

        for ( genvar j=0; j<WT_WIDTH; j++ ) begin: gen_rev_wt
            assign rev_wt[i][j] = wt_i[i][ WT_WIDTH - 1 - j ]; 
        end

        assign match_phase[i] = | ( pcnt_right_most_one & rev_wt[i] );

    end

    assign vld_req = req_i & match_phase & unvisit;

    ODL_fpa #( .NUM_PORT( NUM_PORT ) ) U_O_FPA (
         .req_i ( vld_req  ) 
        ,.gnt_o ( gnt_o    ) 
    );


endmodule

