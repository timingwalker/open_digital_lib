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
// Create Date   : 2019-12-21 10:29:01
// Last Modified : 2026-03-10 11:47:58
// Description   : Glitch free clock switch module
// ----------------------------------------------------------------------

module ODL_clock_switch (
     output wire clk_out                    // Clock output
    ,input  wire clk_in0                    // Clock input 0
    ,input  wire clk_in1                    // Clock input 1
    ,input  wire rst_n                      // Reset
    ,input  wire scan_mode                  // Scan mode 
    ,input  wire select_in                  // Clock selection
);


    //-----------------------------------------------------------------------------
    // Wire declarations
    //-----------------------------------------------------------------------------
    wire in0_select;
    reg  in0_select_s;
    reg  in0_select_ss;
    wire in0_enable;
     
    wire in1_select;
    reg  in1_select_s;
    reg  in1_select_ss;
    wire in1_enable;
     
    wire clk_in0_inv;
    wire clk_in1_inv;
    wire clk_in0_scan_fix_inv;
    wire clk_in1_scan_fix_inv;
    wire gated_clk_in0;
    wire gated_clk_in1;


    //-----------------------------------------------------------------------------
    // scan repair for neg-edge clocked FF
    //-----------------------------------------------------------------------------
    std_wrap_ckmux U_CKMUX_0 ( .i0_i(clk_in0_inv), .i1_i(clk_in0), .s_i(scan_mode), .z_o(clk_in0_scan_fix_inv) );
    std_wrap_ckmux U_CKMUX_1 ( .i0_i(clk_in1_inv), .i1_i(clk_in1), .s_i(scan_mode), .z_o(clk_in1_scan_fix_inv) );


    //-----------------------------------------------------------------------------
    // CLK_IN0 Selection
    //-----------------------------------------------------------------------------
    assign in0_select = ~(select_in | in1_select_ss);
     
    always @ (posedge clk_in0              or negedge rst_n)
      if (rst_n==1'b0) in0_select_s  <=  1'b1;
      else             in0_select_s  <=  in0_select;
     
    always @ (posedge clk_in0_scan_fix_inv or negedge rst_n)
      if (rst_n==1'b0) in0_select_ss <=  1'b1;
      else             in0_select_ss <=  in0_select_s;
     
    // select clk_in0 in scan mode
    //assign in0_enable = in0_select_ss | scan_mode;
    assign in0_enable = in0_select_ss; 
 

    //-----------------------------------------------------------------------------
    // CLK_IN1 Selection
    //-----------------------------------------------------------------------------
    assign in1_select =  ~( (~select_in) | in0_select_ss );
     
    always @ (posedge clk_in1     or negedge rst_n)
      if (rst_n==1'b0) in1_select_s  <=  1'b0;
      else             in1_select_s  <=  in1_select;
     
    always @ (posedge clk_in1_scan_fix_inv or negedge rst_n)
      if (rst_n==1'b0) in1_select_ss <=  1'b0;
      else             in1_select_ss <=  in1_select_s;
     
    //assign in1_enable = in1_select_ss & ~scan_mode;
    assign in1_enable = in1_select_ss; 
 
 
    //-----------------------------------------------------------------------------
    // Clock MUX
    //-----------------------------------------------------------------------------
    std_wrap_ckinv U_CKINV_1 ( .in_i(clk_in0), .zn_o(clk_in0_inv) );
    std_wrap_ckinv U_CKINV_2 ( .in_i(clk_in1), .zn_o(clk_in1_inv) );
    
    std_wrap_ckand U_CKAND_1 ( .a1_i(clk_in0), .a2_i(in0_enable), .z_o(gated_clk_in0) );
    std_wrap_ckand U_CKAND_2 ( .a1_i(clk_in1), .a2_i(in1_enable), .z_o(gated_clk_in1) );
     
    std_wrap_ckor U_CKOR ( .a1_i(gated_clk_in0), .a2_i(gated_clk_in1), .z_o(clk_out) );

endmodule

