// ----------------------------------------------------------------------
// Copyright 2025 TimingWalker
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
// Create Date   : 2025-12-22 18:00:25
// Last Modified : 2025-12-26 10:29:01
// Description   : weighted round robin arbiter
// ----------------------------------------------------------------------

module ODL_wrr #(
    parameter int NUM_PORT = 8,
    parameter int WT_WIDTH = 3
)(
    input  logic                    clk_i
   ,input  logic                    rst_ni
   ,input  logic [NUM_PORT-1:0]     req_i
   ,input  logic [WT_WIDTH-1:0]     wt_i[NUM_PORT-1:0] // weight should be greater than 0
   ,output logic [NUM_PORT-1:0]     gnt_o
);


logic [NUM_PORT-1:0]    ptr;

// ----------------------------------------------------------------------
//  request -> grant
// ----------------------------------------------------------------------
logic [NUM_PORT-1:0]    req_masked;
logic [NUM_PORT-1:0]    unmask_hpri_req;
logic [NUM_PORT-1:0]    mask_hpri_req;
logic [NUM_PORT-1:0]    gnt_unmasked;
logic [NUM_PORT-1:0]    gnt_masked;
logic                   no_req_masked;

assign req_masked    = req_i & ptr;
assign no_req_masked = ~(|req_masked);

// path1: unmask Fixed Priority Arbiter
assign unmask_hpri_req[0]            = 1'b0;
assign unmask_hpri_req[NUM_PORT-1:1] = unmask_hpri_req[NUM_PORT-2:0] | req_i[NUM_PORT-2:0];
assign gnt_unmasked[NUM_PORT-1:0]    = req_i[NUM_PORT-1:0] & ~unmask_hpri_req[NUM_PORT-1:0];

// path2: mask Fixed Priority Arbiter
assign mask_hpri_req[0]              = 1'b0;
assign mask_hpri_req[NUM_PORT-1:1]   = mask_hpri_req[NUM_PORT-2:0] | req_masked[NUM_PORT-2:0];
assign gnt_masked[NUM_PORT-1:0]      = req_masked[NUM_PORT-1:0] & ~mask_hpri_req[NUM_PORT-1:0];

// grant
assign gnt_o = ({NUM_PORT{no_req_masked}} & gnt_unmasked) | gnt_masked;


// ----------------------------------------------------------------------
//  weight counter
// ----------------------------------------------------------------------
logic [WT_WIDTH-1:0]    wt_cnt[NUM_PORT-1:0];
logic [NUM_PORT-1:0]    cnt_over;
logic                   gnt_cnt_over;

for (genvar i=0; i<NUM_PORT; i++) begin : gen_weight_counter

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if ( ~rst_ni ) begin
            wt_cnt[i] <= wt_i[i];
        end
        // reload at the end of one round
        else if ( no_req_masked ) begin
            if ( gnt_o[i] )
                wt_cnt[i] <= wt_i[i] - 'd1;
            else
                wt_cnt[i] <= wt_i[i];
        end
        // decrement by one if this port is granted
        else if ( gnt_o[i] ) begin
            wt_cnt[i] <= wt_cnt[i] - 'd1;
        end
    end

    // if no_req_masked=1, use wt_i because wt_cnt is invalid at this cycle
    assign cnt_over[i] = ( ( no_req_masked ? wt_i[i] : wt_cnt[i] ) <= 'd1 ) & gnt_o[i];

end

assign gnt_cnt_over = |cnt_over;


// ----------------------------------------------------------------------
//  priority pointer: encoded as a mask
//   e.g. ptr = 11111000 >>> the highest priority port is 3. 
// ----------------------------------------------------------------------
logic [NUM_PORT-1:0]    hpri_req;

assign hpri_req = no_req_masked ? unmask_hpri_req : mask_hpri_req;

always_ff @(posedge clk_i, negedge rst_ni) begin
    if ( ~rst_ni ) begin
        ptr <= {NUM_PORT{1'b1}};
    end
    // if no valid requests, reset ptr.
    else if ( ~ |req_i ) begin
        ptr <= {NUM_PORT{1'b1}};
    end
    // otherwise, the pointer is moved to:
    // 1) the next position of the current granted port
    else if ( gnt_cnt_over ) begin
        ptr <= hpri_req;
    end
    // or:
    // 2) the current granted port, because its wt_cnt is not empty
    else if ( ~(|(gnt_o&((ptr<<1)^ptr))) ) begin
        ptr <= hpri_req | gnt_o;
    end
end


endmodule

